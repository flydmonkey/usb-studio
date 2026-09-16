package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class EncoderLimitsTest {
    @Test
    fun capsPreviewFpsAtThirtyForHardwareEncoder() {
        assertEquals(30, EncoderLimits.videoFps(60))
        assertEquals(25, EncoderLimits.videoFps(25))
        assertEquals(5, EncoderLimits.videoFps(1))
    }

    @Test
    fun capsHlsBitrate() {
        assertEquals(4_000_000, EncoderLimits.hlsBitrate(8_000_000))
        assertEquals(2_000_000, EncoderLimits.hlsBitrate(2_000_000))
    }

    @Test
    fun treatsCodecNoMemoryAsLiveEncodeFailure() {
        assertTrue(EncoderLimits.isLiveEncodeFailure("Error 0xfffffff4"))
        assertTrue(EncoderLimits.isLiveEncodeFailure("Codec reported err 0xfffffff4/NO_MEMORY"))
        assertEquals("httpLiveFailed", EncoderLimits.liveFailureDetails("Error 0xfffffff4"))
    }

    @Test
    fun clampsHlsSegmentDuration() {
        assertEquals(0.4, EncoderLimits.hlsSegmentDuration(0.05), 0.0001)
        assertEquals(2.0, EncoderLimits.hlsSegmentDuration(2.0), 0.0001)
        assertEquals(2.5, EncoderLimits.hlsSegmentDuration(82.7), 0.0001)
    }
}
