package com.usbcamera.capture.usb_capture

internal object JpegFrameFormat {
    enum class Kind { Rgbx, Nv21, Unknown }

    fun kind(bytes: Int, width: Int, height: Int): Kind {
        if (width <= 0 || height <= 0 || bytes <= 0) return Kind.Unknown
        val pixels = width * height
        if (bytes >= pixels * 4) return Kind.Rgbx
        if (bytes >= pixels * 3 / 2) return Kind.Nv21
        return Kind.Unknown
    }

    fun inferSize(bytes: Int): Pair<Int, Int>? {
        if (bytes <= 0) return null
        val common = listOf(
            1920 to 1080,
            1280 to 720,
            640 to 480,
            2560 to 1440,
            3840 to 2160,
        )
        for ((w, h) in common) {
            val pixels = w * h
            if (bytes == pixels * 4 || bytes == pixels * 3 / 2) return w to h
        }
        return null
    }
}
