package com.usbcamera.capture.usb_capture

/**
 * Minimal MPEG-TS muxer for H.264 (Annex-B) + AAC (ADTS) into 188-byte packets.
 */
class MpegTsMuxer {
    private data class VideoAu(
        val data: ByteArray,
        val ptsUs: Long,
        val keyframe: Boolean,
    )

    private data class AudioAu(
        val data: ByteArray,
        val ptsUs: Long,
    )

    private val videoAus = mutableListOf<VideoAu>()
    private val audioAus = mutableListOf<AudioAu>()
    private val continuityCounters = IntArray(4)

    fun addVideoAccessUnit(nal: ByteArray, ptsUs: Long, keyframe: Boolean) {
        val data = if (hasAnnexBStartCode(nal)) {
            nal.copyOf()
        } else {
            byteArrayOf(0x00, 0x00, 0x00, 0x01) + nal
        }
        videoAus.add(VideoAu(data, ptsUs, keyframe))
    }

    fun addAudioAccessUnit(aacWithAdts: ByteArray, ptsUs: Long) {
        audioAus.add(AudioAu(aacWithAdts.copyOf(), ptsUs))
    }

    fun flushSegment(): ByteArray {
        if (videoAus.isEmpty() && audioAus.isEmpty()) {
            return ByteArray(0)
        }

        val includeAudio = audioAus.isNotEmpty()
        val output = ArrayList<ByteArray>()
        output.add(buildPatPacket())
        output.add(buildPmtPacket(includeAudio))

        for (au in videoAus) {
            val pes = buildPesPayload(STREAM_ID_VIDEO, au.data, au.ptsUs)
            val pcr = if (au.keyframe) ptsTo90kHz(au.ptsUs) else null
            output.addAll(packetize(PID_VIDEO, pes, pcr))
        }
        for (au in audioAus) {
            val pes = buildPesPayload(STREAM_ID_AUDIO, au.data, au.ptsUs)
            output.addAll(packetize(PID_AUDIO, pes, null))
        }

        videoAus.clear()
        audioAus.clear()

        val total = output.sumOf { it.size }
        val segment = ByteArray(total)
        var offset = 0
        for (packet in output) {
            System.arraycopy(packet, 0, segment, offset, packet.size)
            offset += packet.size
        }
        return segment
    }

    private fun buildPatPacket(): ByteArray {
        val section = buildPatSection()
        return buildSectionPacket(PID_PAT, section, patCounterIndex())
    }

    private fun buildPmtPacket(includeAudio: Boolean): ByteArray {
        val section = buildPmtSection(includeAudio)
        return buildSectionPacket(PID_PMT, section, pmtCounterIndex())
    }

    private fun buildPatSection(): ByteArray {
        val body = ByteArray(16)
        var i = 0
        body[i++] = 0x00 // table_id
        body[i++] = 0xB0.toByte()
        body[i++] = 0x0D
        body[i++] = 0x00
        body[i++] = 0x01
        body[i++] = 0xC1.toByte()
        body[i++] = 0x00
        body[i++] = 0x00
        body[i++] = 0x00
        body[i++] = 0x01
        i = writeSectionPid(body, i, PID_PMT)
        val crc = mpegCrc32(body, 0, i)
        body[i++] = ((crc shr 24) and 0xFF).toByte()
        body[i++] = ((crc shr 16) and 0xFF).toByte()
        body[i++] = ((crc shr 8) and 0xFF).toByte()
        body[i] = (crc and 0xFF).toByte()
        return body
    }

