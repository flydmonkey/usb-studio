package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class LanHttpUrlTest {
    @Test
    fun buildsDisplayUrl() {
        assertEquals(
            "http://192.168.1.8:8080/",
            LanHttpUrl.display("192.168.1.8", 8080),
        )
    }

    @Test
    fun picksFirstNonLoopbackIpv4() {
        assertEquals(
            "192.168.1.8",
            LanHttpUrl.pickIpv4(listOf("127.0.0.1", "192.168.1.8", "::1")),
        )
    }

    @Test
    fun returnsNullWhenOnlyLoopback() {
        assertNull(LanHttpUrl.pickIpv4(listOf("127.0.0.1")))
    }
}
