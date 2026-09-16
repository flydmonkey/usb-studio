package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class AvFormatConvertTest {
    @Test
    fun avccToAnnexBConvertsLengthPrefixedNals() {
        val avcc = byteArrayOf(
            0x00, 0x00, 0x00, 0x03,
            0x65, 0x88.toByte(), 0x84.toByte(),
            0x00, 0x00, 0x00, 0x02,
            0x41, 0x9A.toByte(),
        )
        val annexB = AvFormatConvert.avccToAnnexB(avcc)
        assertTrue(AvFormatConvert.hasAnnexBStartCode(annexB))
        assertEquals(
            listOf(
                0x00, 0x00, 0x00, 0x01, 0x65, 0x88, 0x84,
                0x00, 0x00, 0x00, 0x01, 0x41, 0x9A,
            ),
            annexB.map { it.toInt() and 0xFF },
        )
    }

    @Test
    fun prepareVideoForHlsPrependsSpsPpsOnKeyframe() {
        val sps = byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x67, 0x42)
        val pps = byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x68, 0xCE.toByte())
        val frame = byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x65, 0x88.toByte())
        val out = AvFormatConvert.prepareVideoForHls(frame, sps, pps, keyframe = true)
        assertTrue(out.startsWith(sps))
        assertTrue(out.copyOfRange(sps.size, sps.size + pps.size).contentEquals(pps))
        assertTrue(
            AvFormatConvert.hasAnnexBStartCode(out.copyOfRange(sps.size + pps.size, out.size)),
        )
    }

    @Test
    fun prepareVideoForHlsSkipsSpsPpsOnNonKeyframe() {
        val sps = byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x67)
        val frame = byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x41, 0x9A.toByte())
        val out = AvFormatConvert.prepareVideoForHls(frame, sps, null, keyframe = false)
        assertEquals(frame.toList(), out.toList())
    }

    @Test
    fun wrapAacWithAdtsAddsHeaderForRawAac() {
        val raw = byteArrayOf(0x21, 0x10, 0x04, 0x60, 0x8C.toByte())
        val adts = AvFormatConvert.wrapAacWithAdts(raw, sampleRate = 44100, channelCount = 2)
        assertTrue(AvFormatConvert.hasAdtsSync(adts))
        assertEquals(7 + raw.size, adts.size)
        assertTrue(adts.copyOfRange(7, adts.size).contentEquals(raw))
    }

    @Test
    fun wrapAacWithAdtsLeavesExistingAdtsUntouched() {
        val existing = byteArrayOf(
            0xFF.toByte(),
            0xF1.toByte(),
            0x50,
            0x80.toByte(),
            0x01,
            0x3F,
            0xFC.toByte(),
            0x01,
            0x02,
        )
        val out = AvFormatConvert.wrapAacWithAdts(existing, 48000, 2)
        assertTrue(out.contentEquals(existing))
    }

    private fun ByteArray.startsWith(prefix: ByteArray): Boolean {
        if (size < prefix.size) return false
        return copyOfRange(0, prefix.size).contentEquals(prefix)
    }
}
