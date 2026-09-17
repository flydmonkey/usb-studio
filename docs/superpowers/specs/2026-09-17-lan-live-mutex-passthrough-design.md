# 局域网现场：JPEG 直出并与手机预览互斥

日期：2026-09-17

## 问题

局域网现场设计为 UVC JPEG 直出（`PIXEL_FORMAT_RAW`），实现却把帧回调解成 NV21 再压 JPEG，红米上 CPU 高、网页还可能糊。手机 `TextureView` 与网页现场同时开时，UVC 还要往 Surface 解码。网页没人看实时预览时，也不该为局域网空转编码。

本设计补上直出，并在「网页正在看现场」时让出手机预览。它覆盖 `2026-09-17-lan-mjpeg-passthrough-design.md` 里「只开局域网就 RAW」的触发条件：改为**有观看者才直出**。

## 决策

- 观看者 = 正在读取 `GET /live.mjpeg` 的连接数。流开始 +1，`close` −1，计数不为负。
- `active` = 计数 > 0，采集格式为 MJPEG，且当前没有 RTMP 推流。
- `active` 时：帧回调 `PIXEL_FORMAT_RAW`；识别到 JPEG SOI（`FF D8`）后原样 `hub.publish`（可去掉 SOI 前的填充）；拆掉手机预览 Surface；不启 MediaCodec、不做 NV21/RGBX 再压缩、不截 TextureView。
- 没有观看者时：不设局域网帧回调、不跑 `lan-jpeg` 编码线程。若设置「开启预览」为开且 TextureView 仍在，把 Surface 接回去。
- 推流时局域网现场暂停（现有行为），`active` 为假，恢复手机预览；即使浏览器还挂着 `<img>`。停推流后若仍有观看者，再进入 `active`。
- 互斥只压住画面，不改 `previewEnabled`，不停采集会话、录像、本机监听。有观看者时操作员打开「开启预览」只改偏好，要等 `active` 结束后才建 Surface。
- Flutter 收 `lanLiveBusy: true/false`。`true` 时不建 `UsbCapturePreview`，预览区显示「网页正在看现场」（五语）。`false` 后按偏好恢复预览控件。
- 网页关掉实时预览或切成片时必须拿掉 `/live.mjpeg` 的 `src`，好让连接结束。
- 非 MJPEG：不直出、不互斥，页面继续提示改格式。
- `releaseIfIdle` 在会话仍开着时不得 `engine.stop()`（保持关局域网后点预览不黑屏）。

## 观看者计数

`LanLiveViewers` 单独可测。`MjpegMultipartStream.close()` 必须 −1。若一条流 30 秒内没有任何 `read`，自行结束并 −1，避免页签关掉后 NanoHTTPD 不 `close` 导致互斥卡住。两个浏览器同时看则计数为 2，只在回到 0 时恢复手机预览。

## JPEG 识别

`JpegFrameFormat` 增加 JPEG 种类，且必须先于按缓冲区大小判断的 NV21/RGBX（1080p JPEG 远小于 NV21，现有启发式会判成 Unknown）。无 SOI 的 RAW 缓冲丢掉，不退回 View 截图。

## 不改

- 局域网无密码、VOD、成片下载
- 现场音频、CH9329 / 网页键鼠
- 推流仍用 NV21；开推流时不把 JPEG 在 Java 里再解一遍给推流
- iPad 不做局域网服务器

## 验收

- 只开局域网、网页没开实时预览：手机预览正常；没有为网页空转的 JPEG 编码。
- 网页打开实时预览：手机让出并出现提示；浏览器现场清晰（直出，不是 TextureView 截图）；延迟低于 NV21 再压缩。
- 关掉网页实时预览或关页签（含 30s 超时）：手机预览自动回来，可点，不是黑屏。
- 推流时网页现场暂停、手机能预览；停推流且网页仍在拉流则再让出。
- 关局域网再点预览：预览还在。
- `flutter test` 与 `:usb_capture:testDebugUnitTest` 通过：`LanLiveViewers`、JPEG 先于 NV21、无 SOI 不发布、`lanLiveBusy` 时无预览控件且偏好仍为开启预览、busy 结束后控件回来、`CaptureRuntimePolicy` 会话开着不释放。
