package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class LanLiveStatusTest {
    @Test
    fun hasCardWhenDeviceIdIsOpen() {
        assertTrue(LanLiveStatus.hasCard("1:2"))
        assertTrue(LanLiveStatus.hasCard(null, gotPreview = true))
        assertFalse(LanLiveStatus.hasCard(null))
        assertFalse(LanLiveStatus.hasCard(""))
    }
}
