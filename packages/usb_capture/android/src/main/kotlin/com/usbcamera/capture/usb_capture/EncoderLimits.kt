package com.usbcamera.capture.usb_capture

internal object EncoderLimits {
    fun videoFps(previewFps: Int): Int {
        return previewFps.coerceIn(5, 30)
    }

    fun scaledBitrate(base: Int, width: Int, height: Int): Int {
        val scale = (width * height).toDouble() / (1920.0 * 1080.0)
        return (base * scale.coerceIn(0.25, 2.0)).toInt()
    }

    fun parseStreamBitrate(raw: String?): String {
        return when (raw) {
            "mbps1", "mbps4", "mbps6" -> raw
            else -> "mbps2"
        }
    }

    fun streamBaseBitrate(preset: String): Int {
        return when (preset) {
            "mbps1" -> 1_000_000
            "mbps4" -> 4_000_000
            "mbps6" -> 6_000_000
            else -> 2_000_000
        }
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
