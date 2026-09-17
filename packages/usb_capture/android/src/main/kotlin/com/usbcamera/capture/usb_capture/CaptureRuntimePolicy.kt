package com.usbcamera.capture.usb_capture

internal object CaptureRuntimePolicy {
    fun shouldRelease(
        recording: Boolean,
        streaming: Boolean,
        httpServing: Boolean,
        sessionOpen: Boolean,
    ): Boolean = !recording && !streaming && !httpServing && !sessionOpen
}
