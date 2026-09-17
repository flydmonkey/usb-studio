package com.usbcamera.capture.usb_capture

class MjpegHub {
    private val lock = Object()
    private var latest: ByteArray? = null
    private var generation = 0L
    private var open = true

    fun publish(frame: ByteArray) {
        val jpeg = MjpegJpeg.extract(frame) ?: return
        synchronized(lock) {
            if (!open) return
            latest = jpeg
            generation += 1
            lock.notifyAll()
        }
    }

    fun awaitNext(afterGeneration: Long, timeoutMs: Long): Pair<Long, ByteArray>? {
        val deadline = System.currentTimeMillis() + timeoutMs.coerceAtLeast(0L)
        synchronized(lock) {
            while (open) {
                val frame = latest
                if (frame != null && generation > afterGeneration) {
                    return generation to frame
                }
                val waitMs = deadline - System.currentTimeMillis()
                if (waitMs <= 0L) return null
                try {
                    lock.wait(waitMs)
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return null
                }
            }
            return null
        }
    }

    fun hasFrame(): Boolean = synchronized(lock) { open && latest != null }

    fun isOpen(): Boolean = synchronized(lock) { open }

    fun clear() {
        synchronized(lock) {
            latest = null
            generation += 1
            lock.notifyAll()
        }
    }

    fun close() {
        synchronized(lock) {
            open = false
            latest = null
            lock.notifyAll()
        }
    }

    fun reopen() {
        synchronized(lock) {
            open = true
            latest = null
            generation += 1
            lock.notifyAll()
        }
    }
}
