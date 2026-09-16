## Context

分段目前写死 10 分钟；预览静音只在本次会话；没有自动开录。偏好需要跨进程保存。

## Goals / Non-Goals

**Goals:**
- 分段可关，或选 5/10/15/30 分钟，开录时传给原生。
- 自动开录在启动连上与中途插卡连上时生效；手动停止后本轮插着的卡不再自动开。
- 预览静音、音量、延迟持久化并在 `open` 后应用到原生。

**Non-Goals:**
- 自定义任意分钟数、录制中改分段、拼接多段、记住画质/格式。

## Decisions

- Flutter `shared_preferences` 存偏好；`startRecording(segmentMinutes:)` 传给原生，`0` 表示不分段。
- 不分段文件名 `USB_<stamp>.mp4`；分段仍为 `USB_<stamp>_NN.mp4`。
- 自动开录只走 Flutter 连接成功路径，复用现有开录/FGS/电池提示。
- 手动停止设置 `deferUntilReconnect`；`disconnected` 或进程重启后清除。

## Risks / Trade-offs

- 自动开录可能在操作员还没看画面时开始 → 默认关闭。
- 超长单文件仍有闪退丢失窗口 → 默认保持 10 分钟分段。
