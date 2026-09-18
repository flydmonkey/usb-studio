package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class CaptureRuntimePolicyTest {
    @Test
    fun keepsEngineWhenPreviewSessionStillOpenAfterLanStops() {
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = false,
                httpServing = false,
                sessionOpen = true,
            ),
        )
    }

    @Test
    fun releasesOnlyWhenNothingIsUsingTheCamera() {
        assertTrue(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = false,
                httpServing = false,
                sessionOpen = false,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = true,
                streaming = false,
                httpServing = false,
                sessionOpen = false,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = true,
                httpServing = false,
                sessionOpen = false,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldRelease(
                recording = false,
                streaming = false,
                httpServing = true,
                sessionOpen = false,
            ),
        )
    }

    @Test
    fun lanJpegEncodeOnlyWhileLiveViewersExist() {
        assertFalse(
            CaptureRuntimePolicy.shouldEncodeLanLive(
                httpServing = true,
                liveViewers = 0,
                streaming = false,
            ),
        )
        assertTrue(
            CaptureRuntimePolicy.shouldEncodeLanLive(
                httpServing = true,
                liveViewers = 1,
                streaming = false,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldEncodeLanLive(
                httpServing = true,
                liveViewers = 1,
                streaming = true,
            ),
        )
        assertFalse(
            CaptureRuntimePolicy.shouldEncodeLanLive(
                httpServing = false,
                liveViewers = 1,
                streaming = false,
            ),
        )
    }

    @Test
    fun formatLockRejectsLanMjpegPublishingLikeStreaming() {
        assertEquals(
            "streamFailed" to "streamInProgress",
            CaptureRuntimePolicy.formatLock(
                recording = false,
                streaming = false,
                lanLiveBusy = true,
            ),
        )
        assertEquals(
            "streamFailed" to "streamInProgress",
            CaptureRuntimePolicy.formatLock(
                recording = false,
                streaming = true,
                lanLiveBusy = false,
            ),
        )
    }

    @Test
    fun formatLockAllowsWhenLanServerHasNoViewers() {
        assertNull(
            CaptureRuntimePolicy.formatLock(
                recording = false,
                streaming = false,
                lanLiveBusy = false,
            ),
        )
    }

    @Test
    fun formatLockPrefersRecordingWhenRecording() {
        assertEquals(
            "recordingFailed" to "recordingInProgress",
            CaptureRuntimePolicy.formatLock(
                recording = true,
                streaming = false,
                lanLiveBusy = true,
            ),
        )
    }
}
