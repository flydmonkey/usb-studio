package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

internal class RecordingLibraryConcatTest {
    @Test
    fun concatRejectsTheSessionStillRecording() {
        val error = assertFailsWith<CaptureException> {
            RecordingLibrary.preflight(
                "20260915_153000",
                listOf("content://1", "content://2"),
                "USB_20260915_153000.mp4",
                "20260915_153000",
            )
        }
        assertEquals("recordingFailed", error.code)
        assertEquals("sessionRecording", error.details)
    }

    @Test
    fun concatNeedsTwoSegments() {
        val error = assertFailsWith<CaptureException> {
            RecordingLibrary.preflight(
                "20260915_153000",
                listOf("content://1"),
                "USB_20260915_153000.mp4",
                null,
            )
        }
        assertEquals("concatFailed", error.details)
    }
}
