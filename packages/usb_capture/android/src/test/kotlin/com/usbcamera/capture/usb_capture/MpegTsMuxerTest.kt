package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class MpegTsMuxerTest {
    @Test
    fun flushSegmentProducesValidTsPackets() {
        val muxer = MpegTsMuxer()
        val videoNal = byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x65, 0x88.toByte(), 0x84.toByte())
        val audioFrame = byteArrayOf(
            0xFF.toByte(),
            0xF1.toByte(),
            0x50,
            0x80.toByte(),
            0x01,
            0x3F,
            0xFC.toByte(),
            0x01,
            0x02,
            0x03,
        )
        muxer.addVideoAccessUnit(videoNal, ptsUs = 0L, keyframe = true)
        muxer.addAudioAccessUnit(audioFrame, ptsUs = 0L)

        val segment = muxer.flushSegment()
        assertTrue(segment.isNotEmpty())
        assertEquals(0, segment.size % 188)

        var offset = 0
        while (offset < segment.size) {
            assertEquals(0x47, segment[offset].toInt() and 0xFF)
            offset += 188
        }
    }

    @Test
    fun flushSegmentWithNoDataReturnsEmpty() {
        val muxer = MpegTsMuxer()
        assertTrue(muxer.flushSegment().isEmpty())
    }

    @Test
    fun addVideoWithoutStartCodePrefixesAnnexB() {
        val muxer = MpegTsMuxer()
        muxer.addVideoAccessUnit(byteArrayOf(0x65, 0x88.toByte()), ptsUs = 1_000L, keyframe = false)
        val segment = muxer.flushSegment()
        assertTrue(segment.isNotEmpty())
        assertEquals(0, segment.size % 188)
    }

    @Test
    fun patPointsToPmtPid() {
        val muxer = MpegTsMuxer()
        muxer.addVideoAccessUnit(
            byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x65),
            ptsUs = 0L,
            keyframe = true,
        )
        val segment = muxer.flushSegment()
        val patPid = ((segment[1].toInt() and 0x1F) shl 8) or (segment[2].toInt() and 0xFF)
        assertEquals(0, patPid)

        val programMapPidOffset = 5 + 10
        val encoded = ((segment[programMapPidOffset].toInt() and 0xFF) shl 8) or
            (segment[programMapPidOffset + 1].toInt() and 0xFF)
        assertEquals(0x1000, encoded and 0x1FFF)
    }

    @Test
    fun videoOnlySegmentOmitsAacFromPmt() {
        val muxer = MpegTsMuxer()
        muxer.addVideoAccessUnit(
            byteArrayOf(0x00, 0x00, 0x00, 0x01, 0x65),
            ptsUs = 0L,
            keyframe = true,
        )
        val segment = muxer.flushSegment()
        val pmt = segment.copyOfRange(188, 376)
        assertEquals(0x1B, pmt[17].toInt() and 0xFF)
        val sectionLength = ((pmt[6].toInt() and 0x0F) shl 8) or (pmt[7].toInt() and 0xFF)
        assertEquals(18, sectionLength)
    }

    @Test
    fun largeVideoAuUsesUnboundedPesLength() {
        val muxer = MpegTsMuxer()
        val largeNal = ByteArray(70_000) { 0xAB.toByte() }
        largeNal[0] = 0x00
        largeNal[1] = 0x00
        largeNal[2] = 0x00
        largeNal[3] = 0x01
        largeNal[4] = 0x65
        muxer.addVideoAccessUnit(largeNal, ptsUs = 0L, keyframe = true)

        val segment = muxer.flushSegment()
        assertTrue(segment.isNotEmpty())
        assertEquals(0, segment.size % 188)

        var offset = 0
        while (offset < segment.size) {
            assertEquals(0x47, segment[offset].toInt() and 0xFF)
            offset += 188
        }
    }
}
