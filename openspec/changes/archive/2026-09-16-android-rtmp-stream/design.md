## Context

本地录像走 `ICameraHelper.startRecording` 文件 sink，无法从同一 mux 拆出一路 RTMP。USB PCM 已在 `startAudioMonitor` 里。操作员要地址和密钥分栏，并可与分段录像同时开。

## Goals / Non-Goals

**Goals:**

- Android 将 `rtmp(s)://host/app` 与密钥拼成 ingest URL 后推 H.264 + AAC。
- 推流与本地分段录像可同时开：预览 surface + 文件编码器 + 推流编码器。
- 采集栏开关；设置两栏持久化；LIVE 角标；FGS 在仅推流时也在。
- 拔卡、无信号、连接失败给出中文错误并停推。

**Non-Goals:**

- iPad / RTSP / SRT / WebRTC。
- ffmpeg-kit。
- 从现有 `VideoCapture` 文件 mux 抽流。
- 云端账号登录；密钥同步到其他设备。

## Decisions

### 1. 地址 + 密钥两栏，Dart 侧拼接

- **选择**：设置「推流地址」「推流密钥」。密钥以 `?` 开头则直接拼接，否则 `trimEnd('/') + '/' + key`。仅接受 `rtmp://` 与 `rtmps://`。插件只收完整 URL。
- **理由**：对齐 B 站后台两栏；避免操作员手拼斜杠。
- **备选**：单栏完整 URL。操作员已否决。

### 2. 双编码，不 tee 文件 mux

- **选择**：`MediaCodec` 输入 Surface `helper.addSurface` 出 H.264；PCM 再编一路 AAC；`RtmpClient.sendVideo/sendAudio`。录像继续走现有 `VideoCapture`。
- **理由**：当前文件 sink 不暴露编码回调。
- **备选**：拆 AUSBC mux。改动录像路径，本阶段风险高。

### 3. RootEncoder 仅 rtmp 模块

- **选择**：JitPack `com.github.pedroSG94.RootEncoder:rtmp:2.5.0`（2.8 需要 compileSdk 37），自管编码器。
- **理由**：不引入 ffmpeg-kit，APK 增量小于完整 `library`。
- **备选**：手写 handshake。容易在 B 站鉴权上翻车。

### 4. 失败与生命周期

- **选择**：`startStream` 等到连接成功或超时再返回。拔卡 / 无信号 / `onConnectionFailed` 停推并发 `streamFailed`。FGS 在录制或推流任一存在时保持。
- **理由**：后台杀进程会断 RTMP；无信号继续推黑帧会误导收看端。
- **备选**：无信号仍推最后一帧。违背「无信号必须停推」。

## Risks / Trade-offs

- [部分采集卡多 Surface 掉帧] → 推流码率跟随当前画质预设；失败可读。
- [双路编码耗电] → 已接受；FGS + wakelock。
- [密钥写在本机 prefs] → 不打日志、不进 git。
- [JitPack 解析失败] → 构建时改模块坐标或锁版本。

## Migration Plan

无数据迁移。新偏好键默认空；未填时点推流提示补全。

## Open Questions

无。
