package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class VodDownloadTest {
    @Test
    fun requestedOnlyWhenQueryIsOne() {
        assertTrue(VodDownload.requested(mapOf("download" to "1")))
        assertFalse(VodDownload.requested(emptyMap()))
        assertFalse(VodDownload.requested(null))
        assertFalse(VodDownload.requested(mapOf("download" to "true")))
        assertFalse(VodDownload.requested(mapOf("download" to "0")))
    }

    @Test
    fun fileNameSanitizesAndAddsMp4() {
        assertEquals("recording.mp4", VodDownload.fileName(null))
        assertEquals("recording.mp4", VodDownload.fileName("  "))
        assertEquals("recording.mp4", VodDownload.fileName(".."))
        assertEquals("foobar.mp4", VodDownload.fileName("foo/bar.mp4"))
        assertEquals("婚礼.mp4", VodDownload.fileName("婚礼"))
        assertEquals("clip.mp4", VodDownload.fileName("clip.MP4"))
    }

    @Test
    fun contentDispositionHasAsciiFallbackAndRfc5987() {
        val header = VodDownload.contentDisposition("婚礼")
        assertTrue(header.startsWith("attachment;"))
        assertTrue(header.contains("filename=\"recording.mp4\""))
        assertTrue(header.contains("filename*=UTF-8''"))
        assertTrue(header.contains("%"))
    }
}
