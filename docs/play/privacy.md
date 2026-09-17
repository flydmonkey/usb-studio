# USB Studio Privacy Policy / 隐私政策

**Product / 产品:** USB Studio  
**Developer / 开发者:** flydmonkey  
**Contact / 联系邮箱:** shunsora@outlook.com  
**Last updated / 更新日期:** 2026-09-17

This policy applies to the USB Studio Android app (`io.github.flydmonkey.usbstudio`). The developer named on the Google Play listing must match **flydmonkey**. Public URL (GitHub Pages): https://flydmonkey.github.io/usb-studio/privacy.html

本政策适用于 USB Studio Android 应用（`io.github.flydmonkey.usbstudio`）。公开页面：https://flydmonkey.github.io/usb-studio/privacy.html 。应用内「隐私政策」与 Play Console 必须使用同一 URL。

---

## English

USB Studio lets you preview, record, and optionally live-stream video and audio from a **USB Video Class (UVC) capture card**. It does **not** use this device's built-in selfie / rear camera as a capture source.

### Data we do not collect

The developer does **not** operate user accounts, cloud backups, advertising, crash analytics, or other telemetry. The app does not send recordings to a developer-operated server.

### Camera and microphone

On Android 9 and later, the system requires **Camera** permission before an app can access a USB video device. USB Studio also requests **Microphone** permission so it can capture audio from the capture card (typically UAC), not from the phone's built-in mic as the primary source.

These permissions are requested after an in-app explanation, and only so the app can preview, record, snapshot, stream, or serve live LAN playback of the capture-card signal.

### Photos, videos, and files

Snapshots and MP4 recordings are **user-generated media** stored on the device in the location you choose (default album `DCIM/UsbCapture`, or Movies, Downloads, or a folder you pick). The app can list, play, share, rename, delete, and merge files it created. Media stays on the device unless **you** share it or copy it.

### RTMP streaming (optional)

If you start streaming, USB Studio sends the live capture-card audio/video to the **RTMP/RTMPS URL you enter**. That destination is controlled by you (for example a platform you already use). The developer does not receive that stream.

### LAN playback (optional)

If you enable LAN playback, the app starts a local **unencrypted HTTP** server on your Wi-Fi/LAN so other devices on the same network can watch live HLS or saved recordings. Anyone on that network who knows the URL can open it. This traffic is not sent to the developer and is not HTTPS.

### Notifications and battery

While recording, streaming, or LAN playback is active, Android may show a persistent notification (foreground service) so capture can continue in the background. Notification permission is requested when those features start, not at first launch. You may also be asked to ignore battery optimizations so lock-screen recording is not killed; this is optional.

### Network

The app uses the network only for operator-initiated RTMP ingest, optional LAN HTTP, and opening this privacy policy in a browser. Wi-Fi is not required; Ethernet on a TV is enough for LAN if an IPv4 address is available.

### Retention and deletion

There is no developer-side account or cloud copy to delete. Delete recordings in the in-app library or with the system Files / Photos apps. Uninstalling the app does not always remove files already written to shared storage (album / Movies / Downloads).

### Children

USB Studio is a capture tool for HDMI/USB capture cards. It is not directed at children.

### Changes

We may update this policy when app behavior changes. The date at the top will change. Continued use after an update means you accept the revised policy.

---

## 简体中文

USB Studio 用于预览、录制，并可选地把 **USB Video Class (UVC) 采集卡** 的画面和声音推出去。应用**不以**手机自带的前置/后置摄像头作为采集源。

### 开发者不收集的数据

开发者**不**提供账号、云备份、广告、崩溃统计或其他遥测，也不会把录像发到开发者自己的服务器。

### 相机和麦克风

Android 9 及以上系统要求应用具备**相机**权限后，才能访问 USB 视频设备。USB Studio 还会申请**麦克风**权限，以便采集采集卡上的声音（通常是 UAC），而不是把手机内置麦克风当作主要音源。

这些权限会在应用内说明之后再申请，用途仅限于预览、录制、截图、推流或局域网直播采集卡信号。

### 照片、视频和文件

截图和 MP4 是**你生成的媒体**，保存在你选择的位置（默认相册 `DCIM/UsbCapture`，也可改到影片、下载或自选文件夹）。应用可以列出、播放、分享、重命名、删除和合并它保存的文件。除非你主动分享或拷贝，媒体只留在本机。

### 推流（可选）

若你开始推流，USB Studio 会把采集卡的实时音视频发到**你填写的 RTMP/RTMPS 地址**。目的地由你控制。开发者收不到这条流。

### 局域网播放（可选）

若打开局域网播放，应用会在当前局域网启动**未加密的 HTTP** 服务，同一网络上的其他设备可以用浏览器看现场 HLS 或已录成片。知道地址的人都可以打开。流量不会发到开发者，也不使用 HTTPS。

### 通知和电池

录制、推流或局域网播放进行中，Android 可能显示持续通知（前台服务），以便锁屏或切到后台后仍能采集。通知权限在这些功能启动时才申请，而不是一打开应用就申请。系统也可能提示忽略电池优化，以便锁屏续录；这项可以拒绝。

### 网络

网络仅用于你主动发起的 RTMP、可选的局域网 HTTP，以及用浏览器打开本隐私政策。不强制 Wi-Fi；电视用网线只要有 IPv4 也可以做局域网播放。

### 保存与删除

开发者侧没有账号或云端副本可删。请在应用片库或系统文件/相册中删除录像。卸载应用不一定会删除已经写到共享存储（相册 / 影片 / 下载）的文件。

### 儿童

USB Studio 是采集卡工具，不以儿童为对象。

### 变更

应用行为变化时我们可能更新本政策，并修改文首日期。更新后继续使用即表示接受修订。
