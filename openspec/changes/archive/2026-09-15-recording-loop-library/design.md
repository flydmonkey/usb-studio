## Context

采集仍绑在 Flutter Activity：没有前台服务，成片先写 `cacheDir` 再拷进 MediaStore。锁屏或 MIUI 杀进程会丢掉当前文件。 salvage 只救「还在 temp 里」的那一段。操作员没有 App 内列表。

目标使用：Android 手机亮屏或锁屏连录约 1 小时，回来能在 App 里找到每 10 分钟一段的 MP4。

## Goals / Non-Goals

**Goals:**

- Android 录制进程在锁屏/切走后继续，直到用户停止、拔线或 salvage。
- 分段立即入库，闪退最多丢当前未封完的一段。
- App 内片库覆盖本应用 `Movies/UsbCapture`（Android）与 USB_ 相册项（iPad）。
- 关预览、沉浸模式、已有 salvage 与分段兼容。

**Non-Goals:**

- 把多段自动拼接成一条时间线。
- iPad 锁屏续录、桌面端、推流、暂停、iPhone。
- 通用系统相册浏览器（只列出本应用采集文件）。

## Decisions

### 1. 采集所有权在前台服务，不在 Activity

- **选择**：`CaptureRecordService` 在 `startRecording` 时 `startForeground`，持有 `CaptureEngine`；Activity 只绑定服务。`onPause`/`onStop` 不得 `plugin.close()`。用户点停止或会话断开后停服务。
- **理由**：MIUI 对无 FGS 的 USB/录音进程不友好；引擎已在 plugin，迁到服务比再写一套采集便宜。
- **备选**：只加 wakelock。锁屏后仍会被杀。

### 2. 类型与通知

- **选择**：Android 14+ `foregroundServiceType` 同时声明 `camera|microphone|connectedDevice`。通知渠道「录制」，文案「正在录制 00:12:04 · 第 2 段」，点通知回前台。
- **理由**：UVC + USB 音频都要保活。少一个 type 会被系统打断。
- **备选**：仅 microphone。USB 摄像头在部分机型仍被停。

### 3. 十分钟分段，立即 publish，不拼接

- **选择**：同一场 `USB_<stamp>_NN.mp4`，NN 从 01 起。到点先 salvage/停当前 VideoCapture、publish、立刻 start 下一段，UVC 相机保持打开。段间允许约 1 秒缺口。REC 显示一场总时长。
- **理由**：1 小时单文件约 3.6GB 放 cache 不安全；拼接 H.264 要另做 mux，本期不做。
- **备选**：5 分钟段。文件过多。15 分钟。闪退丢失窗口更大。定 10 分钟。

### 4. 电池优化只问一次

- **选择**：首次 `startRecording` 若未忽略优化，发事件让 Flutter 弹一次说明并跳转系统页；用 SharedPreferences 记「已提示」。拒绝仍允许录，通知里可再进设置。
- **理由**：小米不忽略优化时 FGS 仍可能被杀。不能每次开录都弹。

### 5. 片库只扫本应用采集路径

- **选择**：Android `MediaStore` 查询 `RELATIVE_PATH` 含 `Movies/UsbCapture`。iPad 用 `PHAsset` 按文件名 `USB_` 过滤（做不到则列出本会话保存过的本地路径）。分享走系统 share sheet；删除走 MediaStore/Photos，需确认。
- **理由**：不要做成第二个相册 App。
- **备选**：只显示本次运行内存列表。杀进程后片库变空，不可接受。

### 6. iPad 范围

- **选择**：分段可做（前台）；后台保活明确不做。片库尽力查相册。
- **理由**：外接 UVC 后台不被系统支持，做了也过不了审核预期。

## Risks / Trade-offs

- [厂商仍杀 FGS] → 忽略电池优化 + 前台通知；杀了也只丢当前段。
- [换段时 USB 抖一下] → 失败则 salvage 当前段并停录，已入库段保留。
- [READ_MEDIA_VIDEO 权限] → 只查自己写入的集合；Android 10+ 用 MediaStore 自己的 URI 可不广扫全盘。
- [电视无分享目标] → 分享失败给明确文案，删除与列表仍可用。

## Migration Plan

无旧数据迁移。已在相册里的 `USB_*.mp4` 若在 `Movies/UsbCapture` 下会出现在片库。

## Open Questions

- 无。分段 10 分钟、不拼接、Android 后台 / iPad 仅前台，已定。
