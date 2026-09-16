package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals

internal class UiLocaleTest {
    @Test
    fun unmatchedTagFallsBackToEnglish() {
        assertEquals("en", UiLocale.normalize("fr-FR"))
        assertEquals("en", UiLocale.normalize(""))
        assertEquals("en", UiLocale.normalize(null))
    }

    @Test
    fun mapsChineseRegions() {
        assertEquals("zh-Hans", UiLocale.normalize("zh-CN"))
        assertEquals("zh-Hans", UiLocale.normalize("zh-Hans"))
        assertEquals("zh-Hans", UiLocale.normalize("zh"))
        assertEquals("zh-Hant", UiLocale.normalize("zh-TW"))
        assertEquals("zh-Hant", UiLocale.normalize("zh-Hant"))
        assertEquals("en", UiLocale.normalize("en-US"))
        assertEquals("ja", UiLocale.normalize("ja-JP"))
        assertEquals("ja", UiLocale.normalize("ja"))
        assertEquals("ko", UiLocale.normalize("ko-KR"))
        assertEquals("ko", UiLocale.normalize("ko"))
    }
}
