package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class HttpRangeTest {
    @Test
    fun parsesClosedRange() {
        val r = HttpRange.parse("bytes=0-499", 1000)!!
        assertEquals(0, r.start)
        assertEquals(499, r.end)
    }

    @Test
    fun parsesOpenEndedRangeToEof() {
        val r = HttpRange.parse("bytes=500-", 1000)!!
        assertEquals(500, r.start)
        assertEquals(999, r.end)
    }

    @Test
    fun nullHeaderReturnsNull() {
        assertNull(HttpRange.parse(null, 1000))
    }

    @Test
    fun blankHeaderReturnsNull() {
        assertNull(HttpRange.parse("   ", 1000))
    }

    @Test
    fun illegalHeaderReturnsNull() {
        assertNull(HttpRange.parse("invalid", 1000))
        assertNull(HttpRange.parse("bytes=abc-def", 1000))
    }

    @Test
    fun emptyFileReturnsNull() {
        assertNull(HttpRange.parse("bytes=0-", 0))
    }
}
