package com.usbcamera.capture.usb_capture

internal object SalvagePolicy {
    const val MIN_BYTES = 32L * 1024
    const val MIN_DURATION_MS = 1_500L

    fun isPublishable(bytes: Long, durationMs: Long): Boolean {
        return bytes >= MIN_BYTES && durationMs >= MIN_DURATION_MS
    }
}
