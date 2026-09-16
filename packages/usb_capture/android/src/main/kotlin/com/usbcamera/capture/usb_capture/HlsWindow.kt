package com.usbcamera.capture.usb_capture

import java.util.ArrayDeque

class HlsWindow(
    private val capacity: Int = 6,
    private val targetDurationSec: Int = 3,
) {
    private data class Segment(
        val index: Int,
        val data: ByteArray,
        val durationSec: Double,
    )

    private val segments = ArrayDeque<Segment>()
    private var nextIndex = 0

    @Synchronized
    fun append(ts: ByteArray, durationSec: Double) {
        segments.addLast(Segment(nextIndex++, ts.copyOf(), durationSec))
        while (segments.size > capacity) {
            segments.removeFirst()
        }
    }

    @Synchronized
    fun playlist(base: String = ""): String {
        val mediaSequence = segments.firstOrNull()?.index ?: nextIndex
        return buildString {
            appendLine("#EXTM3U")
            appendLine("#EXT-X-VERSION:3")
            appendLine("#EXT-X-INDEPENDENT-SEGMENTS")
            appendLine("#EXT-X-TARGETDURATION:$targetDurationSec")
            appendLine("#EXT-X-MEDIA-SEQUENCE:$mediaSequence")
            for (segment in segments) {
                appendLine("#EXTINF:${segment.durationSec},")
                appendLine("${base}seg${segment.index}.ts")
            }
        }.trimEnd()
    }

    @Synchronized
    fun segment(name: String): ByteArray? {
        val match = SEGMENT_NAME.matchEntire(name) ?: return null
        val index = match.groupValues[1].toInt()
        return segments.firstOrNull { it.index == index }?.data?.copyOf()
    }

    @Synchronized
    fun segmentCount(): Int = segments.size

    @Synchronized
    fun reset() {
        segments.clear()
        nextIndex = 0
    }

    private companion object {
        private val SEGMENT_NAME = Regex("""seg(\d+)\.ts""")
    }
}
