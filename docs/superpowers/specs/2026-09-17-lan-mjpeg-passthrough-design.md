# 局域网 MJPEG 直出

日期：2026-09-17

## 问题

局域网现场现在把 MJPEG 解成 NV21 再编 H.264+AAC 做 HLS，延迟和 CPU 都高。现场预览不需要声音。

## 决策

- 采集格式为 MJPEG 时，把 UVC 原始 JPEG 经 `GET /live.mjpeg`（`multipart/x-mixed-replace`）送到浏览器 `<img>`，不启 MediaCodec。
- 现场无声音。已录成片仍走 `/vod/` Range MP4。
- 只保留最新一帧，慢客户端丢帧。
- YUY2 等非 JPEG 格式不能直出，页面提示改成 MJPEG。
- 没插卡时连接可挂起直到有帧，或失败后页面重试并显示等待采集卡。
- 有 `/live.mjpeg` 观看者时（不是仅开 HTTP 服务）帧回调用 `PIXEL_FORMAT_RAW`。RTMP 推流需要 NV21，开推流后切回 NV21；此时 MJPEG 直出暂停，停推流后恢复。不把 JPEG 在 Java 里再解一遍给推流。
- 不再为局域网单独开 HLS 编码器。开推流时也不再 tee HLS。
- 局域网 MJPEG 进行中禁止改采集格式；录制画质可以改（不影响直出）。

## 不改

- 本地录像、RTMP、HTTP 无密码、VOD
- 现场音频

## 验收

- 插卡且格式为 MJPEG、打开局域网后，浏览器现场为无声画面，延迟低于原先 HLS。
- 不插卡仍能打开首页和片库。
- 非 MJPEG 格式时现场不可用并有说明。
- `flutter test` 与 Android 单测通过。
