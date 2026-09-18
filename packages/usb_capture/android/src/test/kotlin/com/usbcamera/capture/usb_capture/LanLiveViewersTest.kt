package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class LanLiveViewersTest {
    @Test
    fun addRemoveAndNeverNegative() {
        val viewers = LanLiveViewers()
        assertEquals(1, viewers.add())
        assertEquals(2, viewers.add())
        assertEquals(1, viewers.remove())
        assertEquals(0, viewers.remove())
        assertEquals(0, viewers.remove())
        assertEquals(0, viewers.count())
    }

    @Test
    fun trackWatchdogClosesIdleStreamAndUntracks() {
        val viewers = LanLiveViewers()
        val hub = MjpegHub()
        var n = 0
        lateinit var stream: MjpegMultipartStream
        stream = MjpegMultipartStream(
            hub,
            onClosed = {
                n++
                viewers.untrack(stream)
            },
            idleMs = 40L,
        )
        viewers.track(stream)
        assertEquals(1, viewers.trackedCount())
        Thread.sleep(60)
        viewers.pruneStaleStreams()
        assertEquals(1, n)
        assertEquals(0, viewers.trackedCount())
        stream.close()
        assertEquals(1, n)
    }

    @Test
    fun closeAllTrackedClosesStreamsAndClearsSet() {
        val viewers = LanLiveViewers()
        val hub = MjpegHub()
        var n = 0
        lateinit var stream: MjpegMultipartStream
        stream = MjpegMultipartStream(
            hub,
            onClosed = {
                n++
                viewers.untrack(stream)
                viewers.remove()
            },
        )
        viewers.add()
        viewers.track(stream)
        assertEquals(1, viewers.trackedCount())
        viewers.closeAllTracked()
        assertEquals(1, n)
        assertEquals(0, viewers.trackedCount())
        viewers.add()
        stream.close()
        assertEquals(1, n)
        assertEquals(1, viewers.count())
    }
}