    private fun buildPmtSection(includeAudio: Boolean): ByteArray {
        val esBytes = if (includeAudio) 10 else 5
        val sectionLength = 9 + esBytes + 4
        val body = ByteArray(3 + sectionLength)
        var i = 0
        body[i++] = 0x02 // table_id
        body[i++] = (0xB0 or ((sectionLength shr 8) and 0x0F)).toByte()
        body[i++] = (sectionLength and 0xFF).toByte()
        body[i++] = 0x00
        body[i++] = 0x01
        body[i++] = 0xC1.toByte()
        body[i++] = 0x00
        body[i++] = 0x00
        i = writeSectionPid(body, i, PID_VIDEO)
        body[i++] = 0xF0.toByte()
        body[i++] = 0x00
        body[i++] = 0x1B // H.264
        i = writeSectionPid(body, i, PID_VIDEO)
        body[i++] = 0xF0.toByte()
        body[i++] = 0x00
        if (includeAudio) {
            body[i++] = 0x0F // AAC
            i = writeSectionPid(body, i, PID_AUDIO)
            body[i++] = 0xF0.toByte()
            body[i++] = 0x00
        }
        val crc = mpegCrc32(body, 0, i)
        body[i++] = ((crc shr 24) and 0xFF).toByte()
        body[i++] = ((crc shr 16) and 0xFF).toByte()
        body[i++] = ((crc shr 8) and 0xFF).toByte()
        body[i] = (crc and 0xFF).toByte()
        return body
    }

    private fun buildSectionPacket(pid: Int, section: ByteArray, counterIndex: Int): ByteArray {
        val packet = ByteArray(PACKET_SIZE) { 0xFF.toByte() }
        packet[0] = 0x47
        packet[1] = (0x40 or ((pid shr 8) and 0x1F)).toByte()
        packet[2] = (pid and 0xFF).toByte()
        packet[3] = (0x10 or nextCounter(counterIndex)).toByte()
        packet[4] = 0x00 // pointer_field
        System.arraycopy(section, 0, packet, 5, section.size)
        return packet
    }

    private fun buildPesPayload(streamId: Int, payload: ByteArray, ptsUs: Long): ByteArray {
        val pts = ptsTo90kHz(ptsUs)
        val ptsBytes = encodePts(pts)
        val pesHeaderSize = 9 + ptsBytes.size
        val pes = ByteArray(pesHeaderSize + payload.size)
        var i = 0
        pes[i++] = 0x00
        pes[i++] = 0x00
        pes[i++] = 0x01
        pes[i++] = streamId.toByte()
        val pesContentLength = pesHeaderSize - 6 + payload.size
        val pesLength = if (streamId == STREAM_ID_VIDEO && pesContentLength > 0xFFFF) {
            0
        } else {
            pesContentLength
        }
        pes[i++] = ((pesLength shr 8) and 0xFF).toByte()
        pes[i++] = (pesLength and 0xFF).toByte()
        pes[i++] = 0x80.toByte()
        pes[i++] = 0x80.toByte()
        pes[i++] = ptsBytes.size.toByte()
        System.arraycopy(ptsBytes, 0, pes, i, ptsBytes.size)
        i += ptsBytes.size
        System.arraycopy(payload, 0, pes, i, payload.size)
        return pes
    }

    private fun packetize(pid: Int, pes: ByteArray, pcr: Long?): List<ByteArray> {
        val packets = ArrayList<ByteArray>()
        var offset = 0
        var first = true
        val counterIndex = when (pid) {
            PID_VIDEO -> videoCounterIndex()
            PID_AUDIO -> audioCounterIndex()
            else -> 0
        }

        while (offset < pes.size) {
            val usePcr = first && pcr != null
            val maxPayload = if (usePcr) 176 else 184
            val remaining = pes.size - offset
            var chunkSize = minOf(remaining, maxPayload)
            var payloadStart = PACKET_SIZE - chunkSize
            var adaptationSize = payloadStart - 4

            if (adaptationSize in 1..1) {
                chunkSize -= 1
                payloadStart = PACKET_SIZE - chunkSize
                adaptationSize = payloadStart - 4
            }

            val packet = ByteArray(PACKET_SIZE) { 0xFF.toByte() }
            packet[0] = 0x47
            packet[1] = if (first) {
                (0x40 or ((pid shr 8) and 0x1F)).toByte()
            } else {
                ((pid shr 8) and 0x1F).toByte()
            }
            packet[2] = (pid and 0xFF).toByte()
            val counter = nextCounter(counterIndex)

            if (adaptationSize > 0) {
                packet[3] = (0x30 or counter).toByte()
                packet[4] = (adaptationSize - 1).toByte()
                if (usePcr) {
                    packet[5] = 0x10
                    writePcr(packet, 6, pcr!!)
                    var stuffPos = 12
                    while (stuffPos < payloadStart) {
                        packet[stuffPos++] = 0xFF.toByte()
                    }
                } else {
                    packet[5] = 0x00
                    var stuffPos = 6
                    while (stuffPos < payloadStart) {
                        packet[stuffPos++] = 0xFF.toByte()
                    }
                }
            } else {
                packet[3] = (0x10 or counter).toByte()
            }

            System.arraycopy(pes, offset, packet, payloadStart, chunkSize)
            packets.add(packet)
            offset += chunkSize
            first = false
        }
        return packets
    }

