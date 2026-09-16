package com.usbcamera.capture.usb_capture

import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class SessionConcatInstrumentedTest {
    @Test
    fun remuxTwoClipsKeepsOriginalsAndIsPlayable() {
        val context = InstrumentationRegistry.getInstrumentation().context
        val a = copyAsset("concat/seg_a.mp4")
        val b = copyAsset("concat/seg_b.mp4")
        val originalA = a.length()
        val originalB = b.length()
        val out = File(context.cacheDir, "concat_out.mp4")
        SessionConcat.remux(context, listOf(Uri.fromFile(a), Uri.fromFile(b)), out)
        assertTrue(out.length() > 0)
        assertEquals(originalA, a.length())
        assertEquals(originalB, b.length())
        val extractor = MediaExtractor()
        extractor.setDataSource(out.absolutePath)
        var videoTracks = 0
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("video/") == true) {
                videoTracks++
            }
        }
        extractor.release()
        assertEquals(1, videoTracks)
    }

    private fun copyAsset(name: String): File {
        val context = InstrumentationRegistry.getInstrumentation().context
        val dest = File(context.cacheDir, File(name).name)
        context.assets.open(name).use { input ->
            dest.outputStream().use { output -> input.copyTo(output) }
        }
        return dest
    }
}
