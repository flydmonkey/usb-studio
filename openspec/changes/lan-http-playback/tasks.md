## 1. URL 与错误文案

- [x] 1.1 `LanHttpUrl.display` / `pickIpv4`（Dart + Kotlin）；`CaptureErrorCode.streamFailed` 增加 `httpUnsupported`、`httpBindFailed`、`httpNoNetwork` 文案
- [x] 1.2 Flutter / Kotlin 单测：URL 拼接、IPv4 选择、错误 message

## 2. 偏好、平台能力与插件 API

- [x] 2.1 `OperatorPrefs.httpLanEnabled`（默认 false）；`PlatformProfile.httpLanSupported`
- [x] 2.2 插件 `startHttpServer` / `stopHttpServer` / `httpServerStatus`；iOS 返回 `httpUnsupported`

## 3. HTTP 服务 — 首页与 Range VOD

- [x] 3.1 NanoHTTPD 依赖；`LanHttpServer` 绑定 `0.0.0.0:8080+`；IPv4 采集与无网失败
- [x] 3.2 路由 `GET /`、`GET /api/recordings`、`GET /vod/<id>`（Range）；assets 首页（无卡可列片库）
- [x] 3.3 `HttpRange.parse` 单测；`httpServing` 时 FGS 保活与 manifest 权限

## 4. 设置 UI 与开关生命周期

- [x] 4.1 设置「局域网播放」开关、可复制 URL、Wi-Fi 提示、未加密说明
- [x] 4.2 Widget 测试：Android 可见开关与 URL；iPad 隐藏；开关启停调插件

## 5. HLS 现场

- [x] 5.1 `HlsWindow` / `MpegTsMuxer`；路由 `/live.m3u8` 与 `/live/segN.ts`
- [x] 5.2 与 `RtmpStreamSession` tee 或 HLS-only 编码；拔卡停现场不停 VOD
- [x] 5.3 首页 hls.js 现场区；格式/画质在 live encode 时锁定

## 6. 验证

- [x] 6.1 `flutter test` 与 `:usb_capture:testDebugUnitTest` 通过
- [ ] 6.2 红米安装：无卡看片、插卡现场、与录像/RTMP 并存、关开关地址失效
