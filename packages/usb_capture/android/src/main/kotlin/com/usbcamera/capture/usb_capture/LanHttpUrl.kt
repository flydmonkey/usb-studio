package com.usbcamera.capture.usb_capture

internal object LanHttpUrl {
    fun display(ipv4: String, port: Int): String {
        return "http://$ipv4:$port/"
    }

    fun pickIpv4(addresses: Iterable<String>): String? {
        for (raw in addresses) {
            val host = raw.trim()
            if (host.isEmpty() || host == "127.0.0.1" || host == "0.0.0.0") continue
            if (host.contains(':')) continue
            val parts = host.split('.')
            if (parts.size != 4) continue
            if (parts.all { it.toIntOrNull() != null }) return host
        }
        return null
    }
}
