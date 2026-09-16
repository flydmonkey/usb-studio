package com.usbcamera.capture.usb_capture

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import java.io.File
import java.nio.ByteBuffer

object SessionConcat {
    internal fun isFatalAudioMismatch(outputHasAudio: Boolean, sourceHasAudio: Boolean): Boolean {
        return false
    }

    internal fun shouldCopyAudio(outputHasAudio: Boolean, sourceHasAudio: Boolean): Boolean {
        return outputHasAudio && sourceHasAudio
    }

    fun remux(context: Context, uris: List<Uri>, output: File) {
        if (uris.size < 2) {
            throw CaptureException("recordingFailed", "concatFailed")
        }
        val first = MediaExtractor()
        val videoFormat: MediaFormat
        val audioFormat: MediaFormat?
        try {
            first.setDataSource(context, uris.first(), null)
            val videoIndex = findTrack(first, "video/")
                ?: throw CaptureException("recordingFailed", "concatFailed")
            videoFormat = first.getTrackFormat(videoIndex)
            audioFormat = findTrack(first, "audio/")?.let(first::getTrackFormat)
        } catch (error: CaptureException) {
            throw error
        } catch (error: Exception) {
            throw mapped(error)
        } finally {
            first.release()
        }

        if (output.exists() && !output.delete()) {
            throw CaptureException("recordingFailed", "concatFailed")
        }
        val muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var started = false
        try {
            val outVideo = muxer.addTrack(videoFormat)
            val outAudio = audioFormat?.let(muxer::addTrack)
            muxer.start()
            started = true
            var videoBase = 0L
            var audioBase = 0L
            for (uri in uris) {
                val extractor = MediaExtractor()
                try {
                    extractor.setDataSource(context, uri, null)
                    val videoIndex = findTrack(extractor, "video/")
                        ?: throw CaptureException("recordingFailed", "concatFailed")
                    val audioIndex = findTrack(extractor, "audio/")
                    val sourceHasAudio = audioIndex != null
                    if (isFatalAudioMismatch(outAudio != null, sourceHasAudio)) {
                        throw CaptureException("recordingFailed", "concatFailed")
                    }
                    if (!sameVideo(extractor.getTrackFormat(videoIndex), videoFormat)) {
                        throw CaptureException("recordingFailed", "concatFailed")
                    }
                    val lastVideo = copyTrack(
                        extractor,
                        videoIndex,
                        muxer,
                        outVideo,
                        videoBase,
                        maxInput(videoFormat),
                    )
                    val copyAudio = shouldCopyAudio(outAudio != null, sourceHasAudio)
                    val lastAudio = if (copyAudio && audioIndex != null && outAudio != null) {
                        copyTrack(
                            extractor,
                            audioIndex,
                            muxer,
                            outAudio,
                            audioBase,
                            maxInput(audioFormat),
                        )
                    } else {
                        audioBase
                    }
                    videoBase = lastVideo + 1
                    audioBase = if (copyAudio) lastAudio + 1 else videoBase
                } finally {
                    extractor.release()
                }
            }
        } catch (error: CaptureException) {
            throw error
        } catch (error: Exception) {
            throw mapped(error)
        } finally {
            try {
                if (started) {
                    muxer.stop()
                }
            } catch (_: Exception) {
            }
            muxer.release()
        }
    }

    private fun copyTrack(
        extractor: MediaExtractor,
        trackIndex: Int,
        muxer: MediaMuxer,
        outTrack: Int,
        baseUs: Long,
        bufferBytes: Int,
    ): Long {
        extractor.selectTrack(trackIndex)
        extractor.seekTo(0, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
        val buffer = ByteBuffer.allocate(bufferBytes)
        val info = MediaCodec.BufferInfo()
        var lastPts = baseUs
        var wrote = false
        while (true) {
            buffer.clear()
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) {
                break
            }
            val flags = extractor.sampleFlags
            if (flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                extractor.advance()
                continue
            }
            info.offset = 0
            info.size = size
            info.flags = flags
            val sampleTime = extractor.sampleTime
            var pts = if (sampleTime < 0) lastPts else sampleTime + baseUs
            if (wrote && pts <= lastPts) {
                pts = lastPts + 1
            }
            info.presentationTimeUs = pts
            lastPts = pts
            wrote = true
            buffer.position(0)
            buffer.limit(size)
            muxer.writeSampleData(outTrack, buffer, info)
            extractor.advance()
        }
        extractor.unselectTrack(trackIndex)
        return lastPts
    }

    private fun findTrack(extractor: MediaExtractor, prefix: String): Int? {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith(prefix)) {
                return index
            }
        }
        return null
    }

    private fun sameVideo(left: MediaFormat, right: MediaFormat): Boolean {
        return left.getString(MediaFormat.KEY_MIME) == right.getString(MediaFormat.KEY_MIME) &&
            integer(left, MediaFormat.KEY_WIDTH) == integer(right, MediaFormat.KEY_WIDTH) &&
            integer(left, MediaFormat.KEY_HEIGHT) == integer(right, MediaFormat.KEY_HEIGHT)
    }

    private fun integer(format: MediaFormat, key: String): Int {
        return if (format.containsKey(key)) format.getInteger(key) else -1
    }

    private fun maxInput(format: MediaFormat?): Int {
        val fromFormat = format?.takeIf { it.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE) }
            ?.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE) ?: 0
        return maxOf(fromFormat, 2 * 1024 * 1024)
    }

    private fun mapped(error: Exception): CaptureException {
        android.util.Log.e("SessionConcat", "remux failed", error)
        val message = error.message.orEmpty()
        if (message.contains("ENOSPC", ignoreCase = true) ||
            message.contains("No space", ignoreCase = true)
        ) {
            return CaptureException("recordingFailed", "concatStorage")
        }
        return CaptureException("recordingFailed", "concatFailed")
    }
}
