package com.usbcamera.capture.usb_capture

internal object RtmpUrl {
    fun join(server: String, key: String): String? {
        var host = server.trim()
        var streamKey = key.trim()
        if (host.isEmpty() && isRtmp(streamKey)) {
            host = streamKey
            streamKey = ""
        }
        if (host.isEmpty() || !isRtmp(host)) return null
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

    private fun isRtmp(value: String): Boolean {
        val scheme = value.lowercase()
        return scheme.startsWith("rtmp://") || scheme.startsWith("rtmps://")
    }

    private fun hasAppPath(host: String): Boolean {
        return host.substringAfter("://").contains('/')
    }
}
