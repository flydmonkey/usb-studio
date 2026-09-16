package com.usbcamera.capture.usb_capture

import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

/** Converts MediaCodec outputs (AVCC H.264, raw AAC) into HLS-friendly Annex-B / ADTS. */
internal object AvFormatConvert {
    private val START_CODE = byteArrayOf(0x00, 0x00, 0x00, 0x01)

    fun hasAnnexBStartCode(data: ByteArray): Boolean {
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

    fun hasAdtsSync(data: ByteArray): Boolean {
        return data.size >= 2 &&
            data[0] == 0xFF.toByte() &&
            (data[1].toInt() and 0xF0) == 0xF0
    }

    fun byteBufferToAnnexBNal(buffer: ByteBuffer): ByteArray {
        val dup = buffer.duplicate()
        val raw = ByteArray(dup.remaining())
        dup.get(raw)
        return nalToAnnexB(raw)
    }

    fun nalToAnnexB(nal: ByteArray): ByteArray {
        return if (hasAnnexBStartCode(nal)) {
            nal.copyOf()
        } else {
            START_CODE + nal
        }
    }

    fun avccToAnnexB(data: ByteArray): ByteArray {
        if (hasAnnexBStartCode(data)) {
            return data.copyOf()
        }
        val out = ByteArrayOutputStream(data.size + 16)
        var offset = 0
        while (offset + 4 <= data.size) {
            val length = readBe32(data, offset)
            if (length <= 0 || offset + 4 + length > data.size) {
                break
            }
            out.write(START_CODE)
            out.write(data, offset + 4, length)
            offset += 4 + length
        }
        if (out.size() == 0 && data.isNotEmpty()) {
            return nalToAnnexB(data)
        }
        return out.toByteArray()
    }

    fun prepareVideoForHls(
        frame: ByteArray,
        spsAnnexB: ByteArray?,
        ppsAnnexB: ByteArray?,
        keyframe: Boolean,
    ): ByteArray {
        val annexB = avccToAnnexB(frame)
        if (!keyframe || (spsAnnexB == null && ppsAnnexB == null)) {
            return annexB
        }
        val out = ByteArrayOutputStream(
            (spsAnnexB?.size ?: 0) + (ppsAnnexB?.size ?: 0) + annexB.size,
        )
        spsAnnexB?.let { out.write(it) }
        ppsAnnexB?.let { out.write(it) }
        out.write(annexB)
        return out.toByteArray()
    }

    fun wrapAacWithAdts(rawAac: ByteArray, sampleRate: Int, channelCount: Int): ByteArray {
        if (hasAdtsSync(rawAac)) {
            return rawAac.copyOf()
        }
        val frameLength = rawAac.size + 7
        val profile = 1 // AAC LC (profile_object_type = 1)
        val freqIndex = sampleRateIndex(sampleRate)
        val channels = channelCount.coerceIn(1, 7)
        val header = ByteArray(7)
        header[0] = 0xFF.toByte()
        header[1] = 0xF1.toByte()
        header[2] = (
            ((profile and 0x03) shl 6) or
                ((freqIndex and 0x0F) shl 2) or
                ((channels shr 2) and 0x01)
            ).toByte()
        header[3] = (
            ((channels and 0x03) shl 6) or
                ((frameLength shr 11) and 0x03)
            ).toByte()
        header[4] = ((frameLength shr 3) and 0xFF).toByte()
        header[5] = (
            ((frameLength and 0x07) shl 5) or 0x1F
            ).toByte()
        header[6] = 0xFC.toByte()
        return header + rawAac
    }

    private fun readBe32(data: ByteArray, offset: Int): Int {
        return ((data[offset].toInt() and 0xFF) shl 24) or
            ((data[offset + 1].toInt() and 0xFF) shl 16) or
            ((data[offset + 2].toInt() and 0xFF) shl 8) or
            (data[offset + 3].toInt() and 0xFF)
    }

    private fun sampleRateIndex(sampleRate: Int): Int {
        return when (sampleRate) {
            96000 -> 0
            88200 -> 1
            64000 -> 2
            48000 -> 3
            44100 -> 4
            32000 -> 5
            24000 -> 6
            22050 -> 7
            16000 -> 8
            12000 -> 9
            11025 -> 10
            8000 -> 11
            7350 -> 12
            else -> 4
        }
    }
}
