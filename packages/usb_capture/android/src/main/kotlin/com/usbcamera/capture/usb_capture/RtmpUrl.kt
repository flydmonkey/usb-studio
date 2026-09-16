package com.usbcamera.capture.usb_capture

internal object RtmpUrl {
    fun join(server: String, key: String): String? {
        val host = server.trim()
        val streamKey = key.trim()
        if (host.isEmpty()) return null
        val scheme = host.lowercase()
        if (!scheme.startsWith("rtmp://") && !scheme.startsWith("rtmps://")) {
            return null
        }
        if (streamKey.isEmpty()) {
            return if (hasAppPath(host)) host else null
        }
        if (streamKey.startsWith("?")) {
            return host + streamKey
        }
        return host.trimEnd('/') + "/" + streamKey
    }

    fun validate(url: String): String? {
        val trimmed = url.trim()
        val scheme = trimmed.lowercase()
        if (!scheme.startsWith("rtmp://") && !scheme.startsWith("rtmps://")) {
            return null
        }
        val rest = trimmed.substringAfter("://")
        if (!rest.contains('/')) return null
        return trimmed
    }

    private fun hasAppPath(host: String): Boolean {
        return host.substringAfter("://").contains('/')
    }
}
