package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class RtmpUrlTest {
    @Test
    fun joinsServerAndKeyWithASingleSlash() {
        assertEquals(
            "rtmp://live.example/live/streamkey",
            RtmpUrl.join("rtmp://live.example/live/", "streamkey"),
        )
    }

    @Test
    fun concatenatesQueryStyleKeys() {
        assertEquals(
            "rtmp://live.example/live?secret=1",
            RtmpUrl.join("rtmp://live.example/live", "?secret=1"),
        )
    }

    @Test
    fun rejectsEmptyOrNonRtmp() {
        assertNull(RtmpUrl.join("", "key"))
        assertNull(RtmpUrl.join("https://live.example/live", "key"))
        assertNull(RtmpUrl.validate("rtmp://onlyhost"))
        assertEquals(
            "rtmp://live.example/live",
            RtmpUrl.join("rtmp://live.example/live", " "),
        )
        assertEquals(
            "rtmp://live.example/live/stream",
            RtmpUrl.join("rtmp://live.example/live/stream", ""),
        )
        assertNull(RtmpUrl.join("rtmp://live.example", ""))
    }
}
