## Context

操作员已在 Android 上本地分段录像，并可选用 RTMP 推流。录像文件走现有片库（相册 / 影片 / 下载 / 自定义文件夹）。推流使用独立 `MediaCodec` surface 与 USB PCM AAC，与文件 mux 分离。本变更在**不依赖采集卡打开**的前提下提供局域网 HTTP 访问：成片 VOD 随时可用；现场 HLS 需 UVC 会话与编码器。

## Goals / Non-Goals

**Goals:**

- Android 将 `0.0.0.0:8080+` 上的 NanoHTTPD 提供 `/` 首页、`/live.m3u8` 现场 HLS、`/vod/<id>` Range MP4。
- 设置开关持久化；有 IPv4 时显示可复制 URL；无网可读提示。
- 不插采集卡可浏览并播放已录 MP4；采集卡连上后首页现场区几秒内出声画。
- 与本地分段录像、RTMP 推流可同时开；编码器只保留一路 surface（有 RTMP 则 tee 到 HLS）。
- 开关开着时 FGS 保活；拔卡停现场不停 HTTP/VOD。
- iPad 无开关；插件返回 `httpUnsupported`。

**Non-Goals:**

- iPad 作 HTTP 服务器；公网 / 穿透；密码；HTTPS；DLNA / AirPlay。
- 应用内嵌 WebView 当播放器。
- ffmpeg-kit 全量引入。

## Decisions

### 1. NanoHTTPD 本机 HTTP 服务

- **选择**：`org.nanohttpd:nanohttpd:2.3.1`；绑定 `0.0.0.0`；从 8080 起最多尝试 10 个端口。
- **理由**：轻量、纯 Java/Kotlin，适合 APK 内嵌静态页与 API。
- **备选**：Android `HttpServer`（API 26+）。TV 盒子版本碎片化，NanoHTTPD 更稳。

### 2. 现场 HLS，成片 Range MP4

- **选择**：现场 MPEG-TS 切片 + 滑动窗口 m3u8（约 2s/片，保留 6 片）；成片 `GET /vod/<id>` 支持 `Range`，`video/mp4`。
- **理由**：浏览器 hls.js 播现场；`<video>` 或同一页 JS 播 MP4；与 spec 路径一致。
- **备选**：WebRTC / LL-HLS。复杂度高，延迟要求仅「数秒」。

### 3. 与 RTMP 共用编码器（tee 或 HLS-only）

- **选择**：`if (rtmp && http) -> 现有 RtmpStreamSession + HLS 回调`；`else if (http && camera) -> startEncodersOnly + HLS`；仅保留一路 `MediaCodec` surface。
- **理由**：避免多 surface 掉帧；对齐 spec「与 RTMP 共用同一路 H.264/AAC」。
- **备选**：HLS 独立第二路编码。耗电与部分采集卡兼容性差。

### 4. 开关与 FGS 不依赖采集卡

- **选择**：`startHttpServer` 不要求 camera open；`httpServing` 时 `releaseIfIdle` 不释放；FGS 在录像、推流或 HTTP 服务任一存在时保持；通知文案含「局域网播放」。
- **理由**：无卡 VOD 是核心验收项；锁屏后仍能访问。
- **备选**：仅 session open 时启服务。违背无卡看片。

### 5. IPv4 与错误映射

- **选择**：`ConnectivityManager` / `LinkProperties` 收集 IPv4；`LanHttpUrl.pickIpv4` 过滤 loopback；无 IPv4 → `streamFailed` / `httpNoNetwork`；绑定失败 → `httpBindFailed`；iOS → `httpUnsupported`（复用 `streamFailed` details，避免大面积 enum 变更）。
- **理由**：与实现计划一致；中文可读文案。

## Risks / Trade-offs

- [同一 Wi-Fi 无鉴权] → 设置里一句话说明未加密；非目标不做密码。
- [HLS 延迟数秒] → 2s 切片 + 滑动窗口；可接受。
- [端口被占] → 递增端口并更新界面 URL。
- [文件已删] → 该条 404，不影响列表其它条目。
- [双路 tee + 录像耗电] → 已接受；FGS + wakelock 与推流一致。

## Migration Plan

无数据迁移。新偏好键 `operator.httpLanEnabled` 默认 `false`；升级后开关保持关，行为与现网一致。

**Archive order:** When archiving `lan-http-playback`, merge the `operator-prefs` delta with the pending `android-rtmp-stream` change first so RTMP fields, stream-key no-log rule, and `operator.httpLanEnabled` all land in one MODIFIED requirement—avoid a second archive overwriting RTMP or LAN keys.

## Open Questions

无。
