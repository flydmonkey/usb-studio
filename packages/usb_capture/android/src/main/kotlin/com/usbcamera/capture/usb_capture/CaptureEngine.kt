package com.usbcamera.capture.usb_capture

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.MediaStore
import android.view.Surface
import android.view.TextureView
import com.herohan.uvcapp.CameraException
import com.herohan.uvcapp.CameraHelper
import com.herohan.uvcapp.ICameraHelper
import com.herohan.uvcapp.IImageCapture
import com.herohan.uvcapp.VideoCapture
import com.serenegiant.usb.IFrameCallback
import com.serenegiant.usb.Size
import com.serenegiant.usb.UVCCamera
import com.serenegiant.usb.UVCControl
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.ArrayDeque
import java.util.Date
import java.util.Locale
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class CaptureEngine(
    private val context: Context,
    private var emit: (Map<String, Any?>) -> Unit,
) {
    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var helper: ICameraHelper? = null
    private var previewView: TextureView? = null
    private var previewSurface: Surface? = null
    private var openedDeviceId: String? = null
    private var hasCaptureAudio = false
    private var previewMuted = false
    private var monitorVolume = 1f
    private var monitorDelayMs = 0
    private var qualityPreset = "standard"
    private var streamBitratePreset = "mbps2"
    @Volatile private var streaming = false
    private var httpLiveEncoding = false
    private var httpServing = false
    private var httpServer: LanHttpServer? = null
    private val mjpegHub = MjpegHub()
    private val lanLiveViewers = LanLiveViewers()
    private val jpegLive = JpegLiveEncoder(mjpegHub, previewView = { previewView })
    private var httpUrl: String? = null
    private var httpPort = 0
    @Volatile private var previewMjpeg = false
    @Volatile private var lanLiveBusy = false
    @Volatile private var previewWidth = 0
    @Volatile private var previewHeight = 0
    private val recordingLibrary = RecordingLibrary { null }
    private var streamSession: RtmpStreamSession? = null
    private val livePreviewCallback = IFrameCallback { frame ->
        try {
            if (streaming) {
                streamSession?.queueNv21(frame)
            }
            if (lanLiveViewers.active(streaming = streaming, mjpeg = previewMjpeg)) {
                jpegLive.offerFrame(copyFrame(frame))
            }
        } catch (_: Throwable) {
        }
    }
    private var streamStartedAt = 0L
    private var prefer720p = false
    private var usbGranted = false
    private var recording = false
    private var savedUri: android.net.Uri? = null
    private var recordError: String? = null
    private var recordingStartedAt = 0L
    private var lastFrameAt = 0L
    private var gotPreviewFrame = false
    private var lastEmittedSignal: Map<String, Any?>? = null
    private var frameCount = 0
    private var fpsWindowStart = 0L
    private var measuredFps = 0
    private var lastPeakAt = 0L
    private var snapshotError: String? = null
    private var aacWriter: CaptureAacWriter? = null
    private var videoTemp: File? = null
    private var audioTemp: File? = null
    private var audioSampleRate = 44100
    private var audioChannelCount = 1
    private var muxedHasAudio = false
    private var recordingEverStarted = false
    private val startingRecording = AtomicBoolean(false)
    private var openLatch: CountDownLatch? = null
    private var openError: String? = null
    private var stopLatch: CountDownLatch? = null
    private val monitorRunning = AtomicBoolean(false)
    private var monitorThread: Thread? = null
    private var sessionStamp = ""
    private var segmentIndex = 1
    private var sessionStartedAt = 0L
    private var segmentDurationMs = 10 * 60 * 1000L
    private val rotating = AtomicBoolean(false)
    private val rotateHandler = Handler(Looper.getMainLooper())
    private val rotateRunnable = Runnable {
        Thread { rotateSegment() }.start()
    }

    val isRecordingActive: Boolean
        get() = sessionStamp.isNotEmpty() ||
            recording ||
            helper?.isRecording == true ||
            videoTemp != null

    val isStreaming: Boolean
        get() = streaming

    val isHttpServing: Boolean
        get() = httpServing

    val isSessionOpen: Boolean
        get() = !openedDeviceId.isNullOrBlank() || previewView != null

    fun updateEmit(next: (Map<String, Any?>) -> Unit) {
        emit = next
    }

    fun recordingHud(): RecordingHud? {
        if (!isRecordingActive && !streaming && !httpServing) return null
        val origin = when {
            sessionStartedAt != 0L -> sessionStartedAt
            streamStartedAt != 0L -> streamStartedAt
            httpServing -> SystemClock.elapsedRealtime()
            else -> 0L
        }
        val elapsed = if (origin == 0L) {
            0L
        } else {
            SystemClock.elapsedRealtime() - origin
        }
        return RecordingHud(
            elapsed,
            segmentIndex,
            segmentDurationMs > 0L,
            recording = isRecordingActive,
            streaming = streaming,
            httpServing = httpServing,
        )
    }

    private val stateCallback = object : ICameraHelper.StateCallback {
        override fun onAttach(device: UsbDevice) {
            emit(mapOf("type" to "attached", "device" to mapDevice(device)))
        }

        override fun onDeviceOpen(device: UsbDevice, isFirstOpen: Boolean) {
            usbGranted = true
            val helper = helper ?: return
            try {
                val size = pickSize(helper)
                if (size != null) {
                    helper.openCamera(size)
                } else {
                    helper.openCamera()
                }
            } catch (_: Exception) {
                helper.openCamera()
            }
        }

        override fun onCameraOpen(device: UsbDevice) {
            val helper = helper ?: return
            helper.startPreview()
            attachSurfaceIfReady()
            openedDeviceId = deviceId(device)
            hasCaptureAudio = findUsbAudioDevice() != null
            cachePreviewSize(helper)
            jpegLive.setSize(previewWidth, previewHeight)
            if (!hasCaptureAudio) {
                emit(mapOf("type" to "audioUnavailable", "code" to "noAudioSource"))
            }
            lastFrameAt = SystemClock.elapsedRealtime()
            gotPreviewFrame = false
            lastEmittedSignal = null
            startWatchdog()
            startAudioMonitor()
            try {
                refreshLiveFrames()
            } catch (error: Exception) {
                android.util.Log.e("usb_capture", "LAN MJPEG live failed", error)
            }
            openError = null
            openLatch?.countDown()
            emitSignal(hasSignal = true)
        }

        override fun onCameraClose(device: UsbDevice) {
            previewSurface?.let { helper?.removeSurface(it) }
            stopWatchdog()
        }

        override fun onDeviceClose(device: UsbDevice) {}

        override fun onDetach(device: UsbDevice) {
            val id = deviceId(device)
            emit(mapOf("type" to "detached", "deviceId" to id))
            if (id == openedDeviceId) {
                handleDisconnect()
            }
        }

        override fun onCancel(device: UsbDevice) {
            openError = "permissionDenied"
            openLatch?.countDown()
        }

        override fun onError(device: UsbDevice?, e: CameraException) {
            openError = when {
                e.code == CameraException.CAMERA_OPEN_ERROR_BUSY -> "uvcFailed"
                usbGranted -> "powerIssue"
                else -> "uvcFailed"
            }
            openLatch?.countDown()
        }
    }

    fun start() {
        if (helper != null) return
        val cameraHelper = CameraHelper()
        helper = cameraHelper
        cameraHelper.setStateCallback(stateCallback)
    }

    fun stop() {
        close()
        helper?.release()
        helper = null
    }

    fun attachPreview(view: TextureView) {
        previewView = view
        if (!lanLiveBusy) attachSurfaceIfReady()
    }

    fun detachPreview() {
        previewSurface?.let { helper?.removeSurface(it) }
        previewSurface = null
        previewView = null
    }

    fun onPreviewFrame() {
        val now = SystemClock.elapsedRealtime()
        lastFrameAt = now
        gotPreviewFrame = true
        if (fpsWindowStart == 0L) fpsWindowStart = now
        frameCount++
        if (now - fpsWindowStart >= 1000L) {
            measuredFps = frameCount
            frameCount = 0
            fpsWindowStart = now
        }
    }

    fun hasUsbHost(): Boolean {
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_USB_HOST)
    }

    fun listDevices(): List<Map<String, Any?>> {
        val fromHelper = helper?.deviceList?.filterNotNull().orEmpty()
        val devices = if (fromHelper.isNotEmpty()) {
            fromHelper
        } else {
            usbManager.deviceList.values.filter(::isUvcDevice)
        }
        return devices.map(::mapDevice)
    }

    private fun mapDevice(device: UsbDevice): Map<String, Any?> {
        return deviceMap(
            device,
            UiLocale.wrap(context).getString(R.string.usb_capture_card),
        )
    }

    fun captureStatus(): Map<String, Any?> {
        return mapOf(
            "sessionOpen" to (helper?.isCameraOpened == true),
            "recording" to isRecordingActive,
            "deviceId" to openedDeviceId,
            "segmentIndex" to segmentIndex,
            "elapsedMs" to if (sessionStartedAt == 0L) {
                0L
            } else {
                SystemClock.elapsedRealtime() - sessionStartedAt
            },
            "streaming" to streaming,
            "sessionStamp" to if (isRecordingActive && sessionStamp.isNotEmpty()) {
                sessionStamp
            } else {
                null
            },
        )
    }

    fun open(deviceId: String) {
        if (helper?.isCameraOpened == true && openedDeviceId == deviceId) {
            return
        }
        if (isRecordingActive || streaming) {
            throw CaptureException(
                if (streaming && !isRecordingActive) "streamFailed" else "recordingFailed",
                if (streaming && !isRecordingActive) "streamInProgress" else "recordingInProgress",
            )
        }
        if (!hasUsbHost()) {
            throw CaptureException("usbHostMissing")
        }
        val device = findDevice(deviceId) ?: throw CaptureException("uvcFailed")
        usbGranted = false
        openError = null
        openLatch = CountDownLatch(1)
        mainHandler.post {
            helper?.selectDevice(device)
        }
        val opened = openLatch?.await(25, TimeUnit.SECONDS) == true
        when {
            helper?.isCameraOpened == true -> return
            openError == "permissionDenied" -> throw CaptureException("permissionDenied")
            openError == "powerIssue" -> throw CaptureException("powerIssue")
            openError == "uvcFailed" -> throw CaptureException("uvcFailed")
            usbGranted && !opened -> throw CaptureException("powerIssue")
            else -> throw CaptureException("uvcFailed")
        }
    }

    fun close() {
        cancelRotate()
        val saved = salvageRecording()
        teardownSession()
        endRecordingSession()
        emitSaved(saved)
    }

    fun setPreviewMuted(muted: Boolean) {
        previewMuted = muted
    }

    fun setPrefer720p(value: Boolean) {
        prefer720p = value
    }

    fun setMonitorVolume(volume: Double) {
        monitorVolume = volume.toFloat().coerceIn(0f, 1f)
    }

    fun setMonitorDelay(delayMs: Int) {
        val allowed = intArrayOf(0, 50, 100, 200)
        monitorDelayMs = allowed.minByOrNull { kotlin.math.abs(it - delayMs) } ?: 0
    }

    fun setRecordingQuality(preset: String) {
        if (recording || helper?.isRecording == true || streaming) {
            throw CaptureException(
                when {
                    streaming && !recording -> "streamFailed"
                    else -> "recordingFailed"
                },
                when {
                    streaming && !recording -> "streamInProgress"
                    else -> "recordingInProgress"
                },
            )
        }
        qualityPreset = when (preset) {
            "tiny", "small", "high" -> preset
            else -> "standard"
        }
    }

    fun setStreamBitrate(preset: String) {
        if (streaming) {
            throw CaptureException("streamFailed", "streamInProgress")
        }
        streamBitratePreset = EncoderLimits.parseStreamBitrate(preset)
    }

    fun listFormats(): List<Map<String, Any?>> {
        val helper = helper ?: return emptyList()
        return helper.supportedSizeList.orEmpty().map(::formatMap)
    }

    fun setFormat(formatId: String) {
        val lanPublishing = lanLiveBusy ||
            lanLiveViewers.active(streaming = streaming, mjpeg = previewMjpeg)
        CaptureRuntimePolicy.formatLock(
            recording = recording || helper?.isRecording == true,
            streaming = streaming,
            lanLiveBusy = lanPublishing,
        )?.let { (code, details) ->
            throw CaptureException(code, details)
        }
        val helper = helper
        if (helper == null || helper.isCameraOpened != true) {
            throw CaptureException("noPreview")
        }
        val target = helper.supportedSizeList.orEmpty().firstOrNull { formatId(it) == formatId }
            ?: throw CaptureException("uvcFailed")
        val previous = helper.previewSize
        openError = null
        openLatch = CountDownLatch(1)
        mainHandler.post {
            helper.stopPreview()
            helper.closeCamera()
            helper.openCamera(target)
        }
        val opened = openLatch?.await(8, TimeUnit.SECONDS) == true && helper.isCameraOpened == true
        if (opened) return
        if (previous != null) {
            openLatch = CountDownLatch(1)
            mainHandler.post { helper.openCamera(previous) }
            openLatch?.await(8, TimeUnit.SECONDS)
        }
        throw CaptureException("uvcFailed")
    }

    fun listPictureControls(): List<Map<String, Any?>> {
        val control = helper?.uvcControl ?: return emptyList()
        val items = mutableListOf<Map<String, Any?>>()
        if (control.isBrightnessEnable) {
            items.add(pictureMap("brightness", "亮度", control.brightnessPercent, control))
        }
        if (control.isContrastEnable) {
            items.add(pictureMap("contrast", "对比度", control.contrastPercent, control))
        }
        if (control.isSaturationEnable) {
            items.add(pictureMap("saturation", "饱和度", control.saturationPercent, control))
        }
        if (control.isHueEnable) {
            items.add(pictureMap("hue", "色调", control.huePercent, control))
        }
        return items
    }

    fun setPictureControl(id: String, value: Int) {
        val control = helper?.uvcControl ?: return
        val percent = value.coerceIn(0, 100)
        when (id) {
            "brightness" -> if (control.isBrightnessEnable) control.setBrightnessPercent(percent)
            "contrast" -> if (control.isContrastEnable) control.setContrastPercent(percent)
            "saturation" -> if (control.isSaturationEnable) control.setSaturationPercent(percent)
            "hue" -> if (control.isHueEnable) control.setHuePercent(percent)
        }
    }

    fun resetPictureControls() {
        val control = helper?.uvcControl ?: return
        if (control.isBrightnessEnable) control.resetBrightness()
        if (control.isContrastEnable) control.resetContrast()
        if (control.isSaturationEnable) control.resetSaturation()
        if (control.isHueEnable) control.resetHue()
    }

    fun takeSnapshot() {
        val helper = helper
        if (helper == null || helper.isCameraOpened != true) {
            throw CaptureException("noPreview")
        }
        val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "USB_$stamp.jpg")
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/UsbCapture")
        }
        val options = IImageCapture.OutputFileOptions.Builder(
            context.contentResolver,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
        ).build()
        snapshotError = null
        val done = CountDownLatch(1)
        var ok = false
        mainHandler.post {
            helper.takePicture(
                options,
                object : IImageCapture.OnImageCaptureCallback {
                    override fun onImageSaved(outputFileResults: IImageCapture.OutputFileResults) {
                        ok = true
                        done.countDown()
                    }

                    override fun onError(
                        imageCaptureError: Int,
                        message: String,
                        cause: Throwable?,
                    ) {
                        snapshotError = message
                        done.countDown()
                    }
                },
            )
        }
        done.await(8, TimeUnit.SECONDS)
        if (!ok) {
            throw CaptureException("uvcFailed", snapshotError)
        }
    }

    fun startRecording(segmentMinutes: Int = 10) {
        if (recording || helper?.isRecording == true) {
            throw CaptureException("recordingFailed", "recordingInProgress")
        }
        val minutes = if (segmentMinutes in intArrayOf(0, 1, 5, 10, 15, 30)) {
            segmentMinutes
        } else {
            10
        }
        segmentDurationMs = minutes * 60_000L
        sessionStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        segmentIndex = 1
        sessionStartedAt = SystemClock.elapsedRealtime()
        try {
            beginSegment()
        } catch (error: Exception) {
            sessionStamp = ""
            sessionStartedAt = 0L
            throw error
        }
        scheduleRotate()
        startForegroundIfNeeded()
        maybeEmitBatteryHint()
    }

    fun startStream(url: String) {
        if (streaming) {
            throw CaptureException("streamFailed", "streamInProgress")
        }
        val ingest = RtmpUrl.validate(url)
            ?: throw CaptureException("streamFailed", "missingUrl")
        val helper = helper
        if (helper == null || helper.isCameraOpened != true) {
            throw CaptureException("noPreview")
        }
        val existing = streamSession
        if (existing != null && !streaming) {
            try {
                existing.attachRtmp(
                    url = ingest,
                    hasAudio = findUsbAudioDevice() != null,
                )
            } catch (error: Exception) {
                if (error is CaptureException) throw error
                throw CaptureException("streamFailed", error.message ?: "connectFailed")
            }
            streaming = true
            streamStartedAt = SystemClock.elapsedRealtime()
            mjpegHub.clear()
            refreshLiveFrames()
            startAudioMonitor()
            startForegroundIfNeeded()
            maybeEmitBatteryHint()
            emit(mapOf("type" to "streamStarted"))
            return
        }
        val size = helper.previewSize
        val width = size?.width ?: 1280
        val height = size?.height ?: 720
        val fps = size?.fps ?: 30
        val session = RtmpStreamSession(mainHandler) { details ->
            Thread { stopStreamInternal(details = details) }.start()
        }
        streamSession = session
        try {
            session.start(
                helper = helper,
                url = ingest,
                width = width,
                height = height,
                fps = fps,
                videoBitrate = streamVideoBitrate(width, height),
                sampleRate = audioSampleRate,
                channelCount = audioChannelCount,
                hasAudio = findUsbAudioDevice() != null,
            )
        } catch (error: Exception) {
            streamSession = null
            streaming = false
            try {
                session.stop()
            } catch (_: Exception) {
            }
            if (error is CaptureException) throw error
            throw CaptureException("streamFailed", error.message ?: "connectFailed")
        }
        streaming = true
        streamStartedAt = SystemClock.elapsedRealtime()
        mjpegHub.clear()
        refreshLiveFrames()
        startAudioMonitor()
        startForegroundIfNeeded()
        maybeEmitBatteryHint()
        emit(mapOf("type" to "streamStarted"))
    }

    fun stopStream() {
        stopStreamInternal(user = true)
    }

    fun startHttpServer(): Map<String, Any?> {
        if (httpServing && httpServer?.isRunning == true) {
            return mapOf("url" to httpUrl, "port" to httpPort, "running" to true)
        }
        val ipv4 = LanHttpUrl.pickIpv4(ipv4Addresses())
            ?: throw CaptureException("streamFailed", "httpNoNetwork")
        mjpegHub.reopen()
        val server = LanHttpServer(
            context = context,
            listRecordings = { recordingLibrary.list(context) },
            openRecording = { id -> recordingLibrary.openForRead(context, id) },
            mjpegHub = { mjpegHub },
            liveStatus = { liveStatusJson() },
            liveViewers = lanLiveViewers,
            onLiveViewersChanged = { mainHandler.post { refreshLanLive() } },
        )
        val port = server.start(8080)
        httpServer = server
        httpServing = true
        httpPort = port
        httpUrl = LanHttpUrl.display(ipv4, port)
        startForegroundIfNeeded()
        try {
            refreshLiveFrames()
        } catch (error: Exception) {
            android.util.Log.e("usb_capture", "LAN MJPEG live failed", error)
        }
        return mapOf("url" to httpUrl, "port" to port, "running" to true)
    }

    fun stopHttpServer() {
        stopHttpLive()
        httpServer?.stop()
        httpServer = null
        mjpegHub.close()
        httpServing = false
        httpUrl = null
        httpPort = 0
        stopForegroundIfIdle()
        mainHandler.post { attachSurfaceIfReady() }
    }

    fun httpServerStatus(): Map<String, Any?> {
        return mapOf(
            "running" to httpServing,
            "url" to if (httpServing) httpUrl else null,
        )
    }

    private fun ipv4Addresses(): List<String> {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val lp = cm.getLinkProperties(cm.activeNetwork) ?: return emptyList()
        return lp.linkAddresses.mapNotNull { addr ->
            val host = addr.address.hostAddress ?: return@mapNotNull null
            if (addr.address is java.net.Inet4Address) host else null
        }
    }

    private fun stopStreamInternal(
        details: String? = null,
        user: Boolean = false,
        notify: Boolean = true,
    ) {
        val session = streamSession
        streaming = false
        streamStartedAt = 0L
        streamSession = null
        if (session != null) {
            session.encodedSink = null
            try {
                session.stop()
            } catch (_: Exception) {
            }
        }
        refreshLiveFrames()
        stopForegroundIfIdle()
        if (!notify) return
        if (details != null) {
            emit(
                mapOf(
                    "type" to "error",
                    "code" to "streamFailed",
                    "message" to details,
                ),
            )
        }
        if (user || details != null) {
            emit(mapOf("type" to "streamStopped"))
        }
    }

    private fun liveStatusJson(): JSONObject {
        val snap = jpegLive.snapshot()
        return JSONObject()
            .put("hasCard", LanLiveStatus.hasCard(openedDeviceId, gotPreviewFrame))
            .put("mjpeg", previewMjpeg)
            .put("paused", false)
            .put("ready", mjpegHub.hasFrame())
            .put("deviceId", openedDeviceId ?: "")
            .put("running", snap["running"] == true)
            .put("width", snap["width"])
            .put("height", snap["height"])
            .put("jpegWidth", snap["jpegWidth"])
            .put("jpegHeight", snap["jpegHeight"])
            .put("offered", snap["offered"])
            .put("published", snap["published"])
            .put("error", snap["error"] ?: "")
    }

    private fun cachePreviewSize(helper: ICameraHelper) {
        val size = helper.previewSize ?: return
        if (size.width <= 0 || size.height <= 0) return
        previewWidth = size.width
        previewHeight = size.height
        previewMjpeg = size.type == UVCCamera.UVC_VS_FRAME_MJPEG
    }

    private fun refreshLanLive() {
        refreshLiveFrames()
    }

    private fun refreshLiveFrames() {
        val helper = helper
        val lanActive = lanLiveViewers.active(streaming = streaming, mjpeg = previewMjpeg)
        httpLiveEncoding = lanActive
        if (lanActive != lanLiveBusy) {
            lanLiveBusy = lanActive
            emit(mapOf("type" to "lanLiveBusy", "busy" to lanActive))
            if (lanActive) {
                previewSurface?.let { helper?.removeSurface(it) }
                previewSurface = null
            } else {
                attachSurfaceIfReady()
            }
        }
        if (helper == null) return
        when {
            streaming -> helper.setFrameCallback(livePreviewCallback, UVCCamera.PIXEL_FORMAT_NV21)
            lanActive -> helper.setFrameCallback(livePreviewCallback, UVCCamera.PIXEL_FORMAT_RAW)
            else -> try {
                helper.setFrameCallback(null, 0)
            } catch (_: Exception) {
            }
        }
        if (!lanActive) {
            jpegLive.stop()
        }
    }

    private fun stopHttpLive() {
        httpLiveEncoding = false
        jpegLive.stop()
        mjpegHub.clear()
        if (!streaming) {
            try {
                helper?.setFrameCallback(null, 0)
            } catch (_: Exception) {
            }
        }
    }

    private fun copyFrame(frame: java.nio.ByteBuffer): ByteArray {
        val copy = frame.duplicate()
        if (copy.remaining() <= 0 && copy.capacity() > 0) {
            copy.clear()
        }
        val remaining = copy.remaining()
        if (remaining <= 0) return ByteArray(0)
        val bytes = ByteArray(remaining)
        try {
            copy.get(bytes)
        } catch (_: Exception) {
            return ByteArray(0)
        }
        return bytes
    }

    private fun startForegroundIfNeeded() {
        CaptureRecordService.start(context)
    }

    private fun stopForegroundIfIdle() {
        if (!isRecordingActive && !streaming && !httpServing) {
            CaptureRecordService.stop(context)
        }
    }

    private fun beginSegment() {
        val helper = helper
        if (helper == null || helper.isCameraOpened != true) {
            throw CaptureException("noPreview")
        }
        val nn = segmentIndex.toString().padStart(2, '0')
        val videoName = if (segmentDurationMs > 0L) {
            "USB_${sessionStamp}_${nn}_v.mp4"
        } else {
            "USB_${sessionStamp}_v.mp4"
        }
        val videoFile = File(context.cacheDir, videoName)
        videoTemp = videoFile
        audioTemp = File(context.cacheDir, videoName.replace("_v.mp4", "_a.m4a"))
        muxedHasAudio = false
        val size = helper.previewSize
        val bitrate = videoBitrate(size?.width ?: 1920, size?.height ?: 1080)
        val options = VideoCapture.OutputFileOptions.Builder(videoFile).build()
        helper.videoCaptureConfig = helper.videoCaptureConfig
            .setAudioCaptureEnable(false)
            .setBitRate(bitrate)
        savedUri = null
        recordError = null
        recordingEverStarted = false
        startingRecording.set(true)
        if (findUsbAudioDevice() != null) {
            startAudioMonitor()
            aacWriter = CaptureAacWriter(audioTemp!!, audioSampleRate, audioChannelCount)
        }
        val started = CountDownLatch(1)
        mainHandler.post {
            helper.startRecording(
                options,
                object : VideoCapture.OnVideoCaptureCallback {
                    override fun onStart() {
                        recording = true
                        recordingEverStarted = true
                        recordingStartedAt = SystemClock.elapsedRealtime()
                        started.countDown()
                    }

                    override fun onVideoSaved(outputFileResults: VideoCapture.OutputFileResults) {
                        recording = false
                        stopLatch?.countDown()
                    }

                    override fun onError(
                        videoCaptureError: Int,
                        message: String,
                        cause: Throwable?,
                    ) {
                        recordError = message
                        recording = false
                        started.countDown()
                        val userStop = stopLatch != null
                        stopLatch?.countDown()
                        if (!userStop &&
                            !rotating.get() &&
                            recordingEverStarted &&
                            !startingRecording.get()
                        ) {
                            Thread {
                                val saved = salvageRecording()
                                endRecordingSession()
                                emitSaved(saved)
                                emit(
                                    mapOf(
                                        "type" to "error",
                                        "code" to "recordingFailed",
                                        "message" to (message ?: ""),
                                    ),
                                )
                            }.start()
                        }
                    }
                },
            )
        }
        started.await(3, TimeUnit.SECONDS)
        startingRecording.set(false)
        if (!recording && recordError != null) {
            aacWriter?.finish()
            aacWriter = null
            cleanupTemps()
            throw CaptureException("recordingFailed", recordError)
        }
    }

    private fun scheduleRotate() {
        rotateHandler.removeCallbacks(rotateRunnable)
        if (segmentDurationMs <= 0L) return
        rotateHandler.postDelayed(rotateRunnable, segmentDurationMs)
    }

    private fun cancelRotate() {
        rotateHandler.removeCallbacks(rotateRunnable)
    }

    private fun rotateSegment() {
        if (!rotating.compareAndSet(false, true)) return
        try {
            if (sessionStamp.isEmpty()) return
            val completed = segmentIndex
            requestStopEncoder()
            val saved = try {
                publishRecordingOrThrow()
            } catch (_: Exception) {
                publishVideoOnlyOrNull()
            }
            if (saved == null) {
                endRecordingSession()
                emit(
                    mapOf(
                        "type" to "error",
                        "code" to "recordingFailed",
                        "message" to "segmentFailed",
                    ),
                )
                return
            }
            emitSaved(saved, sessionContinuing = true, completedIndex = completed)
            emit(
                mapOf(
                    "type" to "segmentRolled",
                    "path" to saved["path"],
                    "segmentIndex" to completed,
                    "elapsedMs" to (SystemClock.elapsedRealtime() - sessionStartedAt),
                    "sessionContinuing" to true,
                ),
            )
            segmentIndex = completed + 1
            try {
                beginSegment()
                scheduleRotate()
            } catch (error: Exception) {
                endRecordingSession()
                emit(
                    mapOf(
                        "type" to "error",
                        "code" to "recordingFailed",
                        "message" to (error.message ?: "segmentFailed"),
                    ),
                )
            }
        } finally {
            rotating.set(false)
        }
    }

    private fun endRecordingSession() {
        cancelRotate()
        sessionStamp = ""
        sessionStartedAt = 0L
        stopForegroundIfIdle()
    }

    fun maybeEmitBatteryHint() {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (prefs.getBoolean(PREF_BATTERY_HINT, false)) return
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (pm.isIgnoringBatteryOptimizations(context.packageName)) return
        prefs.edit().putBoolean(PREF_BATTERY_HINT, true).apply()
        emit(mapOf("type" to "batteryOptimizationHint"))
    }

    fun openBatterySettings() {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun stopRecording(): Map<String, Any?> {
        cancelRotate()
        requestStopEncoder()
        return try {
            publishRecordingOrThrow()
        } finally {
            endRecordingSession()
        }
    }

    @Synchronized
    private fun salvageRecording(): Map<String, Any?>? {
        if (videoTemp == null && helper?.isRecording != true && !recording) {
            return null
        }
        requestStopEncoder()
        return try {
            publishRecordingOrThrow()
        } catch (_: Exception) {
            publishVideoOnlyOrNull()
        }
    }

    private fun requestStopEncoder() {
        val helper = helper ?: return
        if (helper.isRecording == true) {
            stopLatch = CountDownLatch(1)
            mainHandler.post { helper.stopRecording() }
            stopLatch?.await(8, TimeUnit.SECONDS)
            stopLatch = null
        }
        recording = false
    }

    @Synchronized
    private fun publishRecordingOrThrow(): Map<String, Any?> {
        val audioOk = aacWriter?.finish() == true
        aacWriter = null
        val video = videoTemp ?: throw CaptureException("recordingFailed", recordError)
        val durationMs = currentSegmentDurationMs()
        if (!video.exists() || !SalvagePolicy.isPublishable(video.length(), durationMs)) {
            cleanupTemps()
            throw CaptureException("recordingFailed", recordError)
        }
        val combined = File(context.cacheDir, video.name.replace("_v.mp4", ".mp4"))
        try {
            Mp4Muxer.combine(video, if (audioOk) audioTemp else null, combined)
            muxedHasAudio = audioOk
        } catch (_: Exception) {
            video.copyTo(combined, overwrite = true)
            muxedHasAudio = false
        }
        val uri = CaptureSave.publishMovie(context, combined, combined.name)
        cleanupTemps()
        combined.delete()
        hasCaptureAudio = findUsbAudioDevice() != null
        recording = false
        recordingEverStarted = false
        savedUri = uri
        return CaptureSave.payload(context, uri, muxedHasAudio)
    }

    private fun publishVideoOnlyOrNull(): Map<String, Any?>? {
        val video = videoTemp ?: return null
        val durationMs = currentSegmentDurationMs()
        if (!video.exists() || !SalvagePolicy.isPublishable(video.length(), durationMs)) {
            cleanupTemps()
            return null
        }
        return try {
            val name = video.name.replace("_v.mp4", ".mp4")
            val combined = File(context.cacheDir, name)
            video.copyTo(combined, overwrite = true)
            muxedHasAudio = false
            val uri = CaptureSave.publishMovie(context, combined, name)
            cleanupTemps()
            combined.delete()
            recordingEverStarted = false
            savedUri = uri
            CaptureSave.payload(context, uri, false)
        } catch (_: Exception) {
            cleanupTemps()
            null
        }
    }

    private fun cleanupTemps() {
        try {
            videoTemp?.delete()
        } catch (_: Exception) {
        }
        try {
            audioTemp?.delete()
        } catch (_: Exception) {
        }
        videoTemp = null
        audioTemp = null
        aacWriter = null
    }

    private fun currentSegmentDurationMs(): Long {
        if (recordingStartedAt <= 0L) return 0L
        return (SystemClock.elapsedRealtime() - recordingStartedAt).coerceAtLeast(0L)
    }

    private fun emitSaved(
        saved: Map<String, Any?>?,
        sessionContinuing: Boolean = false,
        completedIndex: Int? = null,
    ) {
        if (saved == null) return
        val payload = HashMap<String, Any?>()
        payload["type"] = "recordingSaved"
        payload.putAll(saved)
        payload["sessionContinuing"] = sessionContinuing
        if (completedIndex != null) {
            payload["segmentIndex"] = completedIndex
        }
        emit(payload)
    }

    private fun teardownSession() {
        previewWidth = 0
        previewHeight = 0
        previewMjpeg = false
        stopStreamInternal(notify = false)
        stopHttpLive()
        stopAudioMonitor()
        try {
            aacWriter?.finish()
        } catch (_: Exception) {
        }
        aacWriter = null
        stopWatchdog()
        mainHandler.post {
            helper?.stopPreview()
            helper?.closeCamera()
        }
        openedDeviceId = null
        hasCaptureAudio = false
        usbGranted = false
        recording = false
        recordingEverStarted = false
        recordingStartedAt = 0L
    }

    private fun handleDisconnect() {
        cancelRotate()
        val saved = salvageRecording()
        teardownSession()
        endRecordingSession()
        emitSaved(saved)
        emit(mapOf("type" to "disconnected", "code" to "disconnected"))
    }

    private fun attachSurfaceIfReady() {
        if (lanLiveBusy) return
        val view = previewView ?: return
        val texture = view.surfaceTexture ?: return
        val helper = helper ?: return
        if (helper.isCameraOpened != true) return
        previewSurface?.let { helper.removeSurface(it) }
        val surface = Surface(texture)
        previewSurface = surface
        helper.addSurface(surface, false)
    }

    private fun pickSize(helper: ICameraHelper): Size? {
        val sizes = helper.supportedSizeList ?: return null
        val mjpeg = sizes.filter { it.type == UVCCamera.UVC_VS_FRAME_MJPEG }
        val pool = mjpeg.ifEmpty { sizes }
        val target = if (prefer720p) 1280 to 720 else 1920 to 1080
        return pool.firstOrNull { it.width == target.first && it.height == target.second }
            ?: pool.maxByOrNull { it.width * it.height }
    }

    private fun findDevice(deviceId: String): UsbDevice? {
        helper?.deviceList?.firstOrNull { deviceId(it) == deviceId }?.let { return it }
        return usbManager.deviceList.values.firstOrNull { deviceId(it) == deviceId }
    }

    private fun findUsbAudioDevice(): AudioDeviceInfo? {
        return audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS).firstOrNull(::isUsbInput)
    }

    private fun isUsbInput(info: AudioDeviceInfo): Boolean {
        return info.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
            info.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
            info.type == AudioDeviceInfo.TYPE_USB_ACCESSORY
    }

    private fun startAudioMonitor() {
        val usbAudio = findUsbAudioDevice() ?: return
        if (!monitorRunning.compareAndSet(false, true)) return
        val rates = usbAudio.sampleRates
        audioSampleRate = when {
            48000 in rates -> 48000
            44100 in rates -> 44100
            rates.isNotEmpty() -> rates.maxOrNull() ?: 48000
            else -> 48000
        }
        audioChannelCount = if (usbAudio.channelCounts.contains(2) || usbAudio.channelCounts.isEmpty()) 2 else 1
        val inMask = if (audioChannelCount == 2) {
            AudioFormat.CHANNEL_IN_STEREO
        } else {
            AudioFormat.CHANNEL_IN_MONO
        }
        val outMask = if (audioChannelCount == 2) {
            AudioFormat.CHANNEL_OUT_STEREO
        } else {
            AudioFormat.CHANNEL_OUT_MONO
        }
        val minBuf = AudioRecord.getMinBufferSize(
            audioSampleRate,
            inMask,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val record = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            audioSampleRate,
            inMask,
            AudioFormat.ENCODING_PCM_16BIT,
            minBuf * 2,
        )
        record.preferredDevice = usbAudio
        val track = AudioTrack.Builder()
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(audioSampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(outMask)
                    .build(),
            )
            .setBufferSizeInBytes(minBuf * 2)
            .build()
        val frameBytes = audioChannelCount * 2
        monitorThread = Thread {
            try {
                record.startRecording()
                val routed = if (Build.VERSION.SDK_INT >= 24) record.routedDevice else null
                if (routed != null && !isUsbInput(routed)) {
                    return@Thread
                }
                track.play()
                val buffer = ByteArray(minBuf)
                val delayQueue = ArrayDeque<ByteArray>()
                var queued = 0
                while (monitorRunning.get()) {
                    val read = record.read(buffer, 0, buffer.size)
                    if (read <= 0) continue
                    aacWriter?.writePcm(buffer, read)
                    streamSession?.writePcm(buffer, read)
                    val scaled = scalePcm(buffer, read, monitorVolume)
                    emitPeak(scaled)
                    val targetDelay = (audioSampleRate * frameBytes * monitorDelayMs) / 1000
                    if (targetDelay <= 0) {
                        if (!previewMuted) {
                            track.write(scaled, 0, scaled.size)
                        }
                    } else {
                        delayQueue.addLast(scaled)
                        queued += scaled.size
                        while (queued - (delayQueue.firstOrNull()?.size ?: 0) >= targetDelay) {
                            val chunk = delayQueue.removeFirst()
                            queued -= chunk.size
                            if (!previewMuted) {
                                track.write(chunk, 0, chunk.size)
                            }
                        }
                    }
                }
            } catch (_: Exception) {
            } finally {
                try {
                    record.stop()
                } catch (_: Exception) {
                }
                record.release()
                try {
                    track.stop()
                } catch (_: Exception) {
                }
                track.release()
                monitorRunning.set(false)
            }
        }.also { it.start() }
    }

    private fun stopAudioMonitor() {
        monitorRunning.set(false)
        monitorThread?.join(500)
        monitorThread = null
    }

    private val watchdog = object : Runnable {
        override fun run() {
            if (helper?.isCameraOpened == true) {
                val now = SystemClock.elapsedRealtime()
                val hasSignal = !gotPreviewFrame || now - lastFrameAt < SIGNAL_TIMEOUT_MS
                emitSignal(hasSignal)
                if (streaming && !hasSignal && gotPreviewFrame) {
                    Thread { stopStreamInternal(details = "noSignal") }.start()
                }
            }
            mainHandler.postDelayed(this, 500)
        }
    }

    private fun startWatchdog() {
        mainHandler.removeCallbacks(watchdog)
        mainHandler.post(watchdog)
    }

    private fun stopWatchdog() {
        mainHandler.removeCallbacks(watchdog)
    }

    private fun emitSignal(hasSignal: Boolean) {
        val size = helper?.previewSize
        val bytes = if (recording && recordingStartedAt > 0) {
            val elapsedMs = SystemClock.elapsedRealtime() - recordingStartedAt
            val bitrate = videoBitrate(size?.width ?: 1920, size?.height ?: 1080)
            (elapsedMs * bitrate / 8 / 1000).toInt()
        } else {
            0
        }
        val event = mapOf(
            "type" to "signal",
            "width" to (size?.width ?: 0),
            "height" to (size?.height ?: 0),
            "fps" to if (measuredFps > 0) measuredFps else (size?.fps ?: 0),
            "fourcc" to fourcc(size?.type),
            "hasSignal" to hasSignal,
            "bytesWritten" to bytes,
        )
        if (event == lastEmittedSignal) return
        lastEmittedSignal = event
        emit(event)
    }

    private fun emitPeak(pcm: ByteArray) {
        val now = SystemClock.elapsedRealtime()
        if (now - lastPeakAt < 100) return
        lastPeakAt = now
        var max = 0
        var i = 0
        while (i + 1 < pcm.size) {
            val sample = (pcm[i].toInt() and 0xff) or (pcm[i + 1].toInt() shl 8)
            val signed = sample.toShort().toInt()
            val mag = kotlin.math.abs(signed)
            if (mag > max) max = mag
            i += 2
        }
        emit(mapOf("type" to "audioPeak", "peak" to max / 32768.0))
    }

    private fun scalePcm(src: ByteArray, length: Int, volume: Float): ByteArray {
        if (volume >= 0.999f) return src.copyOf(length)
        val out = ByteArray(length)
        var i = 0
        while (i + 1 < length) {
            val sample = (src[i].toInt() and 0xff) or (src[i + 1].toInt() shl 8)
            val scaled = (sample.toShort().toInt() * volume).toInt().coerceIn(-32768, 32767)
            out[i] = (scaled and 0xff).toByte()
            out[i + 1] = ((scaled shr 8) and 0xff).toByte()
            i += 2
        }
        return out
    }

    private fun videoBitrate(width: Int, height: Int): Int {
        val base = when (qualityPreset) {
            "high" -> 16_000_000
            "small" -> 4_000_000
            "tiny" -> 2_000_000
            else -> 8_000_000
        }
        return EncoderLimits.scaledBitrate(base, width, height)
    }

    private fun streamVideoBitrate(width: Int, height: Int): Int {
        return EncoderLimits.scaledBitrate(
            EncoderLimits.streamBaseBitrate(streamBitratePreset),
            width,
            height,
        )
    }

    private fun formatMap(size: Size): Map<String, Any?> {
        return mapOf(
            "id" to formatId(size),
            "width" to size.width,
            "height" to size.height,
            "fps" to size.fps,
            "fourcc" to fourcc(size.type),
        )
    }

    private fun formatId(size: Size): String = "${size.type}:${size.width}x${size.height}@${size.fps}"

    private fun pictureMap(
        id: String,
        label: String,
        value: Int,
        @Suppress("UNUSED_PARAMETER") control: UVCControl,
    ): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "label" to label,
            "min" to 0,
            "max" to 100,
            "value" to value.coerceIn(0, 100),
            "defaultValue" to 50,
        )
    }

    private fun fourcc(type: Int?): String {
        return when (type) {
            UVCCamera.UVC_VS_FRAME_MJPEG -> "MJPG"
            UVCCamera.UVC_VS_FRAME_UNCOMPRESSED -> "YUY2"
            else -> type?.toString() ?: ""
        }
    }

    companion object {
        const val PREVIEW_VIEW_TYPE = "usb_capture/preview"
        private const val SIGNAL_TIMEOUT_MS = 2000L
        private const val PREFS_NAME = "usb_capture"
        private const val PREF_BATTERY_HINT = "battery_hint_shown"

        fun isUvcDevice(device: UsbDevice): Boolean {
            if (device.deviceClass == UsbConstants.USB_CLASS_VIDEO) return true
            for (i in 0 until device.interfaceCount) {
                val usbClass = device.getInterface(i).interfaceClass
                if (usbClass == UsbConstants.USB_CLASS_VIDEO) return true
            }
            return false
        }

        fun hasAudioInterface(device: UsbDevice): Boolean {
            for (i in 0 until device.interfaceCount) {
                if (device.getInterface(i).interfaceClass == UsbConstants.USB_CLASS_AUDIO) {
                    return true
                }
            }
            return false
        }

        fun deviceId(device: UsbDevice): String =
            "${device.vendorId}:${device.productId}:${device.deviceName}"

        fun deviceMap(
            device: UsbDevice,
            fallbackName: String = "USB capture card",
        ): Map<String, Any?> {
            val name = device.productName?.ifBlank { null } ?: fallbackName
            return mapOf(
                "id" to deviceId(device),
                "name" to name,
                "hasAudio" to hasAudioInterface(device),
            )
        }
    }
}

class CaptureException(val code: String, val details: String? = null) : Exception(details ?: code)

class RecordingHud(
    val elapsedMs: Long,
    val segmentIndex: Int,
    val segmented: Boolean,
    val recording: Boolean = true,
    val streaming: Boolean = false,
    val httpServing: Boolean = false,
)
