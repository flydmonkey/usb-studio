package com.usbcamera.capture.usb_capture

data class HttpRange(val start: Long, val end: Long) {
    val length: Long
        get() = end - start + 1

    companion object {
        fun parse(header: String?, total: Long): HttpRange? {
            if (header.isNullOrBlank() || total <= 0L) return null
            val trimmed = header.trim()
            if (!trimmed.startsWith("bytes=", ignoreCase = true)) return null
            val spec = trimmed.substring(6).trim()
            if (spec.contains(',')) return null
            val dash = spec.indexOf('-')
            if (dash < 0) return null
            val startText = spec.substring(0, dash).trim()
            val endText = spec.substring(dash + 1).trim()
            val start: Long
            val end: Long
            when {
                startText.isEmpty() -> return null
                endText.isEmpty() -> {
                    start = startText.toLongOrNull() ?: return null
                    end = total - 1
                }
                else -> {
                    start = startText.toLongOrNull() ?: return null
                    end = endText.toLongOrNull() ?: return null
                }
            }
            if (start < 0 || end < start) return null
            val clampedStart = start.coerceIn(0, total - 1)
            val clampedEnd = end.coerceIn(clampedStart, total - 1)
            return HttpRange(clampedStart, clampedEnd)
        }
    }
}
