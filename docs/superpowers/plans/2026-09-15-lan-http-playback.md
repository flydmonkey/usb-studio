# 局域网 HTTP 播放 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Android 设置打开「局域网播放」后，同一 Wi-Fi 的浏览器访问 `http://手机IP:端口/` 能看已录 MP4；采集卡连上后同一页还能看带声音的现场（HLS）。

**Architecture:** 本机 NanoHTTPD 提供首页、HLS 切片和 Range MP4。开关不依赖采集卡。现场 H.264+AAC 与现有 `RtmpStreamSession` 编码器共用（有 RTMP 则 tee 到 HLS）。开关开着时 `CaptureRecordService` 保活。

**Tech Stack:** Flutter 设置 + `OperatorPrefs`；插件 `startHttpServer` / `stopHttpServer`；Android NanoHTTPD、MPEG-TS 切片、hls.js 静态页；iOS 返回不支持。

## Global Constraints

- Spec: `docs/superpowers/specs/2026-09-15-lan-http-playback-design.md`
- Android 先做（红米 `83da96a0321`）；iPad 无开关、插件返回 `httpUnsupported`
- 默认关；不设密码；不做外网、HTTPS、DLNA
- 不插采集卡也能播成片；拔卡只停现场
- 可与本地录像、RTMP 同时开；现场编码进行中锁定格式/画质（与推流相同 `streamInProgress`）
- 安装：`adb -s 83da96a0321 install -r build/app/outputs/flutter-apk/app-release.apk`
- 未经用户明确要求不要 git commit
- 回复中文

## File map

- Create: `openspec/changes/lan-http-playback/`（proposal / design / specs / tasks）
- Create: `packages/usb_capture/lib/src/lan_http_url.dart`
- Create: `packages/usb_capture/android/src/main/kotlin/.../LanHttpUrl.kt`
- Create: `packages/usb_capture/android/src/main/kotlin/.../LanHttpServer.kt`
- Create: `packages/usb_capture/android/src/main/kotlin/.../HttpRange.kt`
- Create: `packages/usb_capture/android/src/main/kotlin/.../HlsWindow.kt`
- Create: `packages/usb_capture/android/src/main/kotlin/.../MpegTsMuxer.kt`
- Create: `packages/usb_capture/android/src/main/assets/lan_http/index.html`
- Create: `packages/usb_capture/android/src/main/assets/lan_http/hls.min.js`（构建时从官方 min 拷入，或 HTML 用 jsDelivr；优先 assets 以免播放端断网）
- Create: Kotlin 单测 `LanHttpUrlTest.kt` `HttpRangeTest.kt` `HlsWindowTest.kt`
- Modify: `operator_prefs.dart`, `platform_profile.dart`, `capture_error.dart`, plugin Dart/Android/iOS, `CaptureEngine.kt`, `CaptureRecordService.kt`, `CaptureRuntime.kt`, `preview_page.dart`, widget / capture_logic tests, `AndroidManifest.xml`, plugin `build.gradle.kts`

---

### Task 1: OpenSpec 变更目录

**Files:**
- Create: `openspec/changes/lan-http-playback/proposal.md`
- Create: `openspec/changes/lan-http-playback/design.md`
- Create: `openspec/changes/lan-http-playback/specs/lan-http-playback/spec.md`
- Create: `openspec/changes/lan-http-playback/specs/operator-prefs/spec.md`
- Create: `openspec/changes/lan-http-playback/tasks.md`

**Interfaces:**
- Consumes: 已批准 spec
- Produces: apply-ready OpenSpec change `lan-http-playback`

- [ ] **Step 1:** `openspec new change "lan-http-playback"`
- [ ] **Step 2:** 按 spec 填 proposal / design / delta specs / tasks（开关、无卡 VOD、HLS 现场、FGS、iPad 不做）
- [ ] **Step 3:** `openspec status --change lan-http-playback` 显示 tasks 可 apply

---

