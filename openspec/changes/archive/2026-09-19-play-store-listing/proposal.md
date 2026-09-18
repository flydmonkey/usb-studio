## Why

USB Studio 的采集、录制、推流和局域网播放已经能作为完整工具使用，但还不满足 Google Play 上架的政策与审核要求：没有应用内/公网隐私政策，启动时直接申请相机、麦克风和通知且不说明用途，电视相关硬件声明不完整，release 仍用 debug 签名。现在要把第一版送到 Play，这些缺口会直接导致无法上传或审核打回。

## What Changes

- 增加可公开访问的隐私政策，并在设置里提供应用内入口（与 Play Console 同一 URL）。
- 首次采集前先说明为何需要相机和麦克风（USB 采集卡，不是手机自拍摄像头），操作员确认后再申请；通知权限改到开始录制、推流或打开局域网播放时再要。
- 设置增加关于区：版本号、隐私政策、开源许可。
- Manifest 把麦克风、自动对焦、Wi-Fi 声明为非必需，避免电视/无麦设备被过滤；电视 banner 加上应用名。
- 仓库提供 Play 上架材料：隐私政策正文、商店文案、Data safety 草稿、审核备注；release 改为正式签名并产出 AAB。
- 手机和电视仍共用同一包，不撤 `LEANBACK_LAUNCHER`。
- 不增加账号、内购、广告、内置摄像头、云同步；不把录像上传到开发者服务器。

## Capabilities

### New Capabilities

- `play-disclosure`: 应用内隐私政策、关于信息、首次权限说明，以及与商店页一致的数据披露。

### Modified Capabilities

- `usb-capture-device`: 运行时权限改为先说明后申请；通知权限延后；电视可安装所需的硬件 feature 声明。

## Impact

- Flutter：设置关于区、首次权限说明对话框、l10n、打开隐私政策 URL。
- Android：plugin / app Manifest 的 `uses-feature`、电视 banner、release 签名、`flutter build appbundle`。
- 文档：`docs/play/` 隐私政策、商店文案、Data safety、审核备注；keystore 不进 git。
- 测试：权限说明与设置入口的 widget 测试；不插卡仍可打开隐私政策和关于信息。
