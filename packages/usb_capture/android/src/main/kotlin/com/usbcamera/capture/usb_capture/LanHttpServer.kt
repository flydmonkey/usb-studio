package com.usbcamera.capture.usb_capture

import android.content.Context
import android.os.ParcelFileDescriptor
import fi.iki.elonen.NanoHTTPD
import org.json.JSONArray
import org.json.JSONObject
import java.io.InputStream
import java.net.URLDecoder

internal class LanHttpServer(
    private val context: Context,
    private val listRecordings: () -> List<Map<String, Any?>>,
    private val openRecording: (String) -> Pair<ParcelFileDescriptor, Long>?,
    private val mjpegHub: () -> MjpegHub?,
    private val liveStatus: () -> JSONObject,
    private val liveViewers: LanLiveViewers,
    private val onLiveViewersChanged: () -> Unit,
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
        liveViewers.closeAllTracked()
        impl?.stop()
        impl = null
        boundPort = 0
        if (liveViewers.count() != 0) {
            while (liveViewers.remove() > 0) {}
            onLiveViewersChanged()
        }
    }

    private inner class ServerImpl(port: Int) : NanoHTTPD("0.0.0.0", port) {
        override fun serve(session: IHTTPSession): Response {
            if (session.method != Method.GET) {
                return newFixedLengthResponse(Response.Status.METHOD_NOT_ALLOWED, MIME_PLAINTEXT, "")
            }
            val path = session.uri.substringBefore('?')
            return when {
                path == "/" || path == "/index.html" -> serveIndex()
                path == "/api/recordings" -> serveRecordings()
                path == "/api/live" -> serveLiveStatus()
                path == "/live.mjpeg" -> serveLiveMjpeg()
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
                    .put("player", localized.getString(R.string.lan_player))
                    .put("livePreview", localized.getString(R.string.lan_live_preview))
                    .put("fullscreen", localized.getString(R.string.lan_fullscreen))
                    .put("exitFullscreen", localized.getString(R.string.lan_exit_fullscreen))
                    .put("chooseSource", localized.getString(R.string.lan_choose_source))
                    .put("waitingCard", localized.getString(R.string.lan_waiting_card))
                    .put("recordings", localized.getString(R.string.lan_recordings))
                    .put("loading", localized.getString(R.string.lan_loading))
                    .put("liveUnsupported", localized.getString(R.string.lan_live_unsupported))
                    .put("needMjpeg", localized.getString(R.string.lan_need_mjpeg))
                    .put("pausedStream", localized.getString(R.string.lan_paused_stream))
                    .put("loadFailed", localized.getString(R.string.lan_load_failed))
                    .put("empty", localized.getString(R.string.lan_empty))
                    .put("unnamed", localized.getString(R.string.lan_unnamed))
                    .put("download", localized.getString(R.string.lan_download))
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
            val body = liveStatus().toString()
            return newFixedLengthResponse(
                Response.Status.OK,
                "application/json; charset=utf-8",
                body,
            ).apply {
                addHeader("Cache-Control", "no-cache")
            }
        }

        private fun serveLiveMjpeg(): Response {
            val hub = mjpegHub()
                ?: return newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
            liveViewers.add()
            onLiveViewersChanged()
            lateinit var stream: MjpegMultipartStream
            stream = MjpegMultipartStream(hub, onClosed = {
                liveViewers.untrack(stream)
                liveViewers.remove()
                onLiveViewersChanged()
            })
            liveViewers.track(stream)
            return newChunkedResponse(
                Response.Status.OK,
                "multipart/x-mixed-replace; boundary=${MjpegPart.BOUNDARY}",
                stream,
            ).apply {
                addHeader("Cache-Control", "no-cache, no-store, must-revalidate")
                addHeader("Pragma", "no-cache")
                addHeader("Connection", "close")
            }
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
            val download = VodDownload.requested(session.parms)
            val range = if (download) null else HttpRange.parse(rangeHeader, total)
            val input = ParcelFileDescriptor.AutoCloseInputStream(pfd)
            return if (range == null) {
                newFixedLengthResponse(
                    Response.Status.OK,
                    "video/mp4",
                    input,
                    total,
                ).apply {
                    addHeader("Accept-Ranges", "bytes")
                    if (download) {
                        val name = listRecordings().firstOrNull { it["id"]?.toString() == id }
                            ?.get("name")?.toString()
                        addHeader("Content-Disposition", VodDownload.contentDisposition(name))
                    }
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
