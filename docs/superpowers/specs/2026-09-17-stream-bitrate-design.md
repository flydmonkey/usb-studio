# 推流独立码率

日期：2026-09-17

## 问题

RTMP 推流目前和「录制画质」共用 `qualityPreset`。1080p 默认标准约 8 Mbps，上行经常吃不消。本地成片仍需要较高码率。

## 决策

- 推流码率与录制画质分开，各自持久化。
- 推流四档（1080p 基准）：**1 / 2 / 4 / 6 Mbps**，默认 **2 Mbps**。
- 分辨率缩放公式与录制相同：`base * (width*height)/(1920*1080)`，系数夹在 0.25–2.0。编码器下限仍为 500 kbps。
- 设置 → 推流，在地址/密钥下增加「推流码率」下拉。推流进行中禁用；不支持热切换。
- 局域网现场编码不跟这档绑定，仍用录制画质再经现有 HLS 上限。

## 数据

插件新增 `StreamBitrate`：`mbps1` / `mbps2` / `mbps4` / `mbps6`，`baseBitrate` 分别为 1e6 / 2e6 / 4e6 / 6e6。`parse(null|非法)` → `mbps2`。

`OperatorPrefs.streamBitrate`，键 `operator.streamBitrate`，默认 `mbps2`。

原生 `streamBitratePreset` 与 `qualityPreset` 并列。插件 `setStreamBitrate(preset)`：启动时同步，改下拉时再设。新建 RTMP 编码器时用推流档算码率；`beginSegment` 仍用录制档。

若局域网现场编码已经在跑，现有路径会把 RTMP 挂到同一编码器上，不重启、不改当前码率。推流档只在这次会话里新开 RTMP 编码器时生效。

## 锁定

- 推流中：不能改推流码率；UI 禁用；原生抛 `streamFailed` / `streamInProgress`。
- 录制画质、采集格式：保持现状（录制或推流进行中不可改）。
- 只在录像、未推流时：可以改推流码率，下次开推流生效。

## 文案

五语 ARB 增加 `streamBitrate` 与四档标签。标签用 `1 Mbps` 形式（各语言可原样）。

## 不改

- 录制四档数值与默认 `standard`
- AAC 音频码率
- 推流中途改码率
- 自定义任意 kbps
- LAN HLS 码率策略

## 验收

- 新安装默认推流 2 Mbps；录制默认仍为标准。
- 改推流档不影响下一场本地成片码率；改录制画质不影响下一场推流。
- 推流中下拉禁用；停推后可改。
- `flutter test` 与插件 Dart / Android 单测覆盖：偏好读写、非法值回落到 2 Mbps、设置下拉、原生 RTMP 用推流档。
