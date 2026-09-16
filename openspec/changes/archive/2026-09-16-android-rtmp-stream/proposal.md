## Why

操作员要把 USB 采集画面推到 B 站 / OBS / 自建 RTMP，同时还能本地分段录像。现有采集只写文件，没有推流入口。

## What Changes

- Android 采集栏增加「推流」开关；设置里用**推流地址**和**推流密钥**两栏（B 站式），拼接后再连接。
- 推流可与本地分段录像同时进行（独立 H.264/AAC 编码，不拆现有文件 mux）。
- 地址和密钥写入操作员偏好；密钥不打日志。
- 拔卡或无信号时停止推流并给出可读错误；推流期间前台服务与录制共用。
- iPad 本阶段不支持推流。

## Capabilities

### New Capabilities

- `live-rtmp-stream`: Android RTMP 推流的开始/停止、双编码、失败与平台限制。

### Modified Capabilities

- `operator-prefs`: 持久化推流地址和密钥。
- `operator-hud`: 推流中显示 LIVE；前台服务文案覆盖推流。

## Impact

- Flutter：采集栏、设置两栏、`OperatorPrefs`、`SessionState`、错误文案。
- 插件：`startStream` / `stopStream`；Android MediaCodec + RTMP 客户端；iOS 返回不支持。
- 依赖：JitPack RootEncoder `rtmp` 模块；`INTERNET` 权限。
