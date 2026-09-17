package com.usbcamera.capture.usb_capture

internal object CaptureRuntimePolicy {
    fun shouldRelease(
        recording: Boolean,
        streaming: Boolean,
        httpServing: Boolean,
        sessionOpen: Boolean,
    ): Boolean = !recording && !streaming && !httpServing && !sessionOpen

    /**
     * Rejects setFormat while recording, RTMP ingest, or LAN MJPEG is publishing.
     * HTTP server up with zero viewers must not lock. Null means format may change.
     */
    fun formatLock(
        recording: Boolean,
        streaming: Boolean,
        lanLiveBusy: Boolean,
    ): Pair<String, String>? {
        if (!recording && !streaming && !lanLiveBusy) return null
        return if ((streaming || lanLiveBusy) && !recording) {
            "streamFailed" to "streamInProgress"
        } else {
            "recordingFailed" to "recordingInProgress"
        }
    }
}