    private fun writePcr(packet: ByteArray, offset: Int, pcr: Long) {
        val pcrBase = pcr and 0x1FFFFFFFFL
        packet[offset] = ((pcrBase shr 25) and 0xFF).toByte()
        packet[offset + 1] = ((pcrBase shr 17) and 0xFF).toByte()
        packet[offset + 2] = ((pcrBase shr 9) and 0xFF).toByte()
        packet[offset + 3] = ((pcrBase shr 1) and 0xFF).toByte()
        packet[offset + 4] = (((pcrBase and 1) shl 7) or 0x7E).toByte()
        packet[offset + 5] = 0x00
    }

    private fun encodePts(pts: Long): ByteArray {
        return byteArrayOf(
            (0x20 or ((pts shr 29).toInt() and 0x0E) or 0x01).toByte(),
            ((pts shr 22).toInt() and 0xFF).toByte(),
            (0x01 or ((pts shr 14).toInt() and 0xFE)).toByte(),
            ((pts shr 7).toInt() and 0xFF).toByte(),
            (0x01 or ((pts shl 1).toInt() and 0xFE)).toByte(),
        )
    }

    private fun ptsTo90kHz(ptsUs: Long): Long {
        return ptsUs * 90 / 1000
    }

    private fun hasAnnexBStartCode(data: ByteArray): Boolean {
        if (data.size >= 4 &&
            data[0] == 0x00.toByte() &&
            data[1] == 0x00.toByte() &&
            data[2] == 0x00.toByte() &&
            data[3] == 0x01.toByte()
        ) {
            return true
        }
        return data.size >= 3 &&
            data[0] == 0x00.toByte() &&
            data[1] == 0x00.toByte() &&
            data[2] == 0x01.toByte()
    }

    private fun nextCounter(index: Int): Int {
        val value = continuityCounters[index]
        continuityCounters[index] = (value + 1) and 0x0F
        return value
    }

    private fun writeSectionPid(body: ByteArray, offset: Int, pid: Int): Int {
        val encoded = 0xE000 or (pid and 0x1FFF)
        body[offset] = ((encoded shr 8) and 0xFF).toByte()
        body[offset + 1] = (encoded and 0xFF).toByte()
        return offset + 2
    }

    private fun patCounterIndex() = 0
    private fun pmtCounterIndex() = 1
    private fun videoCounterIndex() = 2
    private fun audioCounterIndex() = 3

    private companion object {
        private const val PACKET_SIZE = 188
        private const val PID_PAT = 0
        private const val PID_PMT = 0x1000
        private const val PID_VIDEO = 0x100
        private const val PID_AUDIO = 0x101
        private const val STREAM_ID_VIDEO = 0xE0
        private const val STREAM_ID_AUDIO = 0xC0

        private val CRC_TABLE = IntArray(256) { i ->
            var crc = i shl 24
            repeat(8) {
                crc = if (crc and 0x80000000.toInt() != 0) {
                    (crc shl 1) xor 0x04C11DB7.toInt()
                } else {
                    crc shl 1
                }
            }
            crc
        }

        private fun mpegCrc32(data: ByteArray, offset: Int, length: Int): Int {
            var crc = 0xFFFFFFFF.toInt()
            for (index in offset until offset + length) {
                crc = (crc shl 8) xor CRC_TABLE[((crc ushr 24) xor (data[index].toInt() and 0xFF)) and 0xFF]
            }
            return crc
        }
    }
}
