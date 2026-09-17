# LAN VOD Download Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a LAN browser save each listed recording as an MP4 without changing in-page playback.

**Architecture:** Keep `GET /vod/<id>` for Range playback. When the query is `download=1`, return the whole file with `Content-Disposition: attachment`. The home list keeps tap-to-play and adds a separate download link.

**Tech Stack:** Kotlin NanoHTTPD, `lan_http/index.html`, Android string resources, JUnit.

## Global Constraints

- Android-only LAN HTTP; no auth, no HTTPS
- Playback `/vod/<id>` Range/206 must stay unchanged
- `download=1` ignores Range and returns 200 of the full file
- Filename from library display name; ASCII fallback `recording.mp4` plus RFC 5987 `filename*`
- Live MJPEG unchanged
- Do not commit unless asked

---

### Task 1: Filename and download query helpers

**Files:**
- Create: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/VodDownload.kt`
- Test: `packages/usb_capture/android/src/test/kotlin/com/usbcamera/capture/usb_capture/VodDownloadTest.kt`

**Interfaces:**
- Produces: `VodDownload.requested(parms: Map<String, String>?): Boolean`
- Produces: `VodDownload.fileName(displayName: String?): String`
- Produces: `VodDownload.contentDisposition(displayName: String?): String`

- [ ] Failing tests: `download=1` true; missing/other values false; empty/`foo/bar.mp4`/`..` → `recording.mp4` or sanitized `bar.mp4`; header contains `attachment`, `filename="recording.mp4"`, and `filename*=UTF-8''`
- [ ] Implement `VodDownload`
- [ ] `./gradlew :usb_capture:testDebugUnitTest --tests com.usbcamera.capture.usb_capture.VodDownloadTest` passes

### Task 2: Serve attachment on `/vod/<id>?download=1`

**Files:**
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/LanHttpServer.kt`
- Modify: `openspec/specs/lan-http-playback/spec.md`

- [ ] In `serveVod`, if `VodDownload.requested(session.parms)`: look up `name` from `listRecordings()` by id; return 200 full body; add `Content-Disposition` from `VodDownload.contentDisposition(name)`; do not parse Range
- [ ] Spec: document `?download=1` attachment scenario; playback Range scenario unchanged
- [ ] Unit tests still pass

### Task 3: Home list download control + five-locale copy

**Files:**
- Modify: `packages/usb_capture/android/src/main/assets/lan_http/index.html`
- Modify: `packages/usb_capture/android/src/main/kotlin/.../LanHttpServer.kt` (`serveIndex` i18n payload)
- Modify: `packages/usb_capture/android/src/main/res/values/strings.xml` and `values-zh-rCN`, `values-zh-rTW`, `values-ja`, `values-ko`

- [ ] `lan_download`: Download / 下载 / 下載 / ダウンロード / 다운로드
- [ ] Row: name click plays; `<a class="dl" download>` to `/vod/{id}?download=1` with `stopPropagation`
- [ ] Download must not start playback or clear the current VOD

---

After Task 3: `flutter test` is optional (no Dart API). Run `:usb_capture:testDebugUnitTest` for `VodDownloadTest` and `HttpRangeTest`. Install release APK on `83da96a0321` if the device is attached.
