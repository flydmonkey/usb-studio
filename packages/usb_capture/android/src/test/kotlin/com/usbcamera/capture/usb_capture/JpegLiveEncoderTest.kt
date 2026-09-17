package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertNull

internal class JpegLiveEncoderTest {
    @Test
    fun offerFramePublishesJpegWithoutStart() {
        val hub = MjpegHub()
        val encoder = JpegLiveEncoder(hub, previewView = { null })
        val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x01, 0x02)
        encoder.offerFrame(jpeg)
        val got = hub.awaitNext(0, 200)
        assertContentEquals(jpeg, got?.second)
    }

    @Test
    fun offerFrameDropsNonJpegWhenNotRunning() {
        val hub = MjpegHub()
        val encoder = JpegLiveEncoder(hub, previewView = { null })
        encoder.offerFrame(ByteArray(1920 * 1080 * 3 / 2))
        assertNull(hub.awaitNext(0, 50))
    }
}
