## Why

操作员要在同一 Wi-Fi 的电脑或平板上用浏览器看已录成片，并在采集卡连上后同一页面看带声音的现场画面，而不必依赖外网、密码或第三方播放器。现有应用只在本机预览和推流，没有局域网 HTTP 播放入口。

## What Changes

- 采集设置增加「局域网播放」开关（默认关）；偏好持久化；设置里用一句话说明同一 Wi-Fi 下任何人可打开地址观看（未加密）。
- 开关打开后 Android 本机起 HTTP 服务，绑定 `0.0.0.0`，优先端口 `8080`，占用则递增；界面显示可复制地址，例如 `http://192.168.1.8:8080/`。
- 有 Wi-Fi（或能拿到局域网 IPv4）才显示地址；否则提示先连网。
- 浏览器首页：上方现场 HLS 播放器（H.264 + AAC，延迟约数秒）；下方片库列表，点一条即播该 MP4（支持 HTTP Range）。
- **不插采集卡也能看已录成片**；现场画面需采集卡连上；拔卡只停现场，VOD 继续。
- 可与本地分段录像、RTMP 推流同时开；现场编码与 RTMP 共用同一路 H.264/AAC（有推流则 tee 到 HLS，没有则单独为 HLS 编码）；编码进行中格式/画质锁定。
- 开关开着时用前台通知保活，锁屏后同一局域网仍能打开地址。
- iPad 本阶段不做；不设密码、不做外网穿透、不做 HTTPS、DLNA / AirPlay。

## Capabilities

### New Capabilities

- `lan-http-playback`: Android 局域网 HTTP 服务、首页播放器、HLS 现场、Range VOD、与录像/推流并存及生命周期。

### Modified Capabilities

- `operator-prefs`: 持久化「局域网播放」开关（默认关）。

## Impact

- Flutter：设置开关、可复制 URL、无网提示；`OperatorPrefs`、`SessionState`、错误文案。
- 插件：`startHttpServer` / `stopHttpServer` / `httpServerStatus`；Android NanoHTTPD、HLS 切片、Range MP4；iOS 返回 `httpUnsupported`。
- 原生：与 `RtmpStreamSession` 编码器 tee 或 HLS-only 编码；`CaptureRecordService` FGS 文案与保活。
- 依赖：NanoHTTPD；`ACCESS_NETWORK_STATE`、`ACCESS_WIFI_STATE`、`FOREGROUND_SERVICE_MEDIA_PLAYBACK`。
