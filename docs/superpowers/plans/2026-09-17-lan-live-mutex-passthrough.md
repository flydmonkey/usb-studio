# LAN Live Mutex + JPEG Passthrough Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Serve LAN live as raw UVC JPEG, and yield the phone TextureView only while a browser is actually reading `/live.mjpeg`.

**Architecture:** Count `/live.mjpeg` readers. When count > 0, format is MJPEG, and RTMP is off, switch the UVC callback to `PIXEL_FORMAT_RAW`, publish JPEG bytes (SOI) into `MjpegHub`, and detach the phone preview surface. When count returns to 0 (or ingest starts), clear the LAN callback and restore the surface if `previewEnabled`. Flutter hides `UsbCapturePreview` on `lanLiveBusy` without changing the preview preference.

**Tech Stack:** Kotlin, UVCAndroid, NanoHTTPD, Flutter EventChannel, JUnit, `flutter test`.

## Global Constraints

- Android-only LAN HTTP; no auth, no HTTPS
- Do not encode NV21/RGBX to JPEG for LAN; do not screenshot TextureView for LAN
- Do not mutate `previewEnabled`; do not stop capture session, recording, or phone audio monitor
- RTMP stays NV21; LAN live pauses while ingest is on
- `CaptureRuntimePolicy.shouldRelease` must stay false while `sessionOpen`
- No CH9329, no LAN live audio
- Do not commit unless the user asks
- Device install stays `adb -s 83da96a0321 install -r` of `app-release.apk` when verifying on hardware

## File map

| File | Responsibility |
| --- | --- |
| `LanLiveViewers.kt` | Viewer count + `active(streaming, mjpeg)` |
| `MjpegJpeg.kt` / `JpegFrameFormat.kt` | SOI detection before NV21/RGBX size heuristics |
| `JpegLiveEncoder.kt` | Publish extracted JPEG immediately; no worker for passthrough |
| `MjpegPart.kt` (`MjpegMultipartStream`) | `close()` once; touch timestamp; 30s stale close |
| `LanHttpServer.kt` | Bind stream lifecycle to viewers |
| `CaptureEngine.kt` | RAW vs NV21 callback, surface mutex, emit `lanLiveBusy` |
| `capture_event.dart` / `session_state.dart` | Event + `lanLiveBusy` flag |
| `preview_page.dart` + ARB | Hide preview widget, show copy |
| `openspec/specs/lan-http-playback/spec.md` | Requirements match this behavior |

---

### Task 1: `LanLiveViewers`

