package com.usbcamera.capture.usb_capture

internal object PreviewSurfacePolicy {
    data class AttachPlan(
        val bufferWidth: Int,
        val bufferHeight: Int,
        val releaseExisting: Boolean,
    )

    fun plan(
        existingSurface: Boolean,
        previewWidth: Int,
        previewHeight: Int,
    ): AttachPlan? {
        if (previewWidth <= 0 || previewHeight <= 0) return null
        return AttachPlan(
            bufferWidth = previewWidth,
            bufferHeight = previewHeight,
            releaseExisting = existingSurface,
        )
    }
}