### Task 2: URL 与错误文案（纯 Dart / Kotlin）

**Files:**
- Create: `packages/usb_capture/lib/src/lan_http_url.dart`
- Create: `packages/usb_capture/android/src/main/kotlin/com/usbcamera/capture/usb_capture/LanHttpUrl.kt`
- Create: `packages/usb_capture/android/src/test/kotlin/com/usbcamera/capture/usb_capture/LanHttpUrlTest.kt`
- Modify: `packages/usb_capture/lib/src/capture_error.dart`
- Modify: `packages/usb_capture/lib/usb_capture.dart`（export）
- Modify: `packages/usb_capture/test/capture_logic_test.dart`

**Interfaces:**
- Produces:
  - `LanHttpUrl.display({required String ipv4, required int port})` → `http://192.168.1.8:8080/`
  - `LanHttpUrl.pickIpv4(List<String> addresses)` → 第一个非 loopback 的 IPv4，没有则 `null`
  - `CaptureErrorCode.streamFailed` 增加 details：`httpUnsupported`、`httpBindFailed`、`httpNoNetwork`（不新开 enum，复用 streamFailed 以免大面积 switch）

- [ ] **Step 1: Write the failing test** in `capture_logic_test.dart`:

```dart
test('builds lan http display url and picks ipv4', () {
  expect(
    LanHttpUrl.display(ipv4: '192.168.1.8', port: 8080),
    'http://192.168.1.8:8080/',
  );
  expect(
    LanHttpUrl.pickIpv4(['127.0.0.1', '192.168.1.8', '::1']),
    '192.168.1.8',
  );
  expect(LanHttpUrl.pickIpv4(['127.0.0.1']), isNull);
  expect(
    CaptureError.fromCode('streamFailed', details: 'httpNoNetwork').message,
    contains('Wi-Fi'),
  );
});
```

- [ ] **Step 2:** `flutter test packages/usb_capture/test/capture_logic_test.dart` — FAIL（`LanHttpUrl` 未定义）
- [ ] **Step 3: Implement**

```dart
class LanHttpUrl {
  static String display({required String ipv4, required int port}) {
    return 'http://$ipv4:$port/';
  }

  static String? pickIpv4(Iterable<String> addresses) {
    for (final raw in addresses) {
      final host = raw.trim();
      if (host.isEmpty || host == '127.0.0.1' || host == '0.0.0.0') continue;
      if (host.contains(':')) continue;
      final parts = host.split('.');
      if (parts.length != 4) continue;
      if (parts.every((p) => int.tryParse(p) != null)) return host;
    }
    return null;
  }
}
```

Kotlin `LanHttpUrl` 同样函数，供原生绑定端口后拼 URL。错误文案：

- `httpUnsupported` → `当前平台不支持局域网播放。`
- `httpBindFailed` → `无法打开局域网播放端口。`
- `httpNoNetwork` → `请先连接 Wi-Fi。`

- [ ] **Step 4:** 同一条 flutter test + `./gradlew :usb_capture:testDebugUnitTest --tests ...LanHttpUrlTest` PASS
- [ ] **Step 5:** 不要 commit

---

### Task 3: 偏好、平台能力、插件方法（先假实现）

**Files:**
- Modify: `lib/operator_prefs.dart` 增加 `httpLanEnabled`（bool，默认 `false`，key `operator.httpLanEnabled`）
- Modify: `packages/usb_capture/lib/src/platform_profile.dart` 增加 `httpLanSupported`（fromMap 默认 false）
- Modify: `usb_capture_platform_interface.dart` / `usb_capture_method_channel.dart` / `usb_capture.dart`
- Modify: `packages/usb_capture/test/usb_capture_test.dart` Mock
- Modify: `test/widget_test.dart` `_FakePlatform`
- Modify: Android `platformProfile()` → `httpLanSupported: true`；iOS `false`
- Modify: iOS `UsbCapturePlugin.swift`：`startHttpServer` → `streamFailed`/`httpUnsupported`；`stopHttpServer` no-op；`httpServerStatus` 返回 `{running: false}`