**Files:**
- Create: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/LanLiveViewers.kt`
- Test: `packages/usb_capture/android/src/test/kotlin/com/usbcamera/capture/usb_capture/LanLiveViewersTest.kt`

**Interfaces:**
- Produces: `class LanLiveViewers`
- Produces: `fun add(): Int`
- Produces: `fun remove(): Int`
- Produces: `fun count(): Int`
- Produces: `fun active(streaming: Boolean, mjpeg: Boolean): Boolean` — `count() > 0 && !streaming && mjpeg`

- [ ] **Step 1: Write the failing test**

```kotlin
package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class LanLiveViewersTest {
    @Test
    fun addRemoveAndNeverNegative() {
        val viewers = LanLiveViewers()
        assertEquals(1, viewers.add())
        assertEquals(2, viewers.add())
        assertEquals(1, viewers.remove())
        assertEquals(0, viewers.remove())
        assertEquals(0, viewers.remove())
        assertEquals(0, viewers.count())
    }

    @Test
    fun activeNeedsViewersMjpegAndNoStream() {
        val viewers = LanLiveViewers()
        assertFalse(viewers.active(streaming = false, mjpeg = true))
        viewers.add()
        assertTrue(viewers.active(streaming = false, mjpeg = true))
        assertFalse(viewers.active(streaming = true, mjpeg = true))
        assertFalse(viewers.active(streaming = false, mjpeg = false))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `(cd android && ./gradlew :usb_capture:testDebugUnitTest --tests com.usbcamera.capture.usb_capture.LanLiveViewersTest)`

Expected: FAIL compile — `LanLiveViewers` unresolved.

- [ ] **Step 3: Write minimal implementation**

```kotlin
package com.usbcamera.capture.usb_capture

import java.util.concurrent.atomic.AtomicInteger

internal class LanLiveViewers {
    private val n = AtomicInteger(0)

    fun add(): Int = n.incrementAndGet()

    fun remove(): Int {
        while (true) {
            val cur = n.get()
            if (cur <= 0) return 0
            if (n.compareAndSet(cur, cur - 1)) return cur - 1
        }
    }

    fun count(): Int = n.get()

    fun active(streaming: Boolean, mjpeg: Boolean): Boolean =
        count() > 0 && !streaming && mjpeg
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: same gradle command as Step 2.

Expected: BUILD SUCCESSFUL, both tests PASSED.

---

### Task 2: JPEG kind wins over NV21 size heuristics

**Files:**
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/JpegFrameFormat.kt`
- Modify: `packages/usb_capture/android/src/test/kotlin/com/usbcamera/capture/usb_capture/JpegFrameFormatTest.kt`
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/MjpegJpeg.kt` (add `hasSoi`)

**Interfaces:**
- Produces: `MjpegJpeg.hasSoi(bytes: ByteArray): Boolean`
- Produces: `JpegFrameFormat.Kind.Jpeg`
- Produces: `JpegFrameFormat.kind(frame: ByteArray, width: Int, height: Int): Kind` — SOI first, then existing size heuristics
- Keep: `kind(bytes: Int, width: Int, height: Int)` for NV21/RGBX-only tests (no JPEG)

- [ ] **Step 1: Write the failing tests** (append to `JpegFrameFormatTest.kt` and `MjpegJpegTest.kt`)

```kotlin
@Test
fun hasSoiDetectsJpeg() {
    assertTrue(MjpegJpeg.hasSoi(byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x01)))
    assertFalse(MjpegJpeg.hasSoi(byteArrayOf(0x00, 0x01)))
}

@Test
fun jpegWinsEvenWhenSmallerThanNv21() {
    val jpeg = ByteArray(200_000)
    jpeg[0] = 0xFF.toByte()
    jpeg[1] = 0xD8.toByte()
    assertEquals(JpegFrameFormat.Kind.Jpeg, JpegFrameFormat.kind(jpeg, 1920, 1080))
}
```

Keep existing `classifiesFullHdBuffers` assertions.

- [ ] **Step 2: Run tests — expect FAIL** (`hasSoi` / `Kind.Jpeg` unresolved, or kind still `Unknown` for 200_000-byte JPEG).

Run: `(cd android && ./gradlew :usb_capture:testDebugUnitTest --tests com.usbcamera.capture.usb_capture.JpegFrameFormatTest --tests com.usbcamera.capture.usb_capture.MjpegJpegTest)`

- [ ] **Step 3: Implement**

In `MjpegJpeg.kt`, expose SOI without copying:

```kotlin
fun hasSoi(bytes: ByteArray): Boolean = soiIndex(bytes) >= 0
```

In `JpegFrameFormat.kt`:

```kotlin
enum class Kind { Jpeg, Rgbx, Nv21, Unknown }

fun kind(frame: ByteArray, width: Int, height: Int): Kind {
    if (MjpegJpeg.hasSoi(frame)) return Kind.Jpeg
    return kind(frame.size, width, height)
}
```

Leave `kind(bytes, width, height)` as the size heuristic (Rgbx / Nv21 / Unknown).

- [ ] **Step 4: Re-run Step 2 tests — PASS**, including the original full-HD NV21/RGBX cases.

---

### Task 3: Publish JPEG in `offerFrame` without the encode worker

**Files:**
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/JpegLiveEncoder.kt`
- Test: `packages/usb_capture/android/src/test/kotlin/com/usbcamera/capture/usb_capture/JpegLiveEncoderTest.kt`

**Interfaces:**
- Consumes: `MjpegJpeg.extract`, `MjpegHub.publish`
- Produces: `JpegLiveEncoder.offerFrame` publishes JPEG immediately even if `start()` was never called; non-JPEG still uses the existing worker path only when `running`

- [ ] **Step 1: Failing test**

```kotlin
package com.usbcamera.capture.usb_capture

import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertNull

internal class JpegLiveEncoderTest {
    @Test
    fun offerFramePublishesJpegWithoutStart() {
        val hub = MjpegHub()
        val encoder = JpegLiveEncoder(hub, previewView = { null })
        val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0x01, 0x02)
        encoder.offerFrame(jpeg)
        val got = hub.awaitNext(0, 200)
        assertContentEquals(jpeg, got?.second)
    }

    @Test
    fun offerFrameDropsNonJpegWhenNotRunning() {
        val hub = MjpegHub()
        val encoder = JpegLiveEncoder(hub, previewView = { null })
        encoder.offerFrame(ByteArray(1920 * 1080 * 3 / 2))
        assertNull(hub.awaitNext(0, 50))
    }
}
```

- [ ] **Step 2: Run** `(cd android && ./gradlew :usb_capture:testDebugUnitTest --tests com.usbcamera.capture.usb_capture.JpegLiveEncoderTest)` — FAIL because `offerFrame` waits for the worker / size / NV21 compress.

- [ ] **Step 3: At the top of `offerFrame`, passthrough JPEG**

```kotlin
fun offerFrame(frame: ByteArray) {
    if (frame.isEmpty()) return
    offered.incrementAndGet()
    val jpeg = MjpegJpeg.extract(frame)
    if (jpeg != null) {
        hub.publish(jpeg)
        published.incrementAndGet()
        lastError.set("")
        return
    }
    // existing NV21/RGBX buffer + notify worker
}
```

Do not call `publishFromView` for LAN passthrough (worker may stay unused). Do not start the worker from this task.

- [ ] **Step 4: Re-run JpegLiveEncoderTest — PASS.**

---

### Task 4: Stream close decrements viewers; 30s stale close

**Files:**
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/MjpegPart.kt` (`MjpegMultipartStream`)
- Modify: `packages/usb_capture/android/src/test/kotlin/com/usbcamera/capture/usb_capture/MjpegJpegTest.kt` (`MjpegMultipartStreamTest`)

**Interfaces:**
- Produces: `MjpegMultipartStream(hub, onClosed: () -> Unit = {}, idleMs: Long = 30_000L)`
- Produces: `close()` runs `onClosed` **once**
- Produces: each `read` / `awaitNext` loop updates `touchedAt`; if `now - touchedAt > idleMs` **and** this `read` is not currently waiting on the hub, `close()` and return `-1`

Idle 30s (spec): a stream is stale only when **no `read()` call is in flight** for 30s (tab gone, NanoHTTPD stopped pumping). Refresh `touchedAt` at the **entry** of `read()` and at every `awaitNext` loop iteration so waiting for the first JPEG is not stale. `close()` still runs `onClosed` once.

If NanoHTTPD can sit on a stream without calling `read` after the client drops, keep a weak set of open streams on `LanLiveViewers` (`fun track(stream: MjpegMultipartStream)` / untrack in `onClosed`) and every 5s drop streams whose `touchedAt` is older than 30s by calling `stream.close()`. Do **not** treat “awaitNext timed out while still inside `read()`” as stale.

- [ ] **Step 1: Extend `MjpegMultipartStreamTest`**

```kotlin
@Test
fun closeInvokesOnClosedOnce() {
    val hub = MjpegHub()
    var n = 0
    val stream = MjpegMultipartStream(hub, onClosed = { n++ })
    stream.close()
    stream.close()
    assertEquals(1, n)
}
```

Keep `readsLatestJpegAsMultipart` working with the new defaulted constructor.

- [ ] **Step 2: Run MjpegMultipartStreamTest — FAIL on extra constructor / close.**

- [ ] **Step 3: Implement**

```kotlin
class MjpegMultipartStream(
    private val hub: MjpegHub,
    private val onClosed: () -> Unit = {},
    private val boundary: String = MjpegPart.BOUNDARY,
) : InputStream() {
    private val closed = java.util.concurrent.atomic.AtomicBoolean(false)
    // existing buffer fields

    override fun close() {
        if (closed.compareAndSet(false, true)) {
            onClosed()
        }
        super.close()
    }
}
```

In `read`, if `closed.get()` return `-1`. After `hub.close()` path already returns `-1`; also `close()` the stream so `onClosed` runs.

- [ ] **Step 4: Tests PASS.**

---

### Task 5: HTTP `/live.mjpeg` drives `LanLiveViewers`

**Files:**
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/LanHttpServer.kt`
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/CaptureEngine.kt` (constructor wiring only: pass viewers + `onViewersChanged`)

**Interfaces:**
- Consumes: `LanLiveViewers.add/remove`, `MjpegMultipartStream(hub, onClosed)`
- Produces: `LanHttpServer(..., liveViewers: LanLiveViewers, onLiveViewersChanged: () -> Unit)`
- Produces: `serveLiveMjpeg` calls `liveViewers.add()` then `onLiveViewersChanged()` before returning the chunked body; `onClosed` calls `remove()` then `onLiveViewersChanged()`

- [ ] **Step 1:** No new unit test file required if Task 1 and 4 pass. Manually confirm `ServerImpl` `GET /live.mjpeg` constructs:

```kotlin
path == "/live.mjpeg" -> serveLiveMjpeg()

private fun serveLiveMjpeg(): Response {
    val hub = mjpegHub()
        ?: return newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "")
    liveViewers.add()
    onLiveViewersChanged()
    val stream = MjpegMultipartStream(hub) {
        liveViewers.remove()
        onLiveViewersChanged()
    }
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
```

Update `CaptureEngine` HTTP start site that currently builds `LanHttpServer(...)` to pass `lanLiveViewers` and `{ refreshLanLive() }` (implemented in Task 6; in this task a no-op lambda is OK if compile requires it — prefer calling the real method added in Task 6 in the same change set if you do Tasks 5–6 together).

- [ ] **Step 2:** `stop()` on the HTTP server must not leak counts. In `LanHttpServer.stop()`, `mjpegHub.close()` already ends streams; `close()` on each stream must run. After stop, if `count() != 0`, drain with `while (remove() > 0) {}` then `onLiveViewersChanged()`.

- [ ] **Step 3:** Compile: `(cd android && ./gradlew :usb_capture:testDebugUnitTest --tests com.usbcamera.capture.usb_capture.MjpegMultipartStreamTest --tests com.usbcamera.capture.usb_capture.LanLiveViewersTest)`

---

### Task 6: Engine RAW callback, surface mutex, `lanLiveBusy` event

**Files:**
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/CaptureEngine.kt`
- Modify: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/CaptureRuntimePolicy.kt` only if a new flag is required — **do not** add one; `sessionOpen` already blocks `engine.stop()`

**Interfaces:**
- Consumes: `LanLiveViewers.active(streaming, previewMjpeg)`, `UVCCamera.PIXEL_FORMAT_RAW`, `JpegLiveEncoder.offerFrame`
- Produces: `refreshLanLive()` 
- Produces: event `mapOf("type" to "lanLiveBusy", "busy" to Boolean)` when `busy` actually changes
- Produces: `attachPreview` skips `addSurface` while `lanLiveBusy == true` (keep `previewView` reference)
- Produces: `detachPreview` unchanged

`refreshLiveFrames()` becomes:

```kotlin
private fun refreshLiveFrames() {
    val helper = helper
    val lanActive = lanLiveViewers.active(streaming = streaming, mjpeg = previewMjpeg)
    if (lanActive != lanLiveBusy) {
        lanLiveBusy = lanActive
        emit(mapOf("type" to "lanLiveBusy", "busy" to lanActive))
        if (lanActive) {
            previewSurface?.let { helper?.removeSurface(it) }
            previewSurface = null
        } else {
            attachSurfaceIfReady()
        }
    }
    if (helper == null) return
    when {
        streaming -> helper.setFrameCallback(livePreviewCallback, UVCCamera.PIXEL_FORMAT_NV21)
        lanActive -> helper.setFrameCallback(livePreviewCallback, UVCCamera.PIXEL_FORMAT_RAW)
        else -> try {
            helper.setFrameCallback(null, 0)
        } catch (_: Exception) {
        }
    }
    if (!lanActive) {
        jpegLive.stop()
    }
}
```

`livePreviewCallback`:

```kotlin
if (streaming) {
    streamSession?.queueNv21(frame)
}
if (lanLiveViewers.active(streaming = streaming, mjpeg = previewMjpeg)) {
    jpegLive.offerFrame(copyFrame(frame))
}
```

Do **not** call `jpegLive.start()` from `refreshLiveFrames` / `httpServing`. Do **not** `jpegLive.kick()` from `onPreviewFrame` for LAN (passthrough does not screenshot the view).

`attachPreview`:

```kotlin
fun attachPreview(view: TextureView) {
    previewView = view
    if (!lanLiveBusy) attachSurfaceIfReady()
}
```

When HTTP server starts with zero viewers: no RAW callback (today it starts `jpegLive` whenever `httpServing` — remove that).

When streaming starts: existing NV21 path; `active(..., streaming=true)` is false so phone surface returns even if the browser still holds `/live.mjpeg`.

- [ ] **Step 1:** After edits, run `(cd android && ./gradlew :usb_capture:testDebugUnitTest)` — existing `CaptureRuntimePolicyTest`, `Mjpeg*` tests still PASS.

- [ ] **Step 2:** Confirm `PIXEL_FORMAT_RAW` exists on `UVCCamera` in this UVCAndroid version. If the constant is missing, use the library’s equivalent raw/MJPEG callback format used for unconverted frames (same intent: JPEG bytes in the buffer, not NV21).

---

### Task 7: Dart event + `SessionState.lanLiveBusy`

**Files:**
- Modify: `packages/usb_capture/lib/src/capture_event.dart`
- Modify: `packages/usb_capture/lib/src/session_state.dart`
- Modify: `packages/usb_capture/test/capture_logic_test.dart`
- Modify: `packages/usb_capture/test/usb_capture_test.dart` only if event mapping tests live there

**Interfaces:**
- Produces: `CaptureEventType.lanLiveBusy`
- Produces: `CaptureEvent.busy` (`bool`, default `false`) from map key `'busy'`
- Produces: `SessionState.lanLiveBusy` (default `false`)
- Produces: `previewActive => sessionOpen && previewEnabled && !lanLiveBusy`
- `togglePreview` still only flips `previewEnabled`

- [ ] **Step 1: Failing tests in `capture_logic_test.dart`**

```dart
test('lanLiveBusy event maps busy flag', () {
  expect(
    CaptureEvent.fromMap({'type': 'lanLiveBusy', 'busy': true}).type,
    CaptureEventType.lanLiveBusy,
  );
  expect(
    CaptureEvent.fromMap({'type': 'lanLiveBusy', 'busy': true}).busy,
    isTrue,
  );
});

test('lanLiveBusy hides preview without clearing previewEnabled', () {
  const open = SessionState(sessionOpen: true, previewEnabled: true);
  expect(open.previewActive, isTrue);
  final busy = open.copyWith(lanLiveBusy: true);
  expect(busy.previewEnabled, isTrue);
  expect(busy.previewActive, isFalse);
  expect(busy.copyWith(lanLiveBusy: false).previewActive, isTrue);
});
```

Add `busy` to `CaptureEvent` constructor/fromMap. Add `lanLiveBusy` to `SessionState` constructor, field, `copyWith`.

- [ ] **Step 2:** `cd packages/usb_capture && flutter test test` — FAIL on missing type/field.

- [ ] **Step 3: Implement fields as above.**

- [ ] **Step 4:** Same `flutter test test` — PASS, including existing preview-off recording tests (`previewActive` still false when `previewEnabled` is false).

---

### Task 8: Phone UI copy + widget

**Files:**
- Modify: `lib/l10n/app_en.arb`, `app_zh.arb`, `app_zh_Hant.arb`, `app_ja.arb`, `app_ko.arb`
- Modify: `lib/preview_page.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `CaptureEventType.lanLiveBusy`, `SessionState.lanLiveBusy`
- Produces: `previewLanLiveBusy` strings
- Produces: `_onEvent` sets `_session.copyWith(lanLiveBusy: event.busy)`
- Produces: preview stack: if `sessionOpen && previewEnabled && lanLiveBusy` show overlay text (same style as `_PreviewOffState`); do not build `UsbCapturePreview`
- `UsbCapturePreview` remains `if (_session.previewActive)` which is already false when busy

Copy:

| Locale | `previewLanLiveBusy` |
| --- | --- |
| en | Webpage is watching live preview |
| zh | 网页正在看现场 |
| zh_Hant | 網頁正在看現場 |
| ja | ウェブでライブを表示中 |
| ko | 웹페이지에서 라이브를 보는 중 |

- [ ] **Step 1: Failing widget test** (follow existing `localizedApp` + `_FakePlatform` + open a device so `sessionOpen` is true). After the page shows `UsbCapturePreview`, push:

```dart
fake.eventsController.add(
  const CaptureEvent(type: CaptureEventType.lanLiveBusy, busy: true),
);
await tester.pump();
expect(find.byType(UsbCapturePreview), findsNothing);
expect(find.text('Webpage is watching live preview'), findsOneWidget);
fake.eventsController.add(
  const CaptureEvent(type: CaptureEventType.lanLiveBusy, busy: false),
);
await tester.pump();
expect(find.byType(UsbCapturePreview), findsOneWidget);
```

Reuse the pattern in `turning lan off then tapping preview keeps the preview widget` for opening a session (copy that test’s setup: devices list, pump, connect if needed). If that test relies on auto-open, match it so `sessionOpen` is true before the event.

Keep the existing LAN-off black-screen regression test unchanged.

- [ ] **Step 2:** `flutter test test/widget_test.dart` — FAIL missing l10n getter / event branch.

- [ ] **Step 3: ARB + `_onEvent` + overlay widget.** Run `flutter gen-l10n` if generated files are not updated by `flutter test`.

Preview stack addition next to `_PreviewOffState`:

```dart
if (_session.sessionOpen &&
    _session.previewEnabled &&
    _session.lanLiveBusy)
  _LanLiveBusyState(television: _tv),
```

`_LanLiveBusyState` clones `_PreviewOffState` but uses `previewLanLiveBusy`.

- [ ] **Step 4:** `flutter test` and `(cd packages/usb_capture && flutter test test)` PASS.

---

### Task 9: Webpage tears down `/live.mjpeg`; OpenSpec

**Files:**
- Modify: `packages/usb_capture/android/src/main/assets/lan_http/index.html`
- Modify: `openspec/specs/lan-http-playback/spec.md`
- Modify: `docs/superpowers/specs/2026-09-17-lan-mjpeg-passthrough-design.md` (one sentence: trigger is viewers, not merely HTTP server on)

**Interfaces:**
- `stopLiveStream` already does `liveImg.removeAttribute('src')`. Also `window.addEventListener('pagehide', stopLiveStream)` so closing the tab drops the reader.
- Spec: Live MJPEG SHALL copy UVC JPEG (`PIXEL_FORMAT_RAW`) while at least one `/live.mjpeg` reader exists and ingest is idle. The Android preview surface SHALL detach for that interval and SHALL return when readers drop to zero or ingest starts. Live SHALL NOT NV21-recompress. `previewEnabled` SHALL NOT change.

- [ ] **Step 1:** In `index.html` after live helpers:

```javascript
window.addEventListener('pagehide', function () {
  stopLivePolling();
  stopLiveStream();
});
```

- [ ] **Step 2:** Update `lan-http-playback` requirement “Live SHALL NOT include audio” stays. Add scenarios:

  - WHEN a browser turns 实时预览 on, THEN the phone preview widget is hidden and `/live.mjpeg` is raw JPEG.
  - WHEN the browser turns it off or the last `/live.mjpeg` connection closes, THEN the phone preview returns if `previewEnabled`.
  - WHEN RTMP ingest is active, THEN LAN live pauses and phone preview may show.

- [ ] **Step 3:** `flutter test` + `(cd android && ./gradlew :usb_capture:testDebugUnitTest)` both PASS.

---

## Hardware check (after Task 9, not a code task)

On `83da96a0321` if attached: LAN on, webpage live off → phone preview works. Webpage live on → phone shows 网页正在看现场, browser picture is sharp. Close the tab → phone preview returns and is tappable. Stream on → LAN overlay paused, phone preview back. LAN off then tap preview → not a black screen.

---

## Spec coverage

| Spec item | Task |
| --- | --- |
| Viewer count, not negative, two browsers | 1, 5 |
| `active` = viewers + MJPEG + not streaming | 1, 6 |
| RAW JPEG SOI publish, no NV21 recompress, no TextureView shot | 2, 3, 6 |
| Surface detach / restore, `previewEnabled` unchanged | 6, 7, 8 |
| `lanLiveBusy` UI five locales | 8 |
| No callback / no encode thread without viewers | 6 |
| RTMP pauses LAN, restores phone preview | 6 |
| `close()` / tab `pagehide` | 4, 9 |
| Non-MJPEG no mutex | 1 `active(..., mjpeg=false)`, 6 |
| `sessionOpen` no `engine.stop()` | 6 (policy unchanged) |
| OpenSpec + old passthrough trigger correction | 9 |
| CH9329 / LAN audio | out of scope |
