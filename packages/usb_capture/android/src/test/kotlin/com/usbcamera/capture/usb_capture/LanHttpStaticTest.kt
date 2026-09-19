package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class LanHttpStaticTest {
    @Test
    fun faviconPathsServeAppIconPng() {
        val ico = LanHttpStatic.fileFor("/favicon.ico")
        val png = LanHttpStatic.fileFor("/favicon.png")
        assertEquals("lan_http/favicon.png", ico?.asset)
        assertEquals("image/png", ico?.mime)
        assertEquals(ico, png)
    }

    @Test
    fun otherPathsAreNotStaticAssets() {
        assertNull(LanHttpStatic.fileFor("/"))
        assertNull(LanHttpStatic.fileFor("/index.html"))
        assertNull(LanHttpStatic.fileFor("/api/recordings"))
    }
}