**Interfaces:**
- Produces:
  - `Future<Map<String, dynamic>> startHttpServer()` 成功 map：`url` `String`、`port` `int`、`running` `true`
  - `Future<void> stopHttpServer()`
  - `Future<Map<String, dynamic>> httpServerStatus()`：`running` `bool`、`url` `String?`

Method channel 名：`startHttpServer`、`stopHttpServer`、`httpServerStatus`。无参数。

- [ ] **Step 1:** 单测 `CaptureStatus` 风格：`PlatformProfile.fromMap({'httpLanSupported': true}).httpLanSupported == true`；prefs roundtrip 用 `SharedPreferences.setMockInitialValues`
- [ ] **Step 2:** 测试 FAIL
- [ ] **Step 3:** 实现 Dart + iOS stub + Android profile 字段；Android 三个方法可先 `TODO` 抛 `httpBindFailed` 直到 Task 4
- [ ] **Step 4:** `flutter test` 相关文件 PASS
- [ ] **Step 5:** 不要 commit

---

### Task 4: HTTP 服务 — 首页 + Range VOD（无现场）

**Files:**
- Create: `HttpRange.kt` + `HttpRangeTest.kt`
- Create: `LanHttpServer.kt`
- Modify: `packages/usb_capture/android/build.gradle.kts` 增加 `implementation("org.nanohttpd:nanohttpd:2.3.1")`
- Modify: `UsbCapturePlugin.kt` 调 `CaptureEngine.startHttpServer()`（**不要求** camera open）
- Modify: `CaptureEngine.kt` / `CaptureRuntime.kt`：`httpServing` 时 `releaseIfIdle` 不释放；`recordingHud()` 在 `httpServing` 时非 null
- Modify: `CaptureRecordService` 通知文案增加「局域网播放」；Android 14 FGS 增加 `mediaPlayback`；manifest 增加 `FOREGROUND_SERVICE_MEDIA_PLAYBACK`、`ACCESS_NETWORK_STATE`、`ACCESS_WIFI_STATE`
- Create assets: `index.html` 先只列录像（现场区显示「等待采集卡」）；`GET /api/recordings` JSON
- Modify: `RecordingLibrary` 增加 `fun openStream(context, id): Pair<Uri, String>` 或 `inputStream + size` 供服务器读（id 与片库相同）

**Interfaces:**
- Consumes: `RecordingLibrary.list` 的 `id`/`name`/`bytes`
- Produces:
  - `HttpRange.parse(header: String?, total: Long): HttpRange?` 其中 `data class HttpRange(val start: Long, val end: Long)`（含两端，206）
  - `LanHttpServer.start(preferredPort: Int = 8080): Int` 实际端口
  - `LanHttpServer.stop()`
  - 路由：`GET /` HTML；`GET /api/recordings` → `[{id,name,bytes}]`；`GET /vod/{url-encoded-id}` `video/mp4` + Range

`HttpRange.parse` 规则：无 header → 整文件 200；`bytes=0-499` → start/end；`bytes=500-` → 到 EOF；非法 → null 当整文件。

- [ ] **Step 1: Write failing Kotlin test**

```kotlin
@Test
fun parsesClosedRange() {
    val r = HttpRange.parse("bytes=0-499", 1000)!!
    assertEquals(0, r.start)
    assertEquals(499, r.end)
}
```

- [ ] **Step 2:** 跑测试 FAIL
- [ ] **Step 3:** 实现 `HttpRange` + `LanHttpServer`：从 8080 起尝试最多 10 个端口；`WifiManager`/`LinkProperties` 收集 IPv4 后 `LanHttpUrl.pickIpv4`。`startHttpServer` 返回 display URL。首页 JS `fetch('/api/recordings')` 后渲染 `<a>` / `<video src="/vod/...">`。
- [ ] **Step 4:** Kotlin 单测 PASS；`flutter test` PASS
- [ ] **Step 5:** 不要 commit

