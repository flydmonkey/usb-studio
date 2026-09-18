package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class CaptureRuntimePolicyTest {
    @Test
    fun keepsEngineWhenPreviewSessionStillOpenAfterLanStops() {
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = false,
                httpServing = false,
                sessionOpen = true,
            ),
        )
    }

    @Test
    fun releasesOnlyWhenNothingIsUsingTheCamera() {
        assertTrue(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = false,
                httpServing = false,
                sessionOpen = false,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = true,
                streaming = false,
                httpServing = false,
                sessionOpen = false,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = true,
                httpServing = false,
                sessionOpen = false,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = false,
                httpServing = true,
                sessionOpen = false,
            ),
        )
    }
}
