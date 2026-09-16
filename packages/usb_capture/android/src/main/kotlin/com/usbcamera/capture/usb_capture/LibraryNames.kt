package com.usbcamera.capture.usb_capture

internal object LibraryNames {
    private val illegal = Regex("[\\\\/:*?\"<>|\\u0000-\\u001F]")

    fun normalize(raw: String): String? {
        val trimmed = raw.trim()
        if (trimmed.isEmpty() || trimmed == "." || trimmed == "..") {
            return null
        }
        if (illegal.containsMatchIn(trimmed)) {
            return null
        }
        val stem = if (trimmed.endsWith(".mp4", ignoreCase = true)) {
            trimmed.substring(0, trimmed.length - 4)
        } else {
            trimmed
        }
        if (stem.trim().isEmpty() || illegal.containsMatchIn(stem)) {
            return null
        }
        return "$stem.mp4"
    }

    fun same(left: String, right: String): Boolean {
        return left.equals(right, ignoreCase = true)
    }

    fun taken(names: Iterable<String>, current: String, next: String): Boolean {
        return names.any { name -> !same(name, current) && same(name, next) }
    }
}
