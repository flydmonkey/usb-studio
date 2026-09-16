## Why

HDMI USB 采集卡在手机、平板和电视上通常被系统当成普通 UVC 摄像头，但系统相机 App 对采集卡的声音、延迟和录制支持不稳定。需要一个专用 App：插入采集卡后立即预览画面并监听声音，并在需要时把这一路音视频录成文件。

## What Changes

- 新建 Flutter 应用（仓库目前为空），覆盖 USB-C iPad（iPadOS 17+）、Android 手机/平板（USB OTG）和 Android TV / 电视盒（USB Host）。
- 发现并连接 UVC/UAC 采集卡，实时预览视频并播放采集卡音频。
- 用户可选择开始/停止录制，生成含画面和声音的 MP4，保存到相册或系统影片目录。
- Android 手机与 TV 共用同一采集实现；TV 使用 10-foot 布局和遥控器/D-pad 操作。
- iPhone 不支持 USB 采集（Apple 无公开 UVC API）；Apple 目标仅 iPad。不包含推流、桌面端、内置摄像头兜底、Fire TV 专有 SDK、HDMI-CEC，也不录制电视机自身 HDMI 环路。

## Capabilities

### New Capabilities

- `usb-capture-device`: 权限、设备发现、插拔、连接/断开，以及平台/硬件不支持时的明确提示（含 Android TV 的 USB Host、遥控授权和供电/UVC 失败）。
- `live-av-preview`: 实时画面预览、采集卡声音监听、预览静音；TV 上为 10-foot 布局与 D-pad 焦点。
- `session-recording`: 开始/停止录制、成片含视频+音频、保存位置、录制中拔线处理；TV 上用遥控器操作并提示 Movies 路径。

### Modified Capabilities

- 无。仓库尚无主规格。

## Impact

- 从空仓库引入 Flutter 应用（根目录）和 in-repo 插件 `packages/usb_capture`。
- iPad：AVFoundation 外接摄像头/麦克风、相机与麦克风权限、仅 iPad 目标。
- Android（手机/平板/TV）：USB Host、UVC 库、CAMERA/RECORD_AUDIO/USB 权限；TV 额外 Leanback Launcher（`leanback` 非强制）与 banner。
- 成片：iPad 写入相册；Android 写入 MediaStore Movies。
- 真机依赖 USB-C iPad、OTG 手机、带 USB Host 的 TV/盒子，以及 UVC 采集卡；模拟器无法验证采集。
