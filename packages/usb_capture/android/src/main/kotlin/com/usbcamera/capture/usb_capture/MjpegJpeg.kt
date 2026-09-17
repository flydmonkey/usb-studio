package com.usbcamera.capture.usb_capture

internal object MjpegJpeg {
    fun hasSoi(bytes: ByteArray): Boolean = soiIndex(bytes) >= 0

    fun extract(bytes: ByteArray): ByteArray? {
        val start = soiIndex(bytes)
        if (start < 0) return null
        return if (start == 0) bytes else bytes.copyOfRange(start, bytes.size)
    }

    private fun soiIndex(bytes: ByteArray): Int {
        if (bytes.size < 2) return -1
        val limit = minOf(bytes.size - 1, 64)
        for (i in 0 until limit) {
            if (bytes[i] == 0xFF.toByte() && bytes[i + 1] == 0xD8.toByte()) {
                return i
            }
        }
        return -1
    }
}
