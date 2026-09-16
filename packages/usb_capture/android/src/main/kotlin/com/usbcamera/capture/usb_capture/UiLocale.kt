package com.usbcamera.capture.usb_capture

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

object UiLocale {
    @Volatile
    var tag: String = "en"
        private set

    fun setTag(raw: String?) {
        tag = normalize(raw)
    }

    fun wrap(context: Context): Context {
        val locale = localeFromTag(tag)
        val config = Configuration(context.resources.configuration)
        config.setLocale(locale)
        return context.createConfigurationContext(config)
    }

    fun normalize(raw: String?): String {
        val value = raw?.trim().orEmpty()
        val lower = value.lowercase()
        return when {
            lower.startsWith("zh-hant") ||
                lower.startsWith("zh-tw") ||
                lower.startsWith("zh-hk") ||
                lower.startsWith("zh-mo") -> "zh-Hant"
            lower.startsWith("zh-hans") ||
                lower.startsWith("zh-cn") ||
                lower.startsWith("zh-sg") ||
                lower == "zh" -> "zh-Hans"
            lower.startsWith("en") -> "en"
            lower.startsWith("ja") -> "ja"
            lower.startsWith("ko") -> "ko"
            else -> "en"
        }
    }

    private fun localeFromTag(value: String): Locale {
        return when (value) {
            "zh-Hant" -> Locale.TRADITIONAL_CHINESE
            "zh-Hans" -> Locale.SIMPLIFIED_CHINESE
            "ja" -> Locale.JAPANESE
            "ko" -> Locale.KOREAN
            else -> Locale.ENGLISH
        }
    }
}
