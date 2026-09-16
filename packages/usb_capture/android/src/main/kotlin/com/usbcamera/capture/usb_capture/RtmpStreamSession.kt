package com.usbcamera.capture.usb_capture

import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.SystemClock
import android.util.Log
import android.view.Surface
import com.herohan.uvcapp.ICameraHelper
import com.pedro.common.AudioCodec
import com.pedro.common.ConnectChecker
import com.pedro.common.VideoCodec
import com.pedro.rtmp.rtmp.RtmpClient
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

internal class RtmpStreamSession(
    private val mainHandler: Handler,
    private val onFailed: (String) -> Unit,
) : ConnectChecker {
    interface EncodedSink {
        fun onVideo(annexB: ByteArray, ptsUs: Long, keyframe: Boolean)
        fun onAudio(adtsOrAac: ByteArray, ptsUs: Long)
    }

    @Volatile
    var encodedSink: EncodedSink? = null

    private val running = AtomicBoolean(false)
    @Volatile
    private var connectGate = CountDownLatch(1)
    @Volatile
    private var connectError: String? = null
    @Volatile
    private var live = false

    private var helper: ICameraHelper? = null
    private var encoderSurface: Surface? = null
    private var videoEncoder: MediaCodec? = null
    private var audioEncoder: MediaCodec? = null
    private var rtmp: RtmpClient? = null
    private var videoDrain: Thread? = null
    private var audioPcmBytes = 0L
    private var audioSampleRate = 44100
    private var audioChannelCount = 2
    private var cachedSpsAnnexB: ByteArray? = null
    private var cachedPpsAnnexB: ByteArray? = null
    private var videoWidth = 0
    private var videoHeight = 0
    private var videoFps = 30
    private var videoFrameIndex = 0L
    private var yuvColorFormat = MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible
    private var yuvInput = false
    private var ptsEpochNs = 0L
    private val encodeLock = Any()

    fun start(
        helper: ICameraHelper,
        url: String,
        width: Int,
        height: Int,
        fps: Int,
        videoBitrate: Int,
        sampleRate: Int,
        channelCount: Int,
        hasAudio: Boolean,
    ) {
        if (!running.compareAndSet(false, true)) {
            throw CaptureException("streamFailed", "streamInProgress")
        }
        this.helper = helper
        audioSampleRate = sampleRate
        audioChannelCount = channelCount.coerceIn(1, 2)
        try {
            startVideoEncoder(width, height, fps, videoBitrate)
            if (hasAudio) {
                startAudioEncoder()
            }
            attachRtmp(url, hasAudio)
        } catch (error: Exception) {
            stop()
            if (error is CaptureException) throw error
            throw CaptureException("streamFailed", error.message ?: "connectFailed")
        }
    }

    fun startEncodersOnly(
        helper: ICameraHelper,
        width: Int,
        height: Int,
        fps: Int,
        videoBitrate: Int,
        sampleRate: Int,
        channelCount: Int,
        hasAudio: Boolean,
    ) {
        if (!running.compareAndSet(false, true)) {
            throw CaptureException("streamFailed", "streamInProgress")
        }
        this.helper = helper
        audioSampleRate = sampleRate
        audioChannelCount = channelCount.coerceIn(1, 2)
        rtmp = null
        try {
            startVideoEncoder(width, height, fps, videoBitrate)
            if (hasAudio) {
                startAudioEncoder()
            }
            requestKeyframe()
        } catch (error: Exception) {
            stop()
            if (error is CaptureException) throw error
            throw CaptureException(
                "streamFailed",
                EncoderLimits.liveFailureDetails(error.message),
            )
        }
    }

    fun attachRtmp(url: String, hasAudio: Boolean) {
        if (!running.get()) {
            throw CaptureException("streamFailed", "connectFailed")
        }
        if (rtmp != null) {
            throw CaptureException("streamFailed", "streamInProgress")
        }
        connectError = null
        connectGate = CountDownLatch(1)
        val client = RtmpClient(this).also {
            it.setLogs(false)
            it.setReTries(0)
            it.setVideoCodec(VideoCodec.H264)
            it.setAudioCodec(AudioCodec.AAC)
            it.setVideoResolution(videoWidth.coerceAtLeast(16), videoHeight.coerceAtLeast(16))
            it.setFps(videoFps.coerceAtLeast(1))
            it.setOnlyVideo(!hasAudio)
            if (hasAudio) {
                it.setAudioInfo(audioSampleRate, audioChannelCount == 2)
            }
        }
        rtmp = client
        val sps = cachedSpsAnnexB
        if (sps != null) {
            client.setVideoInfo(
                ByteBuffer.wrap(sps),
                cachedPpsAnnexB?.let { ByteBuffer.wrap(it) },
                null,
            )
        }
        client.connect(url)
        val ok = connectGate.await(12, TimeUnit.SECONDS)
        val error = connectError
        if (!ok || error != null) {
            try {
                client.disconnect()
            } catch (_: Exception) {
            }
            rtmp = null
            throw CaptureException("streamFailed", error ?: "connectFailed")
        }
        live = true
        requestKeyframe()
    }

    fun detachRtmp() {
        live = false
        val client = rtmp
        rtmp = null
        try {
            client?.disconnect()
        } catch (_: Exception) {
        }
        connectError = connectError ?: "stopped"
        connectGate.countDown()
    }

    fun queueNv21(frame: java.nio.ByteBuffer) {
        if (!running.get() || !yuvInput) return
        val remaining = frame.remaining()
        if (remaining <= 0) return
        val nv21 = ByteArray(remaining)
        try {
            frame.duplicate().get(nv21)
        } catch (_: Exception) {
            return
        }
        val expected = YuvConvert.packedSize(videoWidth, videoHeight)
        if (nv21.size < expected || videoWidth <= 0 || videoHeight <= 0) return
        synchronized(encodeLock) {
            if (!running.get()) return
            val encoder = videoEncoder ?: return
            val index = encoder.dequeueInputBuffer(0)
            if (index < 0) return
            try {
                val image = encoder.getInputImage(index)
                if (image != null) {
                    fillImage(image, nv21)
                } else {
                    val input = encoder.getInputBuffer(index) ?: return
                    input.clear()
                    val payload = if (
                        yuvColorFormat == MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar
                    ) {
                        nv21ToI420(nv21)
                    } else {
                        YuvConvert.nv21ToNv12(nv21, videoWidth, videoHeight)
                    }
                    val copy = minOf(input.remaining(), payload.size)
                    input.put(payload, 0, copy)
                }
                val pts = ptsUs()
                videoFrameIndex++
                encoder.queueInputBuffer(index, 0, expected, pts, 0)
                if (videoFrameIndex <= 3L || videoFrameIndex % 90L == 0L) {
                    Log.i(TAG, "queued yuv frame #$videoFrameIndex size=${nv21.size}")
                }
            } catch (error: Exception) {
                Log.w(TAG, "queueNv21 failed", error)
                try {
                    encoder.queueInputBuffer(index, 0, 0, 0, 0)
                } catch (_: Exception) {
                }
            }
        }
    }

    fun writePcm(data: ByteArray, length: Int) {
        if (!running.get() || length <= 0) return
        synchronized(encodeLock) {
            val encoder = audioEncoder ?: return
            if (!running.get()) return
            val pts = ptsUs()
            audioPcmBytes += length
            var offset = 0
            while (offset < length) {
                val index = encoder.dequeueInputBuffer(0)
                if (index < 0) {
                    drainAudio(false)
                    return
                }
                val input = encoder.getInputBuffer(index) ?: return
                input.clear()
                val copy = minOf(input.remaining(), length - offset)
                input.put(data, offset, copy)
                encoder.queueInputBuffer(index, 0, copy, pts, 0)
                offset += copy
            }
            drainAudio(false)
        }
    }

    fun stop() {
        running.set(false)
        live = false
        val drain = videoDrain
        videoDrain = null
        try {
            drain?.join(800)
        } catch (_: InterruptedException) {
        }
        synchronized(encodeLock) {
            val surface = encoderSurface
            val camera = helper
            if (surface != null && camera != null) {
                val done = CountDownLatch(1)
                mainHandler.post {
                    try {
                        camera.removeSurface(surface)
                    } catch (_: Exception) {
                    }
                    done.countDown()
                }
                done.await(1, TimeUnit.SECONDS)
            }
            encoderSurface?.release()
            encoderSurface = null
            releaseCodec(videoEncoder)
            videoEncoder = null
            releaseCodec(audioEncoder)
            audioEncoder = null
            try {
                rtmp?.disconnect()
            } catch (_: Exception) {
            }
            rtmp = null
            helper = null
            connectError = connectError ?: "stopped"
            connectGate.countDown()
        }
    }

    override fun onConnectionStarted(url: String) {}

    override fun onConnectionSuccess() {
        connectGate.countDown()
    }

    override fun onConnectionFailed(reason: String) {
        connectError = "connectFailed"
        connectGate.countDown()
        if (live) {
            onFailed("connectFailed")
        }
    }

    override fun onDisconnect() {}

    override fun onAuthError() {
        connectError = "connectFailed"
        connectGate.countDown()
        if (live) {
            onFailed("connectFailed")
        }
    }

    override fun onAuthSuccess() {}

    override fun onNewBitrate(bitrate: Long) {}

    private fun resetPtsClock() {
        ptsEpochNs = SystemClock.elapsedRealtimeNanos()
    }

    private fun ptsUs(): Long {
        if (ptsEpochNs == 0L) {
            resetPtsClock()
            return 0L
        }
        return ((SystemClock.elapsedRealtimeNanos() - ptsEpochNs) / 1000L).coerceAtLeast(0L)
    }

    private fun startVideoEncoder(width: Int, height: Int, fps: Int, bitrate: Int) {
        videoWidth = width
        videoHeight = height
        videoFps = EncoderLimits.videoFps(fps)
        videoFrameIndex = 0L
        yuvInput = true
        resetPtsClock()
        val colors = intArrayOf(
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar,
        )
        var last: Exception? = null
        for (name in avcEncoderNames()) {
            for (color in colors) {
                var encoder: MediaCodec? = null
                try {
                    encoder = if (name == null) {
                        MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
                    } else {
                        MediaCodec.createByCodecName(name)
                    }
                    val format = MediaFormat.createVideoFormat(
                        MediaFormat.MIMETYPE_VIDEO_AVC,
                        width,
                        height,
                    )
                    format.setInteger(MediaFormat.KEY_COLOR_FORMAT, color)
                    format.setInteger(MediaFormat.KEY_BIT_RATE, bitrate.coerceAtLeast(500_000))
                    format.setInteger(MediaFormat.KEY_FRAME_RATE, videoFps)
                    format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
                    format.setInteger(
                        MediaFormat.KEY_PROFILE,
                        MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline,
                    )
                    if (Build.VERSION.SDK_INT >= 23) {
                        format.setInteger(
                            MediaFormat.KEY_LEVEL,
                            MediaCodecInfo.CodecProfileLevel.AVCLevel4,
                        )
                        format.setInteger(MediaFormat.KEY_PRIORITY, 0)
                        format.setInteger(
                            MediaFormat.KEY_BITRATE_MODE,
                            MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR,
                        )
                    }
                    if (Build.VERSION.SDK_INT >= 29) {
                        format.setInteger(MediaFormat.KEY_MAX_B_FRAMES, 0)
                    }
                    format.setInteger("vendor.qti-ext-enc-low-latency.enable", 1)
                    encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                    encoder.start()
                    encoderSurface = null
                    yuvColorFormat = color
                    videoEncoder = encoder
                    videoDrain = Thread({ drainVideoLoop() }, "rtmp-video").also { it.start() }
                    Log.i(
                        TAG,
                        "AVC yuv encoder started name=${encoder.name} color=$color " +
                            "${width}x${height}@$videoFps",
                    )
                    return
                } catch (error: Exception) {
                    last = error
                    Log.w(TAG, "AVC yuv encoder failed name=$name color=$color", error)
                    try {
                        encoder?.release()
                    } catch (_: Exception) {
                    }
                }
            }
        }
        throw last ?: CaptureException("streamFailed", "httpLiveFailed")
    }

    private fun avcEncoderNames(): List<String?> {
        val software = ArrayList<String>()
        try {
            val mime = MediaFormat.MIMETYPE_VIDEO_AVC
            for (info in MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos) {
                if (!info.isEncoder) continue
                if (info.supportedTypes.none { it.equals(mime, ignoreCase = true) }) continue
                val name = info.name.lowercase()
                if (name.contains("google") || name.contains("c2.android")) {
                    software.add(info.name)
                }
            }
        } catch (_: Exception) {
        }
        return listOf<String?>(null) + software
    }

    private fun startAudioEncoder() {
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC,
            audioSampleRate,
            audioChannelCount,
        )
        format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
        format.setInteger(MediaFormat.KEY_BIT_RATE, 128_000)
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16_384)
        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        encoder.start()
        audioEncoder = encoder
    }

    private fun fillImage(image: Image, nv21: ByteArray) {
        val planes = image.planes
        if (planes.size < 3) {
            throw IllegalStateException("encoder image planes=${planes.size}")
        }
        YuvConvert.fillYuv420FromNv21(
            nv21 = nv21,
            width = videoWidth,
            height = videoHeight,
            y = YuvConvert.Plane(
                rowStride = planes[0].rowStride,
                pixelStride = planes[0].pixelStride.coerceAtLeast(1),
                buffer = planes[0].buffer,
            ),
            u = YuvConvert.Plane(
                rowStride = planes[1].rowStride,
                pixelStride = planes[1].pixelStride.coerceAtLeast(1),
                buffer = planes[1].buffer,
            ),
            v = YuvConvert.Plane(
                rowStride = planes[2].rowStride,
                pixelStride = planes[2].pixelStride.coerceAtLeast(1),
                buffer = planes[2].buffer,
            ),
        )
    }

    private fun nv21ToI420(nv21: ByteArray): ByteArray {
        val ySize = videoWidth * videoHeight
        val cSize = ySize / 4
        val out = ByteArray(ySize + cSize * 2)
        System.arraycopy(nv21, 0, out, 0, ySize)
        var src = ySize
        var u = ySize
        var v = ySize + cSize
        while (src + 1 < nv21.size && u < ySize + cSize) {
            out[v++] = nv21[src]
            out[u++] = nv21[src + 1]
            src += 2
        }
        return out
    }

    private fun requestKeyframe() {
        val params = Bundle()
        params.putInt(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0)
        try {
            videoEncoder?.setParameters(params)
        } catch (_: Exception) {
        }
    }

    private fun drainVideoLoop() {
        val info = MediaCodec.BufferInfo()
        while (running.get()) {
            val encoder = videoEncoder ?: break
            val index = try {
                encoder.dequeueOutputBuffer(info, 20_000)
            } catch (_: Exception) {
                break
            }
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> {}
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val format = encoder.outputFormat
                    storeVideoCsd(format.getByteBuffer("csd-0"), format.getByteBuffer("csd-1"))
                    val sps = format.getByteBuffer("csd-0")
                    val pps = format.getByteBuffer("csd-1")
                    if (sps != null) {
                        rtmp?.setVideoInfo(sps, pps, null)
                    }
                }
                index >= 0 -> {
                    val output = encoder.getOutputBuffer(index)
                    if (output != null && info.size > 0) {
                        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                            val csd = ByteArray(info.size)
                            output.position(info.offset)
                            output.get(csd)
                            parseAvcCsd(csd)
                        } else if (running.get()) {
                            val copy = ByteArray(info.size)
                            output.position(info.offset)
                            output.get(copy)
                            output.position(info.offset)
                            val keyframe = info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME != 0
                            if (videoFrameIndex <= 8L) {
                                Log.i(
                                    TAG,
                                    "encoded video size=${info.size} key=$keyframe pts=${info.presentationTimeUs}",
                                )
                            }
                            encodedSink?.onVideo(
                                AvFormatConvert.prepareVideoForHls(
                                    copy,
                                    cachedSpsAnnexB,
                                    cachedPpsAnnexB,
                                    keyframe,
                                ),
                                info.presentationTimeUs,
                                keyframe,
                            )
                            try {
                                rtmp?.sendVideo(output, info)
                            } catch (_: Throwable) {
                            }
                        }
                    }
                    encoder.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
        }
    }

    private fun parseAvcCsd(csd: ByteArray) {
        val sps = videoEncoder?.outputFormat?.getByteBuffer("csd-0")
        val pps = videoEncoder?.outputFormat?.getByteBuffer("csd-1")
        if (sps != null) {
            storeVideoCsd(sps, pps)
            rtmp?.setVideoInfo(sps.duplicate(), pps?.duplicate(), null)
            return
        }
        if (csd.size > 4) {
            rtmp?.setVideoInfo(ByteBuffer.wrap(csd), null, null)
        }
    }

    private fun storeVideoCsd(sps: ByteBuffer?, pps: ByteBuffer?) {
        if (sps != null) {
            cachedSpsAnnexB = AvFormatConvert.byteBufferToAnnexBNal(sps)
        }
        if (pps != null) {
            cachedPpsAnnexB = AvFormatConvert.byteBufferToAnnexBNal(pps)
        }
    }

    private fun drainAudio(end: Boolean) {
        val encoder = audioEncoder ?: return
        val info = MediaCodec.BufferInfo()
        var idle = 0
        while (true) {
            val index = encoder.dequeueOutputBuffer(info, if (end) 20_000L else 0L)
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!end || ++idle > 8) return
                }
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val csd = encoder.outputFormat.getByteBuffer("csd-0")
                    if (csd != null) {
                        val config = MediaCodec.BufferInfo()
                        config.offset = 0
                        config.size = csd.remaining()
                        config.flags = MediaCodec.BUFFER_FLAG_CODEC_CONFIG
                        try {
                            rtmp?.sendAudio(csd, config)
                        } catch (_: Throwable) {
                        }
                    }
                }
                index >= 0 -> {
                    idle = 0
                    val output = encoder.getOutputBuffer(index)
                    if (output != null &&
                        info.size > 0 &&
                        info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 &&
                        running.get()
                    ) {
                        val copy = ByteArray(info.size)
                        output.position(info.offset)
                        output.get(copy)
                        output.position(info.offset)
                        encodedSink?.onAudio(
                            AvFormatConvert.wrapAacWithAdts(
                                copy,
                                audioSampleRate,
                                audioChannelCount,
                            ),
                            info.presentationTimeUs,
                        )
                        try {
                            rtmp?.sendAudio(output, info)
                        } catch (_: Throwable) {
                        }
                    }
                    val eos = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    encoder.releaseOutputBuffer(index, false)
                    if (eos) return
                }
            }
        }
    }

    private fun releaseCodec(codec: MediaCodec?) {
        if (codec == null) return
        try {
            codec.stop()
        } catch (_: Exception) {
        }
        try {
            codec.release()
        } catch (_: Exception) {
        }
    }

    private companion object {
        const val TAG = "usb_capture"
    }
}
