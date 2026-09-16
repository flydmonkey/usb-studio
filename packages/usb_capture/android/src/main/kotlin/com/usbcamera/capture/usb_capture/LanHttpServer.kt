package com.usbcamera.capture.usb_capture

import android.content.Context
import android.os.ParcelFileDescriptor
import fi.iki.elonen.NanoHTTPD
import org.json.JSONArray
import org.json.JSONObject
import java.io.InputStream
import java.net.URLDecoder

class LanHttpServer(
    private val context: Context,
    private val listRecordings: () -> List<Map<String, Any?>>,
    private val openRecording: (String) -> Pair<ParcelFileDescriptor, Long>?,
    private val hlsWindow: () -> HlsWindow?,
) {
    private var impl: ServerImpl? = null
    private var boundPort = 0

    val isRunning: Boolean
        get() = impl?.isAlive == true

    fun start(preferredPort: Int = 8080): Int {
        if (isRunning) return boundPort
        for (offset in 0 until 10) {
            val port = preferredPort + offset
            try {
                val server = ServerImpl(port)
                server.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false)
                impl = server
                boundPort = port
                return port
            } catch (_: Exception) {
            }
        }
        throw CaptureException("streamFailed", "httpBindFailed")
    }

    fun stop() {
        impl?.stop()
        impl = null
        boundPort = 0
    }

    private inner class ServerImpl(port: Int) : NanoHTTPD("0.0.0.0", port) {
        override fun serve(session: IHTTPSession): Response {
            if (session.method != Method.GET) {
                return newFixedLengthResponse(Response.Status.METHOD_NOT_ALLOWED, MIME_PLAINTEXT, "")
            }
            val path = session.uri.substringBefore('?')
            return when {
                path == "/" || path == "/index.html" -> serveIndex()
                path == "/hls.min.js" -> serveAsset("lan_http/hls.min.js", "application/javascript")
                path == "/api/recordings" -> serveRecordings()
                path == "/api/live" -> serveLiveStatus()
                path == "/live.m3u8" -> serveLivePlaylist()
                path.startsWith("/live/") -> serveLiveSegment(path.removePrefix("/live/"))
                path.startsWith("/vod/") -> serveVod(path.removePrefix("/vod/"), session)
                else -> newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            }.also { addCors(it) }
        }

        private fun addCors(response: Response): Response {
            response.addHeader("Access-Control-Allow-Origin", "*")
            response.addHeader("Access-Control-Allow-Methods", "GET, OPTIONS")
            response.addHeader("Access-Control-Allow-Headers", "Range")
            return response
        }

        private fun serveIndex(): Response {
            return try {
                val html = context.assets.open("lan_http/index.html").bufferedReader().use { it.readText() }
                val localized = UiLocale.wrap(context)
                val payload = JSONObject()
                    .put("lang", UiLocale.tag)
                    .put("title", localized.getString(R.string.lan_page_title))
                    .put("hint", localized.getString(R.string.lan_page_hint))
                    .put("live", localized.getString(R.string.lan_live))
                    .put("waitingCard", localized.getString(R.string.lan_waiting_card))
                    .put("recordings", localized.getString(R.string.lan_recordings))
                    .put("loading", localized.getString(R.string.lan_loading))
                    .put("liveUnsupported", localized.getString(R.string.lan_live_unsupported))
                    .put("loadFailed", localized.getString(R.string.lan_load_failed))
                    .put("empty", localized.getString(R.string.lan_empty))
                    .put("unnamed", localized.getString(R.string.lan_unnamed))
                val body = html.replace(
                    "window.LAN_I18N = window.LAN_I18N || {};",
                    "window.LAN_I18N = $payload;",
                ).toByteArray(Charsets.UTF_8)
                newFixedLengthResponse(
                    Response.Status.OK,
                    "text/html; charset=utf-8",
                    body.inputStream(),
                    body.size.toLong(),
                )
            } catch (_: Exception) {
                newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            }
        }

        private fun serveAsset(assetPath: String, mime: String): Response {
            return try {
                context.assets.open(assetPath).use { input ->
                    val body = input.readBytes()
                    newFixedLengthResponse(Response.Status.OK, mime, body.inputStream(), body.size.toLong())
                }
            } catch (_: Exception) {
                newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            }
        }

        private fun serveRecordings(): Response {
            val array = JSONArray()
            for (item in listRecordings()) {
                array.put(
                    JSONObject().apply {
                        put("id", item["id"]?.toString() ?: "")
                        put("name", item["name"]?.toString() ?: "")
                        put(
                            "bytes",
                            when (val bytes = item["bytes"]) {
                                is Number -> bytes.toLong()
                                else -> 0L
                            },
                        )
                    },
                )
            }
            return newFixedLengthResponse(
                Response.Status.OK,
                "application/json; charset=utf-8",
                array.toString(),
            )
        }

        private fun serveLiveStatus(): Response {
            val window = hlsWindow()
            val body = JSONObject()
                .put("segments", window?.segmentCount() ?: 0)
                .toString()
            return newFixedLengthResponse(
                Response.Status.OK,
                "application/json; charset=utf-8",
                body,
            ).apply {
                addHeader("Cache-Control", "no-cache")
            }
        }

        private fun serveLivePlaylist(): Response {
            val body = hlsWindow()?.playlist(base = "/live/") ?: HlsWindow().playlist(base = "/live/")
            return newFixedLengthResponse(
                Response.Status.OK,
                "application/vnd.apple.mpegurl",
                body,
            ).apply {
                addHeader("Cache-Control", "no-cache")
            }
        }

        private fun serveLiveSegment(name: String): Response {
            val data = hlsWindow()?.segment(name)
                ?: return newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            return newFixedLengthResponse(
                Response.Status.OK,
                "video/mp2t",
                data.inputStream(),
                data.size.toLong(),
            )
        }

        private fun serveVod(encodedId: String, session: IHTTPSession): Response {
            val id = try {
                URLDecoder.decode(encodedId, Charsets.UTF_8.name())
            } catch (_: Exception) {
                return newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            }
            val opened = openRecording(id)
                ?: return newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            val (pfd, total) = opened
            if (total <= 0L) {
                pfd.close()
                return newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            }
            val rangeHeader = session.headers.entries.firstOrNull {
                it.key.equals("range", ignoreCase = true)
            }?.value
            val range = HttpRange.parse(rangeHeader, total)
            val input = ParcelFileDescriptor.AutoCloseInputStream(pfd)
            return if (range == null) {
                newFixedLengthResponse(
                    Response.Status.OK,
                    "video/mp4",
                    input,
                    total,
                ).apply {
                    addHeader("Accept-Ranges", "bytes")
                }
            } else {
                skipFully(input, range.start)
                newFixedLengthResponse(
                    Response.Status.PARTIAL_CONTENT,
                    "video/mp4",
                    input,
                    range.length,
                ).apply {
                    addHeader("Accept-Ranges", "bytes")
                    addHeader("Content-Range", "bytes ${range.start}-${range.end}/$total")
                }
            }
        }

        private fun skipFully(input: InputStream, bytes: Long) {
            var remaining = bytes
            while (remaining > 0L) {
                val skipped = input.skip(remaining)
                if (skipped <= 0L) {
                    if (input.read() < 0) break
                    remaining--
                } else {
                    remaining -= skipped
                }
            }
        }
    }
}
