package com.usbcamera.capture.usb_capture

import android.content.Context
import android.graphics.SurfaceTexture
import android.view.TextureView
import android.view.View
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PreviewViewFactory(
    private val engineProvider: () -> CaptureEngine?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return PreviewPlatformView(context, engineProvider)
    }
}

private class PreviewPlatformView(
    context: Context,
    private val engineProvider: () -> CaptureEngine?,
) : PlatformView {
    private val textureView = TextureView(context).apply {
        isFocusable = false
        isFocusableInTouchMode = false
        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
    }

    init {
        textureView.surfaceTextureListener =
            object : TextureView.SurfaceTextureListener {
                override fun onSurfaceTextureAvailable(
                    surface: SurfaceTexture,
                    width: Int,
                    height: Int,
                ) {
                    engineProvider()?.attachPreview(textureView)
                }

                override fun onSurfaceTextureSizeChanged(
                    surface: SurfaceTexture,
                    width: Int,
                    height: Int,
                ) {}

                override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
                    engineProvider()?.detachPreview()
                    return true
                }

                override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
                    engineProvider()?.onPreviewFrame()
                }
            }
        if (textureView.isAvailable) {
            engineProvider()?.attachPreview(textureView)
        }
    }

    override fun getView(): View = textureView

    override fun dispose() {
        engineProvider()?.detachPreview()
    }
}
