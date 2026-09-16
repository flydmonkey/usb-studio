package com.usbcamera.capture.usb_capture

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class UsbCapturePlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var events: EventChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var appContext: Context? = null
    private var permissionResult: MethodChannel.Result? = null
    private var pickResult: MethodChannel.Result? = null
    private val library = RecordingLibrary { activity }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "usb_capture")
        channel.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "usb_capture/events")
        events.setStreamHandler(this)
        val engine = CaptureRuntime.obtain(binding.applicationContext)
        engine.updateEmit { event ->
            val activity = activity
            if (activity != null) {
                activity.runOnUiThread { CaptureRuntime.eventSink?.success(event) }
            } else {
                Handler(Looper.getMainLooper()).post {
                    CaptureRuntime.eventSink?.success(event)
                }
            }
        }
        binding.platformViewRegistry.registerViewFactory(
            CaptureEngine.PREVIEW_VIEW_TYPE,
            PreviewViewFactory { CaptureRuntime.engine },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        CaptureRuntime.releaseIfIdle()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        detachActivityListeners()
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivityListeners()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivityListeners()
        activity = null
    }

    private fun detachActivityListeners() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        CaptureRuntime.eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        CaptureRuntime.eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val engine = CaptureRuntime.engine
        when (call.method) {
            "getPlatformProfile" -> result.success(platformProfile())
            "getCaptureStatus" -> result.success(
                engine?.captureStatus()
                    ?: mapOf("sessionOpen" to false, "recording" to false),
            )
            "requestPermissions" -> requestPermissions(result)
            "listDevices" -> result.success(engine?.listDevices() ?: emptyList<Map<String, Any?>>())
            "listFormats" -> result.success(engine?.listFormats() ?: emptyList<Map<String, Any?>>())
            "setFormat" -> {
                val id = call.argument<String>("formatId")
                if (id == null) {
                    result.error("uvcFailed", "uvcFailed", null)
                    return
                }
                runOffMain(result) {
                    engine?.setFormat(id)
                    null
                }
            }
            "setMonitorVolume" -> {
                engine?.setMonitorVolume(call.argument<Number>("volume")?.toDouble() ?: 1.0)
                result.success(null)
            }
            "setMonitorDelay" -> {
                engine?.setMonitorDelay(call.argument<Number>("delayMs")?.toInt() ?: 0)
                result.success(null)
            }
            "listPictureControls" -> result.success(
                engine?.listPictureControls() ?: emptyList<Map<String, Any?>>(),
            )
            "setPictureControl" -> {
                val id = call.argument<String>("id") ?: ""
                val value = call.argument<Number>("value")?.toInt() ?: 50
                engine?.setPictureControl(id, value)
                result.success(null)
            }
            "resetPictureControls" -> {
                engine?.resetPictureControls()
                result.success(null)
            }
            "takeSnapshot" -> runOffMain(result) {
                engine?.takeSnapshot()
                null
            }
            "setRecordingQuality" -> {
                try {
                    engine?.setRecordingQuality(call.argument<String>("preset") ?: "standard")
                    result.success(null)
                } catch (error: CaptureException) {
                    result.error(error.code, error.details ?: error.code, null)
                }
            }
            "open" -> {
                val id = call.argument<String>("deviceId")
                if (id == null) {
                    result.error("uvcFailed", "uvcFailed", null)
                    return
                }
                runOffMain(result) {
                    engine?.setPrefer720p(isTelevision())
                    engine?.open(id)
                    null
                }
            }
            "close" -> {
                engine?.close()
                result.success(null)
            }
            "setPreviewMuted" -> {
                engine?.setPreviewMuted(call.argument<Boolean>("muted") == true)
                result.success(null)
            }
            "startRecording" -> runOffMain(result) {
                val minutes = call.argument<Number>("segmentMinutes")?.toInt() ?: 10
                engine?.startRecording(minutes)
                null
            }
            "stopRecording" -> runOffMain(result) {
                engine?.stopRecording()
            }
            "startStream" -> runOffMain(result) {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    throw CaptureException("streamFailed", "missingUrl")
                }
                (engine ?: throw CaptureException("noPreview")).startStream(url)
                null
            }
            "stopStream" -> runOffMain(result) {
                engine?.stopStream()
                null
            }
            "listRecordings" -> runOffMain(result) {
                val ctx = appContext ?: throw CaptureException("unknown")
                library.list(ctx)
            }
            "concatSession" -> {
                val stamp = call.argument<String>("sessionStamp")
                val displayName = call.argument<String>("displayName")
                val uris = (call.argument<ArrayList<*>>("uris") ?: arrayListOf<Any?>())
                    .mapNotNull { it as? String }
                if (stamp.isNullOrBlank() || uris.size < 2 || displayName.isNullOrBlank()) {
                    result.error("recordingFailed", "concatFailed", null)
                    return
                }
                runOffMain(result) {
                    val ctx = appContext ?: throw CaptureException("unknown")
                    val status = engine?.captureStatus().orEmpty()
                    val recordingStamp = if (status["recording"] == true) {
                        status["sessionStamp"] as? String
                    } else {
                        null
                    }
                    library.concat(ctx, stamp, uris, displayName, recordingStamp)
                }
            }
            "deleteRecording" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("unknown", "missingId", null)
                    return
                }
                runOffMain(result) {
                    val ctx = appContext ?: throw CaptureException("unknown")
                    library.delete(ctx, id)
                    null
                }
            }
            "shareRecording" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("unknown", "missingId", null)
                    return
                }
                try {
                    library.share(id)
                    result.success(null)
                } catch (error: CaptureException) {
                    result.error(error.code, error.details ?: error.code, null)
                } catch (error: Exception) {
                    result.error("unknown", error.message ?: LibraryCopyShareFailed, null)
                }
            }
            "openRecording" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("unknown", "missingId", null)
                    return
                }
                try {
                    library.open(id)
                    result.success(null)
                } catch (error: CaptureException) {
                    result.error(error.code, error.details ?: error.code, null)
                } catch (_: Exception) {
                    result.error("unknown", "playFailed", null)
                }
            }
            "renameRecording" -> {
                val id = call.argument<String>("id")
                val displayName = call.argument<String>("displayName")
                if (id.isNullOrBlank() || displayName == null) {
                    result.error("unknown", "renameInvalid", null)
                    return
                }
                runOffMain(result) {
                    val ctx = appContext ?: throw CaptureException("unknown")
                    library.rename(ctx, id, displayName)
                }
            }
            "openBatterySettings" -> {
                openBatterySettings()
                result.success(null)
            }
            "setSaveLocation" -> {
                val ctx = appContext
                if (ctx == null) {
                    result.error("unknown", "no context", null)
                    return
                }
                CaptureSave.set(
                    ctx,
                    call.argument<String>("kind") ?: CaptureSave.KIND_GALLERY,
                    call.argument<String>("uri"),
                )
                result.success(null)
            }
            "pickSaveFolder" -> pickSaveFolder(result)
            "startHttpServer" -> runOffMain(result) {
                val ctx = appContext ?: throw CaptureException("unknown")
                CaptureRuntime.obtain(ctx).startHttpServer()
            }
            "stopHttpServer" -> runOffMain(result) {
                CaptureRuntime.engine?.stopHttpServer()
                CaptureRuntime.releaseIfIdle()
                null
            }
            "httpServerStatus" -> runOffMain(result) {
                CaptureRuntime.engine?.httpServerStatus()
                    ?: mapOf("running" to false)
            }
            "setUiLocale" -> {
                UiLocale.setTag(call.argument<String>("tag"))
                appContext?.let { CaptureRecordService.refresh(it) }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun runOffMain(
        result: MethodChannel.Result,
        block: () -> Any?,
    ) {
        Thread {
            try {
                val value = block()
                Handler(Looper.getMainLooper()).post { result.success(value) }
            } catch (error: CaptureException) {
                Handler(Looper.getMainLooper()).post {
                    result.error(error.code, error.details ?: error.code, null)
                }
            } catch (error: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("unknown", error.message, null)
                }
            }
        }.start()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        val cameraOk = isGranted(permissions, grantResults, Manifest.permission.CAMERA)
        val audioOk = isGranted(permissions, grantResults, Manifest.permission.RECORD_AUDIO)
        val pending = permissionResult
        permissionResult = null
        if (cameraOk && audioOk) {
            pending?.success(null)
        } else {
            pending?.error("permissionDenied", "permissionDenied", null)
        }
        return true
    }

    private fun isGranted(
        permissions: Array<out String>,
        grantResults: IntArray,
        permission: String,
    ): Boolean {
        val index = permissions.indexOf(permission)
        if (index < 0) return true
        return index < grantResults.size && grantResults[index] == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("permissionDenied", "no activity", null)
            return
        }
        val needed = mutableListOf(
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO,
        )
        if (Build.VERSION.SDK_INT >= 33) {
            needed.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        val missing = needed.filter {
            ContextCompat.checkSelfPermission(act, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(null)
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(act, missing.toTypedArray(), PERMISSION_REQUEST)
    }

    private fun openBatterySettings() {
        val ctx = activity ?: appContext ?: return
        val ignored = if (Build.VERSION.SDK_INT >= 23) {
            val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(ctx.packageName)
        } else {
            true
        }
        val intent = if (ignored) {
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        } else {
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${ctx.packageName}")
            }
        }
        if (activity == null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        ctx.startActivity(intent)
    }

    private fun platformProfile(): Map<String, Any?> {
        val ctx = appContext ?: return emptyMap()
        val pm = ctx.packageManager
        return mapOf(
            "usbCaptureSupported" to true,
            "televisionUiMode" to isTelevision(),
            "hasUsbHost" to pm.hasSystemFeature(PackageManager.FEATURE_USB_HOST),
            "hasTouchscreen" to pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN),
            "customSaveFolderSupported" to true,
            "rtmpStreamSupported" to true,
            "httpLanSupported" to true,
        )
    }

    private fun isTelevision(): Boolean {
        val ctx = appContext ?: return false
        val uiMode = ctx.resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK
        return uiMode == Configuration.UI_MODE_TYPE_TELEVISION ||
            ctx.packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
    }

    private fun pickSaveFolder(result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("unknown", "no activity", null)
            return
        }
        pickResult?.success(null)
        pickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        try {
            act.startActivityForResult(intent, PICK_FOLDER)
        } catch (error: Exception) {
            pickResult = null
            result.error("unknown", error.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_FOLDER) return false
        val pending = pickResult
        pickResult = null
        val uri = data?.data
        val ctx = activity ?: appContext
        if (resultCode != Activity.RESULT_OK || uri == null || ctx == null) {
            pending?.success(null)
            return true
        }
        val takeFlags = data.flags and (
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        try {
            ctx.contentResolver.takePersistableUriPermission(uri, takeFlags)
        } catch (_: SecurityException) {
        }
        CaptureSave.set(ctx, CaptureSave.KIND_CUSTOM, uri.toString())
        pending?.success(
            mapOf(
                "kind" to CaptureSave.KIND_CUSTOM,
                "uri" to uri.toString(),
                "folderName" to CaptureSave.folderName(ctx),
            ),
        )
        return true
    }

    companion object {
        private const val PERMISSION_REQUEST = 2401
        private const val PICK_FOLDER = 2403
        private const val LibraryCopyShareFailed = "shareUnavailable"
    }
}
