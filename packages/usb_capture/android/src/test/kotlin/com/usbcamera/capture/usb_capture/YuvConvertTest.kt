package com.usbcamera.capture.usb_capture

import java.nio.ByteBuffer
import kotlin.test.Test
import kotlin.test.assertEquals

internal class YuvConvertTest {
    @Test
    fun nv21ToNv12SwapsChromaPairs() {
        val nv21 = byteArrayOf(
            1, 2, 3, 4,
            9, 8,
        )
        val nv12 = YuvConvert.nv21ToNv12(nv21, width = 2, height = 2)
        assertEquals(listOf<Byte>(1, 2, 3, 4, 8, 9), nv12.toList())
    }

    @Test
    fun fillSemiPlanarPlanesWritesNv12Chroma() {
        val nv21 = byteArrayOf(
            10, 11, 12, 13,
            21, 20,
        )
        val y = ByteBuffer.allocate(4)
        val u = ByteBuffer.allocate(2)
        val v = ByteBuffer.allocate(2)
        YuvConvert.fillYuv420FromNv21(
            nv21 = nv21,
            width = 2,
            height = 2,
            y = YuvConvert.Plane(rowStride = 2, pixelStride = 1, buffer = y),
            u = YuvConvert.Plane(rowStride = 2, pixelStride = 2, buffer = u),
            v = YuvConvert.Plane(rowStride = 2, pixelStride = 2, buffer = v),
        )
        assertEquals(listOf<Byte>(10, 11, 12, 13), y.array().toList())
        assertEquals(20.toByte(), u.get(0))
        assertEquals(21.toByte(), v.get(0))
    }

    @Test
    fun fillYPlaneUsesRowStridePadding() {
        val nv21 = byteArrayOf(
            1, 2, 3, 4,
            5, 6, 7, 8,
            0, 0, 0, 0,
        )
        val y = ByteBuffer.allocate(12)
        val u = ByteBuffer.allocate(2)
        val v = ByteBuffer.allocate(2)
        YuvConvert.fillYuv420FromNv21(
            nv21 = nv21,
            width = 4,
            height = 2,
            y = YuvConvert.Plane(rowStride = 6, pixelStride = 1, buffer = y),
            u = YuvConvert.Plane(rowStride = 2, pixelStride = 1, buffer = u),
            v = YuvConvert.Plane(rowStride = 2, pixelStride = 1, buffer = v),
        )
        assertEquals(1.toByte(), y.get(0))
        assertEquals(4.toByte(), y.get(3))
        assertEquals(5.toByte(), y.get(6))
        assertEquals(8.toByte(), y.get(9))
    }
}