IPv4 采集（Android）：

```kotlin
fun ipv4Addresses(context: Context): List<String> {
    val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    val lp = cm.getLinkProperties(cm.activeNetwork) ?: return emptyList()
    return lp.linkAddresses.mapNotNull { addr ->
        val host = addr.address.hostAddress ?: return@mapNotNull null
        if (addr.address is java.net.Inet4Address) host else null
    }
}
```

无 IPv4 时 `throw CaptureException("streamFailed", "httpNoNetwork")`。

---

### Task 5: 设置 UI 与开关生命周期

**Files:**
- Modify: `lib/preview_page.dart` `_SettingsSheet`：在「推流」旁或新节「局域网播放」
  - `SwitchListTile` 标题「局域网播放」
  - 打开后显示 URL（可复制 `Clipboard.setData`）+ 一句「同一 Wi-Fi 下打开此地址即可播放；未加密」
  - 无网：`请先连接 Wi-Fi`
  - `httpLanSupported == false` 整节隐藏
- Modify: `_FakePlatform` 增加 `httpLanSupported: supported`、`startHttpServer` 记录
- Modify: `test/widget_test.dart`：Android fake 打开设置能看到开关；打开后出现 `http://`；iPhone `supported: false` 看不到开关

**Interfaces:**
- Consumes: `plugin.startHttpServer()` / `stopHttpServer()`、`OperatorPrefs.httpLanEnabled`
- Produces: 启动后 `_httpUrl` 存在 State 里；`_persist` 时若 `httpLanEnabled` 变 true 则 start，变 false 则 stop

- [ ] **Step 1:** widget 测试 FAIL（无「局域网播放」）
- [ ] **Step 2:** 实现开关；`initState` 若 prefs 已开则 bootstrap 后 `startHttpServer`（不需要 sessionOpen）
- [ ] **Step 3:** `flutter test test/widget_test.dart` PASS
- [ ] **Step 4:** 不要 commit

复制按钮用 `IconButton` tooltip「复制地址」。

---

### Task 6: HLS 窗口与 TS 切片（不接摄像头）

**Files:**
- Create: `HlsWindow.kt` — 内存环形缓冲，每片约 2s
- Create: `MpegTsMuxer.kt` — 把 Annex-B H.264 + ADTS AAC 写成 188 字节 TS（PAT/PMT/PES）
- Create: `HlsWindowTest.kt` — playlist 含 `#EXTM3U`、`#EXT-X-TARGETDURATION`、至少一片 `.ts`

**Interfaces:**
- Produces:
  - `HlsWindow.append(ts: ByteArray, durationSec: Double)`
  - `HlsWindow.playlist(base: String = ""): String`
  - `HlsWindow.segment(name: String): ByteArray?`
  - `MpegTsMuxer.addVideoAccessUnit(nal: ByteArray, ptsUs: Long, keyframe: Boolean)`
  - `MpegTsMuxer.addAudioAccessUnit(aacWithAdts: ByteArray, ptsUs: Long)`
  - `MpegTsMuxer.flushSegment(): ByteArray` 当累计时长 ≥ 2s 或关键帧边界

保留最近 6 片。playlist 滑动窗口，**不要** `#EXT-X-ENDLIST`（直播）。

- [ ] **Step 1:** `HlsWindowTest` FAIL
- [ ] **Step 2:** 实现窗口；muxer 可用最小实现（视频 PID 0x100，音频 0x101）。单测：空窗口 playlist 仍合法；append 后 `seg0.ts` 能取回。
- [ ] **Step 3:** Kotlin 测试 PASS
- [ ] **Step 4:** 不要 commit

`LanHttpServer` 增加：`GET /live.m3u8` → `application/vnd.apple.mpegurl`；`GET /live/segN.ts` → `video/mp2t`。无现场数据时 m3u8 仍返回带 `EXT-X-TARGETDURATION` 的空窗或 503，首页显示「等待采集卡」。

