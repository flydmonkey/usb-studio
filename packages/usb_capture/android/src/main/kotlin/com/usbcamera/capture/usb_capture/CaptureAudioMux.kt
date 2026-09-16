package com.usbcamera.capture.usb_capture

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.nio.ByteBuffer

internal class CaptureAacWriter(
    private val file: File,
    private val sampleRate: Int,
    private val channelCount: Int,
) {
    private val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
    private val muxer = MediaMuxer(file.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    private val bufferInfo = MediaCodec.BufferInfo()
    private var track = -1
    private var muxerStarted = false
    private var pcmBytes = 0L
    @Volatile
    private var running = true

    init {
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC,
            sampleRate,
            channelCount,
        )
        format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
        format.setInteger(MediaFormat.KEY_BIT_RATE, 128000)
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        encoder.start()
    }

    @Synchronized
    fun writePcm(data: ByteArray, length: Int) {
        if (!running || length <= 0) return
        val pts = pcmBytes * 1_000_000L / (sampleRate * channelCount * 2L)
        pcmBytes += length
        var offset = 0
        while (offset < length) {
            val index = encoder.dequeueInputBuffer(10_000)
            if (index < 0) {
                drain(false)
                continue
            }
            val input = encoder.getInputBuffer(index) ?: return
            input.clear()
            val copy = minOf(input.remaining(), length - offset)
            input.put(data, offset, copy)
            encoder.queueInputBuffer(index, 0, copy, pts, 0)
            offset += copy
        }
        drain(false)
    }

    @Synchronized
    fun finish(): Boolean {
        if (!running) return muxerStarted
        running = false
        val index = encoder.dequeueInputBuffer(100_000)
        if (index >= 0) {
            encoder.queueInputBuffer(
                index,
                0,
                0,
                pcmBytes * 1_000_000L / (sampleRate * channelCount * 2L).coerceAtLeast(1),
                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
            )
        }
        drain(true)
        encoder.stop()
        encoder.release()
        if (muxerStarted) {
            muxer.stop()
        }
        muxer.release()
        return muxerStarted && file.length() > 0
    }

    private fun drain(end: Boolean) {
        var idle = 0
        while (true) {
            val index = encoder.dequeueOutputBuffer(bufferInfo, if (end) 50_000L else 0L)
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!end || ++idle > 10) return
                }
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (!muxerStarted) {
                        track = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                }
                index >= 0 -> {
                    idle = 0
                    val output = encoder.getOutputBuffer(index)
                    if (output != null &&
                        bufferInfo.size > 0 &&
                        muxerStarted &&
                        bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0
                    ) {
                        output.position(bufferInfo.offset)
                        output.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(track, output, bufferInfo)
                    }
                    val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    encoder.releaseOutputBuffer(index, false)
                    if (eos) return
                }
            }
        }
    }
}

internal object Mp4Muxer {
    fun combine(video: File, audio: File?, output: File) {
        val muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val videoExtractor = MediaExtractor()
        videoExtractor.setDataSource(video.absolutePath)
        val videoIndex = selectTrack(videoExtractor, "video/")
        videoExtractor.selectTrack(videoIndex)
        val muxVideo = muxer.addTrack(videoExtractor.getTrackFormat(videoIndex))
        var audioExtractor: MediaExtractor? = null
        var muxAudio = -1
        if (audio != null && audio.exists() && audio.length() > 0) {
            audioExtractor = MediaExtractor()
            audioExtractor.setDataSource(audio.absolutePath)
            val audioIndex = selectTrack(audioExtractor, "audio/")
            audioExtractor.selectTrack(audioIndex)
            muxAudio = muxer.addTrack(audioExtractor.getTrackFormat(audioIndex))
        }
        muxer.start()
        copyTrack(videoExtractor, muxer, muxVideo)
        if (audioExtractor != null && muxAudio >= 0) {
            copyTrack(audioExtractor, muxer, muxAudio)
        }
        muxer.stop()
        muxer.release()
        videoExtractor.release()
        audioExtractor?.release()
    }

    private fun selectTrack(extractor: MediaExtractor, prefix: String): Int {
        for (i in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith(prefix)) return i
        }
        throw IllegalStateException("missing $prefix track")
    }

    private fun copyTrack(extractor: MediaExtractor, muxer: MediaMuxer, track: Int) {
        val buffer = ByteBuffer.allocate(1 * 1024 * 1024)
        val info = MediaCodec.BufferInfo()
        while (true) {
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) break
            info.offset = 0
            info.size = size
            info.presentationTimeUs = extractor.sampleTime.coerceAtLeast(0)
            info.flags = extractor.sampleFlags
            muxer.writeSampleData(track, buffer, info)
            extractor.advance()
        }
    }
}
