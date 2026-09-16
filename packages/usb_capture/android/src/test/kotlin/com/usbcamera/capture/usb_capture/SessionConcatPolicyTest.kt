package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class SessionConcatPolicyTest {
    @Test
    fun laterVideoOnlySegmentIsAllowedWhenEarlierHasAudio() {
        assertFalse(SessionConcat.isFatalAudioMismatch(outputHasAudio = true, sourceHasAudio = false))
        assertFalse(SessionConcat.isFatalAudioMismatch(outputHasAudio = false, sourceHasAudio = true))
    }

    @Test
    fun copiesAudioOnlyWhenTheOutputTrackAndSourceBothHaveIt() {
        assertTrue(SessionConcat.shouldCopyAudio(outputHasAudio = true, sourceHasAudio = true))
        assertFalse(SessionConcat.shouldCopyAudio(outputHasAudio = true, sourceHasAudio = false))
        assertFalse(SessionConcat.shouldCopyAudio(outputHasAudio = false, sourceHasAudio = true))
    }
}
