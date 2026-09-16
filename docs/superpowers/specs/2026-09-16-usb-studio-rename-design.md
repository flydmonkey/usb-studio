# USB Studio 改名

日期：2026-09-16

## 决策

桌面图标、通知和文档中的应用名改为 **USB Studio**。USB 表示采集卡输入，Studio 覆盖预览、录像、推流和局域网播放。

应用 ID 改为 `io.github.flyedmonkey.usbstudio`。安装后是新应用，旧的 `com.usbcamera.capture.usb_camera_capture` 需手动卸载。

## 范围

改：

- 显示名：`AndroidManifest` label、`MaterialApp.title`、前台通知标题与空闲文案
- Android `applicationId` 与 `namespace`、`MainActivity` 包路径
- Flutter 包名 `usb_camera_capture` → `usb_studio`（import 同步）
- README

不改：

- 内部插件 `packages/usb_capture` 与 Kotlin 包 `com.usbcamera.capture.usb_capture`
- 录像目录 `DCIM/UsbCapture`（片库仍能列出旧文件）
- Git 仓库目录名

## 验收

- 桌面图标显示 USB Studio
- `adb shell pm path io.github.flyedmonkey.usbstudio` 能找到包
- `flutter test` 通过
