package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class HlsWindowTest {
    @Test
    fun playlistContainsRequiredTags() {
        val window = HlsWindow()
        val playlist = window.playlist()
        assertTrue(playlist.contains("#EXTM3U"))
        assertTrue(playlist.contains("#EXT-X-TARGETDURATION"))
    }

    @Test
    fun emptyWindowPlaylistIsLegalWithoutEndList() {
        val window = HlsWindow()
        val playlist = window.playlist()
        assertTrue(playlist.contains("#EXTM3U"))
        assertTrue(playlist.contains("#EXT-X-TARGETDURATION"))
        assertTrue(playlist.contains("#EXT-X-INDEPENDENT-SEGMENTS"))
        assertFalse(playlist.contains("#EXT-X-ENDLIST"))
    }

    @Test
    fun appendThenSegmentReturnsData() {
        val window = HlsWindow()
        val ts = byteArrayOf(0x47)
        window.append(ts, 2.0)
        assertEquals(ts.toList(), window.segment("seg0.ts")?.toList())
    }

    @Test
    fun playlistListsAtLeastOneTsAfterAppend() {
        val window = HlsWindow()
        window.append(byteArrayOf(0x47), 2.0)
        val playlist = window.playlist(base = "/live/")
        assertTrue(playlist.contains(".ts"))
        assertTrue(playlist.contains("/live/seg0.ts"))
        assertEquals(1, window.segmentCount())
    }

    @Test
    fun keepsOnlyLastSixSegmentsAndMediaSequenceIncreases() {
        val window = HlsWindow(capacity = 6)
        repeat(8) { index ->
            window.append(byteArrayOf(index.toByte()), 2.0)
        }
        assertNull(window.segment("seg0.ts"))
        assertNull(window.segment("seg1.ts"))
        assertNotNull(window.segment("seg2.ts"))
        assertNotNull(window.segment("seg7.ts"))

        val playlist = window.playlist()
        assertTrue(playlist.contains("#EXT-X-MEDIA-SEQUENCE:2"))
        assertFalse(playlist.contains("seg0.ts"))
        assertFalse(playlist.contains("seg1.ts"))
        assertTrue(playlist.contains("seg2.ts"))
        assertTrue(playlist.contains("seg7.ts"))
    }

    @Test
    fun resetClearsWindow() {
        val window = HlsWindow()
        window.append(byteArrayOf(0x47), 2.0)
        window.reset()
        assertNull(window.segment("seg0.ts"))
        val playlist = window.playlist()
        assertTrue(playlist.contains("#EXTM3U"))
        assertFalse(playlist.contains("seg0.ts"))
    }
}
