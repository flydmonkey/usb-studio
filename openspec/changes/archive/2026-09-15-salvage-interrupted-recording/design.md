## Context

Android 录制把视频写到 `cacheDir` 的临时 MP4，停录时才 mux AAC 并 `publishMovie` 到 MediaStore。`CaptureEngine.close()` 经 `stopRecordingInternal(save = false)` 丢掉临时文件。USB 拔出走 `handleDisconnect()` → `close()`，所以录制中拔线等于白录。编码器 `onError` 同样不会发布成片。

iPad 用 `AVCaptureMovieFileOutput`；`close()` 会 `stopRecording()` 但立刻 `session.stopRunning()`，完成回调不一定来得及写入 Photos，Flutter 也收不到保存结果。

Flutter 已有 `recordingSaved` 事件分支，原生从未发出。主规格「preserve any finalized media that can be salvaged」没有可测试的成功/失败分支。

## Goals / Non-Goals

**Goals:**

- 录制中断开、会话失败、编码器报错时，若临时视频非空，则 mux（音频能封装则带上）并写入系统库。
- UI 退出录制态，同时说明中断原因和是否已保存。
- Android 与 iPad 行为对齐；电视仍提示影片目录。

**Non-Goals:**

- 前台服务、锁屏/切走续录、分段封装。
- 修复缺少 moov、长度为 0、或无法 mux 的损坏文件。
- 片库浏览、分享、自动打开刚保存的文件。

## Decisions

### 1. 先 salvage 再拆会话

- **选择**：断开或编码错误时调用与正常停录相同的封装/发布路径（Android `stopRecording()` 的 mux+MediaStore；iPad 等 `didFinishRecording` 写入 Photos），成功后再 `closeCamera` / `session.stopRunning`。
- **理由**：现成发布逻辑已验证；`save = false` 是丢片的直接原因。
- **备选**：只拷临时 `_v.mp4` 不 mux。可能无声或播放器打不开，不采用。

### 2. 用已有 `recordingSaved`，再发 `disconnected` / `error`

- **选择**：salvage 成功则先发 `recordingSaved`（`path`、`hasAudio`、`savedToMovies`），再发 `disconnected` 或 `error`。失败则只发中断/错误，不发 `recordingSaved`。
- **理由**：Dart 已处理 `recordingSaved`；预览页需在 `disconnected` 时若刚保存过，把状态写成「已拔出，片子已保存」。
- **备选**：给 `disconnected` 加 `salvaged` 字段。要改事件模型，收益不大。

### 3. 可救的判据是临时视频非空

- **选择**：Android：`videoTemp.exists() && length > 0`，音频失败则视频-only 仍发布。iPad：`stopRecording` 完成后文件可写入相册则算成功。
- **理由**：与正常停录、无采集音频时仍存视频的政策一致。
- **备选**：要求音视频都完整。拔线时常先丢 USB 音频，会误杀有画面的成片。

### 4. 编码器错误与拔线同一条 salvage

- **选择**：`VideoCapture.onError` / iOS recording 失败回调：有内容就发布，然后 `error`（`recordingFailed` 或 `disconnected` 按原因）。
- **理由**：操作员不区分「线掉了」还是「编码挂了」，都要片子。

## Risks / Trade-offs

- [拔线瞬间编码器已死，`stopRecording` 超时] → 仍尝试 mux 已有 temp；超时后若文件非空则 `copyTo` 发布视频-only；两边都失败才报未保存。
- [salvage 期间 USB 已断开，UVC `stopRecording` 卡住] → 保留现有 latch 超时（约 8s），超时走文件兜底，UI 不得一直显示 REC。
- [iPad `stopRunning` 抢在文件收尾前] → disconnect 时先停 movie output 并等待完成回调，再 `stopRunning`。
- [成片尾部缺一两秒] → 可接受；不承诺中断瞬间的最后一帧。

## Migration Plan

无数据迁移。发版后旧的「拔线丢片」行为消失。无法 salvage 的中断仍只提示错误。

## Open Questions

- 无。电视与手机共用同一套事件与文案（电视继续强调影片目录）。
