package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class LibraryNamesTest {
    @Test
    fun normalizeAppendsMp4AndRejectsIllegalNames() {
        assertEquals("婚礼.mp4", LibraryNames.normalize("婚礼"))
        assertEquals("婚礼.mp4", LibraryNames.normalize(" 婚礼.mp4 "))
        assertEquals("USB_a.mp4", LibraryNames.normalize("USB_a.MP4"))
        assertNull(LibraryNames.normalize(""))
        assertNull(LibraryNames.normalize(".mp4"))
        assertNull(LibraryNames.normalize("a/b"))
        assertNull(LibraryNames.normalize("a:b"))
    }

    @Test
    fun takenIgnoresTheCurrentName() {
        assertTrue(LibraryNames.same("婚礼.mp4", "婚礼.MP4"))
        assertTrue(
            LibraryNames.taken(listOf("婚礼.mp4", "USB_a_01.mp4"), "USB_a_01.mp4", "婚礼.mp4"),
        )
        assertFalse(
            LibraryNames.taken(listOf("USB_a_01.mp4"), "USB_a_01.mp4", "USB_a_01.mp4"),
        )
    }
}
