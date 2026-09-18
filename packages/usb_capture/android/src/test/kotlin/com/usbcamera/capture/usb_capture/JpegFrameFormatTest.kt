package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals

internal class JpegFrameFormatTest {
    @Test
    fun classifiesFullHdBuffers() {
        assertEquals(JpegFrameFormat.Kind.Nv21, JpegFrameFormat.kind(1920 * 1080 * 3 / 2, 1920, 1080))
        assertEquals(JpegFrameFormat.Kind.Rgbx, JpegFrameFormat.kind(1920 * 1080 * 4, 1920, 1080))
        assertEquals(JpegFrameFormat.Kind.Unknown, JpegFrameFormat.kind(100, 1920, 1080))
        assertEquals(1920 to 1080, JpegFrameFormat.inferSize(1920 * 1080 * 3 / 2))
        assertEquals(1280 to 720, JpegFrameFormat.inferSize(1280 * 720 * 4))
    }
}
