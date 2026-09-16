package com.usbcamera.capture.usb_capture

internal object EncoderLimits {
    fun videoFps(previewFps: Int): Int {
        return previewFps.coerceIn(5, 30)
    }

    fun hlsBitrate(requested: Int): Int {
        return requested.coerceAtMost(4_000_000).coerceAtLeast(500_000)
    }

    fun isLiveEncodeFailure(message: String?): Boolean {
        if (message.isNullOrBlank()) return false
        val lower = message.lowercase()
        return lower.contains("fffffff4") ||
            lower.contains("no_memory") ||
            lower.contains("insufficient")
    }

    fun liveFailureDetails(message: String?): String {
        return if (isLiveEncodeFailure(message)) "httpLiveFailed" else (message ?: "httpLiveFailed")
    }

    fun hlsSegmentDuration(seconds: Double): Double {
        return seconds.coerceIn(0.4, 2.5)
    }
}
