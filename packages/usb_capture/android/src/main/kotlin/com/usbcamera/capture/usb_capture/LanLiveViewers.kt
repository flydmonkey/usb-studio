package com.usbcamera.capture.usb_capture

import java.lang.ref.WeakReference
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

internal class LanLiveViewers {
    private val n = AtomicInteger(0)
    private val streams = mutableSetOf<WeakReference<MjpegMultipartStream>>()
    private val lock = Any()
    private val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "LanLiveViewers-watchdog").apply { isDaemon = true }
    }
    private var watchdog: ScheduledFuture<*>? = null

    fun add(): Int = n.incrementAndGet()

    fun remove(): Int {
        while (true) {
            val cur = n.get()
            if (cur <= 0) return 0
            if (n.compareAndSet(cur, cur - 1)) return cur - 1
        }
    }

    fun count(): Int = n.get()

    fun active(streaming: Boolean, mjpeg: Boolean): Boolean =
        count() > 0 && !streaming && mjpeg

    fun track(stream: MjpegMultipartStream) {
        synchronized(lock) {
            streams.add(WeakReference(stream))
            ensureWatchdogLocked()
        }
    }

    fun untrack(stream: MjpegMultipartStream) {
        synchronized(lock) {
            streams.removeAll { it.get() === stream || it.get() == null }
        }
    }

    internal fun trackedCount(): Int = synchronized(lock) {
        streams.count { it.get() != null }
    }

    private fun ensureWatchdogLocked() {
        if (watchdog?.isDone == false) return
        watchdog = scheduler.scheduleAtFixedRate(
            { pruneStaleStreams() },
            5L,
            5L,
            TimeUnit.SECONDS,
        )
    }

    internal fun closeAllTracked() {
        val toClose = mutableListOf<MjpegMultipartStream>()
        synchronized(lock) {
            for (ref in streams) {
                ref.get()?.let { toClose.add(it) }
            }
            streams.clear()
        }
        for (stream in toClose) {
            stream.close()
        }
    }

    internal fun pruneStaleStreams() {
        val now = System.currentTimeMillis()
        val stale = mutableListOf<MjpegMultipartStream>()
        synchronized(lock) {
            val iter = streams.iterator()
            while (iter.hasNext()) {
                val stream = iter.next().get()
                if (stream == null) {
                    iter.remove()
                } else if (now - stream.touchedAtMs > stream.idleTimeoutMs()) {
                    stale.add(stream)
                    iter.remove()
                }
            }
        }
        for (stream in stale) {
            stream.close()
        }
    }
}
