package com.usbcamera.capture.usb_capture

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object CaptureRuntime {
    @Volatile
    var engine: CaptureEngine? = null

    @Volatile
    var eventSink: EventChannel.EventSink? = null

    @Synchronized
    fun obtain(context: Context): CaptureEngine {
        engine?.let { return it }
        val created = CaptureEngine(context.applicationContext) { event ->
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(event)
            }
        }
        created.start()
        engine = created
        return created
    }

    @Synchronized
    fun releaseIfIdle() {
        val current = engine ?: return
        if (current.isRecordingActive || current.isStreaming || current.isHttpServing) return
        current.stop()
        engine = null
    }
}
