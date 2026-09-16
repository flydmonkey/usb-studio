## 1. Flutter 工程与插件骨架

- [x] 1.1 在仓库根目录创建 Flutter 应用，最低 iOS 部署版本 17，Android minSdk 按所选 UVC 库设置（21 或 24）
- [x] 1.2 将 iOS 目标设为仅 iPad（TARGETED_DEVICE_FAMILY = 2），并声明相机/麦克风用途文案
- [x] 1.3 创建 in-repo 插件 `packages/usb_capture`，用 path 依赖接入应用
- [x] 1.4 定义 Dart API：listDevices、open/close、预览入口、start/stopRecording、权限、插拔与错误事件（含无 Host、权限拒绝、UVC 失败、供电、无音频源）
- [x] 1.5 为 iOS/Android 提供可编译的 stub，使 `flutter analyze` 通过

## 2. Android UVC 采集（手机与 TV 共用）

- [x] 2.1 接入 AUSBC 或同级 libuvc 封装，配置 USB Host、device filter、CAMERA 与 RECORD_AUDIO
- [x] 2.2 实现设备枚举、USB 权限请求、插拔监听与单设备打开/关闭
- [x] 2.3 实现 TextureView/OpenGL PlatformView 预览；优先 1080p30 MJPEG，否则选最高稳定模式
- [x] 2.4 实现采集卡 UAC 音频监听；无 UAC 时标明无采集音频，禁止改用设备麦克风
- [x] 2.5 实现原生 H.264+AAC MP4 录制，成片写入 MediaStore Movies
- [x] 2.6 实现 USB Host 缺失、UVC 打开失败、供电不足（提示 powered hub）和录制中拔线的错误码

## 3. iPad AVFoundation 采集

- [x] 3.1 用 DiscoverySession `.external` 枚举外接摄像头，并监听连接/断开
- [x] 3.2 用 AVCaptureVideoPreviewLayer PlatformView 预览外接画面
- [x] 3.3 将采集卡关联麦克风/UAC 加入同一 AVCaptureSession 并做预览监听
- [x] 3.4 用 AVCaptureMovieFileOutput 录制 MP4，完成后写入 Photos
- [x] 3.5 iPhone 运行时直接展示不支持 USB 采集，不创建采集会话

## 4. 预览与录制 UI（手机/平板）

- [x] 4.1 实现全屏预览页：设备名、连接状态、空设备态
- [x] 4.2 实现预览静音开关（只静音监听，不停止画面，不单独掐断录制音频）
- [x] 4.3 实现开始/停止录制、录制指示与已用时间；无预览时禁止开录
- [x] 4.4 实现权限拒绝、拔线、无音频源、保存成功等状态文案

## 5. Android TV Leanback 与 10-foot UI

- [x] 5.1 Manifest 增加 LEANBACK_LAUNCHER、TV banner，`android.software.leanback` 设为 required=false
- [x] 5.2 按 UI_MODE_TYPE_TELEVISION（必要时无触摸大屏）切换 10-foot 布局：大控件、安全边距、全屏预览
- [x] 5.3 保证录制、静音、状态控件可被 D-pad 聚焦；预览 PlatformView 不抢焦点
- [x] 5.4 TV 录制完成后提示「已保存到影片目录」；1080p 不稳时降到 720p 或给出明确错误

## 6. 验证

- [x] 6.1 跑 `flutter analyze` 与现有/新增单测（插件错误映射、TV uiMode 布局分支、录制状态机）
- [x] 6.2 Android TV 模拟器验证 Leanback 启动与 D-pad 焦点（不作为 UVC 通过条件）
- [x] 6.3 真机验收：USB-C iPad、OTG Android 手机、带 USB Host 的 TV/盒子 + HDMI 采集卡，覆盖预览、听声、录制、拔线与失败提示
