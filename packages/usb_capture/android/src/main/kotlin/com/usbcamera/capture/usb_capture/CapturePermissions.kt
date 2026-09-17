package com.usbcamera.capture.usb_capture

import android.Manifest
import android.os.Build

internal object CapturePermissions {
    fun captureRuntime(): List<String> = listOf(
        Manifest.permission.CAMERA,
        Manifest.permission.RECORD_AUDIO,
    )

    fun notificationRuntime(sdkInt: Int = Build.VERSION.SDK_INT): List<String> {
        return if (sdkInt >= 33) {
            listOf(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            emptyList()
        }
    }
}
