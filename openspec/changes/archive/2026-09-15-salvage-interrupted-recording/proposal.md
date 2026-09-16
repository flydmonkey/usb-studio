## Why

录制中拔采集卡或编码器报错时，Android 会丢掉 cache 里未发布的临时文件，操作员白录一场。主规格已经要求尽量保住能封装的媒体，但实现是直接丢弃。现在预览和正常停录已经可用，先把「中断也能留下能播的片子」补上，比做一小时后台分段更划算。

## What Changes

- 录制中设备断开、会话失败、或编码器报错时，只要临时视频有可封装内容，就 mux 并写入系统影片库（Android Movies / iPad Photos），再结束录制状态。
- UI 必须同时说明「采集中断」和「片子是否已保存」；不能只显示已拔出却让人以为文件没了，也不能卡在录制中。
- 没有任何可救字节时，才提示录制失败/已中断且未保存。
- 不包含：前台服务、锁屏续录、自动分段、片库页、把损坏 moov 的文件强行修复到完整时长。

## Capabilities

### New Capabilities

- （无）行为落在现有录制会话上，不新开能力。

### Modified Capabilities

- `session-recording`: 中断录制时从「停录并尽量 salvage」改为明确必须发布可播 MP4（若有内容），并告知保存结果；编码器错误走同一条路径。

## Impact

- Android `CaptureEngine.close` / `handleDisconnect` / `VideoCapture.onError`：先 `save=true` 或等价 salvage，再拆会话。
- iPad `CaptureController.close` / disconnect：停 `AVCaptureMovieFileOutput` 后走现有写入 Photos 的完成回调，而不是丢弃。
- Flutter 预览页：`disconnected` / `error` 与 `recordingSaved` 组合展示；状态机退出 `recording`。
- 单测覆盖「中断且有内容 → 视为已保存」「无内容 → 失败且未保存」。
