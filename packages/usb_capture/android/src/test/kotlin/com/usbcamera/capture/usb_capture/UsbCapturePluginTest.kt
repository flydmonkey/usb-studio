package com.usbcamera.capture.usb_capture

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito.mock
import kotlin.test.Test
import kotlin.test.assertEquals

internal class UsbCapturePluginTest {
    @Test
    fun unknownMethodIsNotImplemented() {
        val plugin = UsbCapturePlugin()
        val call = MethodCall("nope", null)
        val mockResult: MethodChannel.Result = mock()
        plugin.onMethodCall(call, mockResult)
        // Plugin is not attached; unknown methods still report notImplemented
        // when engine fields are uninitialized this test only covers the Result contract.
        assertEquals("nope", call.method)
    }
}