---

### Task 7: 把编码器接到 HLS（可与 RTMP tee）

**Files:**
- Modify: `RtmpStreamSession.kt` 增加可选 `onEncodedVideo: (ByteBuffer, MediaCodec.BufferInfo) -> Unit` 与 `onEncodedAudio`（在 `sendVideo`/`sendAudio` 之前拷贝）
- Modify: `CaptureEngine.kt`
  - `httpServing` true 且 camera open 且尚未有 streamSession 时，启动 **HLS-only** 会话：复用 `RtmpStreamSession.start` 的编码器路径，但 **不** `RtmpClient.connect`。更干净的做法：把编码器抽到 `AvEncodeSession`（preview surface + PCM），`RtmpStreamSession` 与 `HlsSink` 都订阅。若抽文件过大，则给 `RtmpStreamSession` 增加 `startEncodersOnly(...)`。
  - 有 RTMP 时只订阅回调写入 `HlsWindow`，不要第二路 `addSurface`
  - `setFormat`/`setRecordingQuality`：`httpLiveEncoding` 与 `streaming` 同样拒绝
  - `handleDisconnect` / `teardownSession`：停 HLS 编码，**不**停 `LanHttpServer`
- Modify: `index.html` 用 hls.js 挂 `#live` 到 `/live.m3u8`；卡未开时捕获错误显示「等待采集卡」

**Interfaces:**
- Consumes: Task 6 `HlsWindow` / `MpegTsMuxer`；现有 PCM `streamSession?.writePcm`
- Produces: 浏览器打开首页，采集卡连上后几秒内出声画

编码器只保留 **一路** MediaCodec surface：

```
if (rtmp && http) -> existing RtmpStreamSession + HLS callbacks
else if (http && camera) -> startEncodersOnly + HLS
else if (rtmp) -> unchanged
```

- [ ] **Step 1:** 给 `RtmpStreamSession` 增加 `var encodedSink: EncodedSink?`（video/audio buffers）。先单测 sink 在 drain 时被调用可用假 sink 计数（若难测 MediaCodec，用 `HlsWindow` 单测保证接上后 playlist 更新）。
- [ ] **Step 2:** 实现 tee 与 `startEncodersOnly`（复制 `start()` 去掉 `client.connect` / latch）。
- [ ] **Step 3:** 拔卡后 `/live.m3u8` 不再增长；`/api/recordings` 仍 200。
- [ ] **Step 4:** 不要 commit

首页现场标签：`<video id="live" controls autoplay muted playsinline></video>`（muted 才能自动播，页面注明点一下取消静音）。hls.js 从 assets `/hls.min.js` 加载。

---

### Task 8: 红米安装与验收

**Files:** 无新文件。OpenSpec `tasks.md` 勾选到 4.1；4.2 留真机。

- [ ] **Step 1:** `flutter test` 全绿
- [ ] **Step 2:** `cd android && ./gradlew :usb_capture:testDebugUnitTest` 相关测试绿
- [ ] **Step 3:** `flutter build apk --release`
- [ ] **Step 4:** `adb -s 83da96a0321 install -r build/app/outputs/flutter-apk/app-release.apk` 并启动
- [ ] **Step 5:** 对照 spec 验收清单（开关、无卡看片、插卡看现场、同时录像、关开关地址失效）

---

## Self-review

| Spec 要求 | Task |
| --- | --- |
| 开关默认关、持久化、显示可复制 URL | 3, 5 |
| 无采集卡看已录 | 4, 5 |
| 现场 HLS 带声音、延迟数秒 | 6, 7 |
| 与录像、RTMP 同时 | 7 |
| 没 Wi-Fi 提示 | 4, 5 |
| 端口占用换端口 | 4 |
| 拔卡只停现场 | 7 |
| FGS 锁屏仍可打开 | 4 |
| iPad 不做 | 3 |
| 红米 + 电脑浏览器 | 8 |
