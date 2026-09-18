package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class PreviewSurfacePolicyTest {
    @Test
    fun formatSwitchReleasesExistingSurfaceAndUsesNewSize() {
        val plan = PreviewSurfacePolicy.plan(
            existingSurface = true,
            previewWidth = 1280,
            previewHeight = 720,
        )
        assertEquals(1280, plan?.bufferWidth)
        assertEquals(720, plan?.bufferHeight)
        assertTrue(plan?.releaseExisting == true)
    }

    @Test
    fun firstAttachDoesNotReleaseWhenNoSurfaceYet() {
        val plan = PreviewSurfacePolicy.plan(
            existingSurface = false,
            previewWidth = 1920,
            previewHeight = 1080,
        )
        assertFalse(plan?.releaseExisting == true)
        assertEquals(1920, plan?.bufferWidth)
    }

    @Test
    fun skipsAttachUntilPreviewSizeIsKnown() {
        assertNull(
            PreviewSurfacePolicy.plan(
                existingSurface = true,
                previewWidth = 0,
                previewHeight = 720,
            ),
        )
    }
}
