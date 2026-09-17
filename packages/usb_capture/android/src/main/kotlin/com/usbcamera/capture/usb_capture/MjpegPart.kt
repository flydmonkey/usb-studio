package com.usbcamera.capture.usb_capture

import java.io.InputStream
import java.util.concurrent.atomic.AtomicBoolean

object MjpegPart {
    const val BOUNDARY = "usbframe"

    fun encode(boundary: String, jpeg: ByteArray): ByteArray {
        val header = "--$boundary\r\n" +
            "Content-Type: image/jpeg\r\n" +
            "Content-Length: ${jpeg.size}\r\n" +
            "\r\n"
        val headerBytes = header.toByteArray(Charsets.US_ASCII)
        val out = ByteArray(headerBytes.size + jpeg.size + 2)
        System.arraycopy(headerBytes, 0, out, 0, headerBytes.size)
        System.arraycopy(jpeg, 0, out, headerBytes.size, jpeg.size)
        out[out.size - 2] = '\r'.code.toByte()
        out[out.size - 1] = '\n'.code.toByte()
        return out
    }
}

class MjpegMultipartStream(
    private val hub: MjpegHub,
    private val onClosed: () -> Unit = {},
    private val idleMs: Long = 30_000L,
    private val boundary: String = MjpegPart.BOUNDARY,
) : InputStream() {
    private val closed = AtomicBoolean(false)
    private var lastGeneration = 0L
    private var buffer = ByteArray(0)
    private var offset = 0

    @Volatile
    var touchedAtMs: Long = System.currentTimeMillis()
        private set

    internal fun idleTimeoutMs(): Long = idleMs

    override fun read(): Int {
        val one = ByteArray(1)
        val n = read(one, 0, 1)
        return if (n <= 0) -1 else one[0].toInt() and 0xFF
    }

    override fun read(b: ByteArray, off: Int, len: Int): Int {
        if (closed.get()) return -1
        if (len <= 0) return 0

        val now = System.currentTimeMillis()
        if (now - touchedAtMs > idleMs) {
            close()
            return -1
        }
        touchedAtMs = now

        while (offset >= buffer.size) {
            if (closed.get()) return -1
            if (!hub.isOpen()) {
                close()
                return -1
            }
            touchedAtMs = System.currentTimeMillis()
            val next = hub.awaitNext(lastGeneration, 15_000L) ?: continue
            lastGeneration = next.first
            buffer = MjpegPart.encode(boundary, next.second)
            offset = 0
        }
        val n = minOf(len, buffer.size - offset)
        System.arraycopy(buffer, offset, b, off, n)
        offset += n
        return n
    }

    override fun close() {
        if (closed.compareAndSet(false, true)) {
            onClosed()
        }
        super.close()
    }
}
