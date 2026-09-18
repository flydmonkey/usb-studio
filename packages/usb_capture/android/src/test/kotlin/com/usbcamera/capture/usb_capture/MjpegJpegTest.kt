package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class MjpegJpegTest {
    @Test
    fun extractsJpegStartingAtSoi() {
        val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x01, 0x02)
        assertContentEquals(jpeg, MjpegJpeg.extract(jpeg))
    }

    @Test
    fun skipsPreambleBeforeSoi() {
        val jpeg = byteArrayOf(0x00, 0x11, 0xFF.toByte(), 0xD8.toByte(), 0x22)
        assertContentEquals(
            byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x22),
            MjpegJpeg.extract(jpeg),
        )
    }

    @Test
    fun rejectsNonJpeg() {
        assertNull(MjpegJpeg.extract(byteArrayOf(0x00, 0x01, 0x02)))
        assertNull(MjpegJpeg.extract(byteArrayOf()))
    }
}

internal class MjpegHubTest {
    @Test
    fun keepsLatestFrameAndDropsStaleWaitersForward() {
        val hub = MjpegHub()
        val jpeg1 = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x01)
        val jpeg2 = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x02)
        hub.publish(jpeg1)
        hub.publish(jpeg2)
        val first = hub.awaitNext(0, 50)
        assertEquals(2L, first?.first)
        assertContentEquals(jpeg2, first?.second)
    }

    @Test
    fun ignoresNonJpegPublishes() {
        val hub = MjpegHub()
        hub.publish(byteArrayOf(0x12, 0x34))
        assertNull(hub.awaitNext(0, 20))
    }
}

internal class MjpegPartTest {
    @Test
    fun wrapsJpegInMultipartPart() {
        val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x01)
        val part = MjpegPart.encode("usbframe", jpeg)
        val text = String(part, Charsets.ISO_8859_1)
        assertTrue(text.startsWith("--usbframe\r\n"))
        assertTrue(text.contains("Content-Type: image/jpeg\r\n"))
        assertTrue(text.contains("Content-Length: 3\r\n"))
        assertContentEquals(
            jpeg,
            part.copyOfRange(part.size - jpeg.size - 2, part.size - 2),
        )
    }
}

internal class MjpegMultipartStreamTest {
    @Test
    fun readsLatestJpegAsMultipart() {
        val hub = MjpegHub()
        val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x07)
        hub.publish(jpeg)
        val stream = MjpegMultipartStream(hub)
        val expected = MjpegPart.encode(MjpegPart.BOUNDARY, jpeg)
        val buf = ByteArray(expected.size)
        assertEquals(expected.size, stream.read(buf))
        assertContentEquals(expected, buf)
        hub.close()
        assertEquals(-1, stream.read())
    }

    @Test
    fun closeInvokesCallbackOnce() {
        val hub = MjpegHub()
        var n = 0
        val stream = MjpegMultipartStream(hub, onClosed = { n++ })
        stream.close()
        stream.close()
        assertEquals(1, n)
        assertEquals(-1, stream.read())
    }
}
