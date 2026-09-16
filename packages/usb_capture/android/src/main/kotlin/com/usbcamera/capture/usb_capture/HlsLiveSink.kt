package com.usbcamera.capture.usb_capture

/** Muxes encoded A/V into MPEG-TS segments for [HlsWindow]. */
internal class HlsLiveSink(
    private val window: HlsWindow,
) : RtmpStreamSession.EncodedSink {
    private val muxer = MpegTsMuxer()
    private var segmentFirstPtsUs: Long? = null
    private var segmentLastPtsUs = 0L

    @Synchronized
    override fun onVideo(annexB: ByteArray, ptsUs: Long, keyframe: Boolean) {
        notePts(ptsUs)
        muxer.addVideoAccessUnit(annexB, ptsUs, keyframe)
        maybeFlush(keyframe)
    }

    @Synchronized
    override fun onAudio(adtsOrAac: ByteArray, ptsUs: Long) {
        notePts(ptsUs)
        muxer.addAudioAccessUnit(adtsOrAac, ptsUs)
        maybeFlush(atKeyframe = false)
    }

    private fun notePts(ptsUs: Long) {
        if (segmentFirstPtsUs == null) {
            segmentFirstPtsUs = ptsUs
        }
        segmentLastPtsUs = ptsUs
    }

    @Synchronized
    private fun maybeFlush(atKeyframe: Boolean) {
        val first = segmentFirstPtsUs ?: return
        val durationSec = EncoderLimits.hlsSegmentDuration(
            (segmentLastPtsUs - first) / 1_000_000.0,
        )
        val shouldFlush = (atKeyframe && durationSec >= 0.8) || durationSec >= 2.0
        if (!shouldFlush) return
        val ts = muxer.flushSegment()
        if (ts.isEmpty()) return
        window.append(ts, durationSec)
        android.util.Log.i(
            "usb_capture",
            "HLS segment appended bytes=${ts.size} dur=$durationSec count=${window.segmentCount()}",
        )
        segmentFirstPtsUs = null
    }
}
