package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class SalvagePolicyTest {
    @Test
    fun rejectsContainerOnlyFilesEvenIfTheClockRan() {
        assertFalse(SalvagePolicy.isPublishable(bytes = 2_048, durationMs = 12_000))
        assertFalse(SalvagePolicy.isPublishable(bytes = 16_384, durationMs = 8_000))
    }

    @Test
    fun rejectsShortTakesEvenWhenTheFileLooksLarge() {
        assertFalse(SalvagePolicy.isPublishable(bytes = 200_000, durationMs = 400))
        assertFalse(SalvagePolicy.isPublishable(bytes = 80_000, durationMs = 0))
    }

    @Test
    fun publishesASegmentWithBothSizeAndDuration() {
        assertTrue(SalvagePolicy.isPublishable(bytes = 64 * 1024, durationMs = 2_000))
        assertTrue(SalvagePolicy.isPublishable(bytes = 2_000_000, durationMs = 60_000))
    }
}
