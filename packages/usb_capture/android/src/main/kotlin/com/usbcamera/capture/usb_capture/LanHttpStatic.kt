package com.usbcamera.capture.usb_capture

internal object LanHttpStatic {
    data class File(val asset: String, val mime: String)

    fun fileFor(path: String): File? =
        when (path) {
            "/favicon.ico", "/favicon.png" ->
                File("lan_http/favicon.png", "image/png")
            else -> null
        }
}
