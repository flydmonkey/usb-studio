package com.usbcamera.capture.usb_capture

internal object LanLiveStatus {
    fun hasCard(openedDeviceId: String?, gotPreview: Boolean = false): Boolean {
        return !openedDeviceId.isNullOrEmpty() || gotPreview
    }
}
