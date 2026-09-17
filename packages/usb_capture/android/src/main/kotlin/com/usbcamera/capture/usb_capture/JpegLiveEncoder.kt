package com.usbcamera.capture.usb_capture

import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.view.TextureView
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

internal class JpegLiveEncoder(
    private val hub: MjpegHub,
    private val previewView: () -> TextureView?,
    private val quality: Int = 90,
) {
    private val lock = Object()
    private var latest: ByteArray? = null
    private var generation = 0L
    private var width = 0
    private var height = 0
    private var running = false
    private var worker: Thread? = null
    val offered = AtomicLong(0)
    val published = AtomicLong(0)
    val lastError = AtomicReference("")
    val lastJpegWidth = AtomicInteger(0)
    val lastJpegHeight = AtomicInteger(0)

    fun setSize(width: Int, height: Int) {
        synchronized(lock) {
            if (width > 0 && height > 0) {
                this.width = width
                this.height = height
            }
        }
    }

    fun start() {
        synchronized(lock) {
            if (running) return
            running = true
            worker = Thread({ loop() }, "lan-jpeg").apply {
                isDaemon = true
                start()
            }
        }
    }

    fun stop() {
        val thread: Thread?
        synchronized(lock) {
            running = false
            latest = null
            generation += 1
            lock.notifyAll()
            thread = worker
            worker = null
        }
        thread?.join(400)
        hub.clear()
    }

    fun kick() {
        synchronized(lock) {
            if (!running) return
            generation += 1
            lock.notifyAll()
        }
    }

    fun offerFrame(frame: ByteArray) {
        if (frame.isEmpty()) return
        offered.incrementAndGet()
        val jpeg = MjpegJpeg.extract(frame)
        if (jpeg != null) {
            hub.publish(jpeg)
            published.incrementAndGet()
            lastError.set("")
            return
        }
        synchronized(lock) {
            if (!running) return
            latest = frame
            generation += 1
            lock.notifyAll()
        }
    }

    fun snapshot(): Map<String, Any?> {
        val size = synchronized(lock) { width to height }
        return mapOf(
            "running" to synchronized(lock) { running },
            "width" to size.first,
            "height" to size.second,
            "jpegWidth" to lastJpegWidth.get(),
            "jpegHeight" to lastJpegHeight.get(),
            "offered" to offered.get(),
            "published" to published.get(),
            "error" to lastError.get(),
        )
    }

    private fun loop() {
        var seen = 0L
        val out = ByteArrayOutputStream()
        while (true) {
            synchronized(lock) {
                while (running && generation <= seen) {
                    try {
                        lock.wait()
                    } catch (_: InterruptedException) {
                        Thread.currentThread().interrupt()
                        return
                    }
                }
                if (!running) return
                seen = generation
            }
            if (publishFromCapture(out)) continue
            publishFromView(out)
        }
    }

    private fun publishFromCapture(out: ByteArrayOutputStream): Boolean {
        val frame: ByteArray
        var w: Int
        var h: Int
        synchronized(lock) {
            frame = latest ?: return false
            w = width
            h = height
        }
        if (w <= 0 || h <= 0) {
            val inferred = JpegFrameFormat.inferSize(frame.size)
            if (inferred == null) {
                lastError.set("size 0")
                return false
            }
            w = inferred.first
            h = inferred.second
            synchronized(lock) {
                if (width <= 0 || height <= 0) {
                    width = w
                    height = h
                }
            }
        }
        return when (JpegFrameFormat.kind(frame.size, w, h)) {
            JpegFrameFormat.Kind.Rgbx -> publishRgbx(frame, w, h, out)
            JpegFrameFormat.Kind.Nv21 -> publishNv21(frame, w, h, out)
            else -> {
                lastError.set("frame ${frame.size} for ${w}x$h")
                false
            }
        }
    }

    private fun publishNv21(nv21: ByteArray, w: Int, h: Int, out: ByteArrayOutputStream): Boolean {
        out.reset()
        val ok = try {
            YuvImage(nv21, ImageFormat.NV21, w, h, null)
                .compressToJpeg(Rect(0, 0, w, h), quality, out)
        } catch (error: Exception) {
            lastError.set(error.message ?: "yuv")
            false
        }
        return publishJpeg(out, ok, w, h)
    }

    private fun publishRgbx(rgbx: ByteArray, w: Int, h: Int, out: ByteArrayOutputStream): Boolean {
        val needed = w * h * 4
        if (rgbx.size < needed) return false
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        return try {
            bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(rgbx, 0, needed))
            out.reset()
            val ok = bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
            publishJpeg(out, ok, w, h)
        } catch (error: Exception) {
            lastError.set(error.message ?: "rgbx")
            false
        } finally {
            bitmap.recycle()
        }
    }

    private fun publishFromView(out: ByteArrayOutputStream): Boolean {
        val view = previewView() ?: return false
        val bitmap = try {
            view.getBitmap()
        } catch (error: Exception) {
            lastError.set(error.message ?: "bitmap")
            return false
        } ?: return false
        val w = bitmap.width
        val h = bitmap.height
        out.reset()
        val ok = try {
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
        } catch (error: Exception) {
            lastError.set(error.message ?: "compress")
            false
        } finally {
            bitmap.recycle()
        }
        return publishJpeg(out, ok, w, h)
    }

    private fun publishJpeg(out: ByteArrayOutputStream, ok: Boolean, w: Int, h: Int): Boolean {
        if (!ok || out.size() <= 2) return false
        hub.publish(out.toByteArray())
        published.incrementAndGet()
        lastJpegWidth.set(w)
        lastJpegHeight.set(h)
        lastError.set("")
        return true
    }
}
