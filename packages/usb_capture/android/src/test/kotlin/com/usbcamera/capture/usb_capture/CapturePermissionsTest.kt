package com.usbcamera.capture.usb_capture

import android.Manifest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

internal class CapturePermissionsTest {
    @Test
    fun captureRuntimeIsCameraAndMicrophoneOnly() {
        val permissions = CapturePermissions.captureRuntime()
        assertEquals(
            listOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO),
            permissions,
        )
        assertFalse(permissions.contains(Manifest.permission.POST_NOTIFICATIONS))
    }

    @Test
    fun notificationRuntimeStartsAtApi33() {
        assertEquals(emptyList(), CapturePermissions.notificationRuntime(32))
        assertEquals(
            listOf(Manifest.permission.POST_NOTIFICATIONS),
            CapturePermissions.notificationRuntime(33),
        )
    }
}
