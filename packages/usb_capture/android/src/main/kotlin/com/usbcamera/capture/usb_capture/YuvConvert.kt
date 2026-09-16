package com.usbcamera.capture.usb_capture

import java.nio.ByteBuffer

internal object YuvConvert {
    data class Plane(
        val rowStride: Int,
        val pixelStride: Int,
        val buffer: ByteBuffer,
    )

    fun packedSize(width: Int, height: Int): Int = width * height * 3 / 2

    fun nv21ToNv12(nv21: ByteArray, width: Int, height: Int): ByteArray {
        val ySize = width * height
        val out = nv21.copyOf()
        var index = ySize
        while (index + 1 < nv21.size) {
            out[index] = nv21[index + 1]
            out[index + 1] = nv21[index]
            index += 2
        }
        return out
    }

    fun fillYuv420FromNv21(
        nv21: ByteArray,
        width: Int,
        height: Int,
        y: Plane,
        u: Plane,
        v: Plane,
    ) {
        fillY(nv21, width, height, y)
        fillUv(nv21, width, height, u, v)
    }

    private fun fillY(nv21: ByteArray, width: Int, height: Int, y: Plane) {
        val yBase = y.buffer.position()
        if (y.pixelStride == 1) {
            val dest = y.buffer.duplicate()
            for (row in 0 until height) {
                dest.position(yBase + row * y.rowStride)
                dest.put(nv21, row * width, width)
            }
            return
        }
        for (row in 0 until height) {
            val srcRow = row * width
            val dstRow = row * y.rowStride
            for (col in 0 until width) {
                y.buffer.put(yBase + dstRow + col * y.pixelStride, nv21[srcRow + col])
            }
        }
    }

    private fun fillUv(
        nv21: ByteArray,
        width: Int,
        height: Int,
        u: Plane,
        v: Plane,
    ) {
        val uBase = u.buffer.position()
        val vBase = v.buffer.position()
        val chromaWidth = width / 2
        val chromaHeight = height / 2
        var chromaIndex = width * height
        val nv12Overlapped = u.pixelStride == 2 &&
            v.pixelStride == 2 &&
            kotlin.math.abs(vBase - uBase) == 1
        if (nv12Overlapped) {
            val dest = if (uBase < vBase) u.buffer.duplicate() else v.buffer.duplicate()
            val destBase = minOf(uBase, vBase)
            val rowStride = if (uBase < vBase) u.rowStride else v.rowStride
            val row = ByteArray(chromaWidth * 2)
            for (rowIndex in 0 until chromaHeight) {
                var offset = 0
                repeat(chromaWidth) {
                    val chromaV = nv21[chromaIndex]
                    val chromaU = nv21[chromaIndex + 1]
                    chromaIndex += 2
                    row[offset++] = chromaU
                    row[offset++] = chromaV
                }
                dest.position(destBase + rowIndex * rowStride)
                dest.put(row)
            }
            return
        }
        for (row in 0 until chromaHeight) {
            for (col in 0 until chromaWidth) {
                val chromaV = nv21[chromaIndex]
                val chromaU = nv21[chromaIndex + 1]
                chromaIndex += 2
                u.buffer.put(uBase + row * u.rowStride + col * u.pixelStride, chromaU)
                v.buffer.put(vBase + row * v.rowStride + col * v.pixelStride, chromaV)
            }
        }
    }
}
