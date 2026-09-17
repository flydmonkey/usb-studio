package com.usbcamera.capture.usb_capture

import java.net.URLEncoder

internal object VodDownload {
    fun requested(parms: Map<String, String>?): Boolean {
        return parms?.get("download")?.trim() == "1"
    }

    fun fileName(displayName: String?): String {
        var name = (displayName ?: "")
            .replace("/", "")
            .replace("\\", "")
            .replace("\u0000", "")
            .trim()
            .trim('.')
        if (name.isEmpty()) return "recording.mp4"
        if (!name.endsWith(".mp4", ignoreCase = true)) {
            name += ".mp4"
        } else if (!name.endsWith(".mp4")) {
            name = name.dropLast(4) + ".mp4"
        }
        return name
    }

    fun contentDisposition(displayName: String?): String {
        val encoded = URLEncoder.encode(fileName(displayName), Charsets.UTF_8.name())
            .replace("+", "%20")
        return "attachment; filename=\"recording.mp4\"; filename*=UTF-8''$encoded"
    }
}
