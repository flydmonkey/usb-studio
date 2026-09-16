## Context

仓库目前只有 OpenSpec 脚手架，没有应用代码。目标是做一个 Flutter App：插入 HDMI USB 采集卡后预览画面、监听采集卡声音，并可把这一路音视频录成 MP4。平台为 USB-C iPad（iPadOS 17+）、Android 手机/平板（OTG）和 Android TV / 电视盒（USB Host）。iPhone 没有公开 UVC API，不作为采集目标。

采集卡在系统里是 UVC 视频 + 通常伴随 UAC 音频。iPadOS 17 通过 AVFoundation `.external` 官方支持；Android 的 CameraX 通常枚举不到 UVC，必须走 USB Host + UVC 库。Android TV 与手机共用这条采集链路，差异在遥控 UI 和更差的 USB 兼容性。

## Goals / Non-Goals

**Goals:**

- 一套 Flutter UI + 仓库内原生采集插件，覆盖 iPad 与 Android（含 TV）。
- 发现/连接 UVC 采集卡，实时预览，播放采集卡音频，可选录制 H.264+AAC MP4。
- Android 手机与 TV 共用同一 UVC 实现；TV 使用 10-foot + D-pad。
- 权限失败、无设备、拔线、无 USB Host、UVC 打不开时给出明确错误，禁止静默黑屏。

**Non-Goals:**

- iPhone USB 采集、Windows/macOS、RTMP/网络推流、多路同时采集。
- 内置摄像头兜底、UVC 画质旋钮、分辨率高级面板、截图。
- Fire TV 专有 SDK、HDMI-CEC、录制电视机自身 HDMI 环路。

## Decisions

### 1. Flutter 根工程 + in-repo plugin `packages/usb_capture`

- **选择**：应用在仓库根目录；采集能力做成 federated/in-repo plugin，Dart 统一 API，iOS/Android 各自实现。
- **理由**：两端 UI 相同（预览+录制），采集必须原生。官方 `camera` 插件基本只覆盖内置摄像头，iPad 外接 UVC 没有成熟 Flutter 插件。
- **备选**：双原生（SwiftUI + Compose）采集集成更好但 UI 双倍成本；KMP 对 AVFoundation/UVC 帮助有限。不采用。

Dart API 最小面：`listDevices`、`open`/`close`、预览 widget、`startRecording`/`stopRecording`、权限、插拔事件、错误码（无 Host、权限拒绝、UVC 失败、供电提示、无音频源）。

### 2. 预览走 PlatformView，录制走原生 mux

- **选择**：iPad 用 `AVCaptureVideoPreviewLayer`；Android 用 TextureView（AUSBC/OpenGL 预览）。录制不把每帧拉进 Dart 再编码。
- **理由**：低延迟；音视频时间戳由系统/编码器处理。Texture 拷帧到 Flutter 会增加延迟和 CPU。
- **备选**：Flutter Texture / 自研 mux。仅在 PlatformView 无法满足时再退。

### 3. iPad：AVFoundation external camera + movie file output

- **选择**：`AVCaptureDevice.DiscoverySession`（`.external` + video）；音频用采集卡关联麦克风/外接 UAC，加入同一 `AVCaptureSession`。录制用 `AVCaptureMovieFileOutput`。Xcode 仅 iPad（`TARGETED_DEVICE_FAMILY = 2`）。最低 iPadOS 17。
- **理由**：WWDC23 官方路径；MovieFileOutput 负责封装 MP4。限制 iPad 避免 iPhone 能装不能采。
- **备选**：DriverKit/自研 UVC——iPhone 不可用，iPad 无必要。

### 4. Android 手机与 TV：同一 UVC 库，同一 APK

- **选择**：UsbManager 权限 + AUSBC（或同级 libuvc 封装）。音频优先采集卡 UAC。录制在原生侧 H.264+AAC MP4。`android.software.leanback` **required=false**；增加 `LEANBACK_LAUNCHER` 与 TV banner。用 `UI_MODE_TYPE_TELEVISION`（必要时无触摸大屏）切换 10-foot UI。minSdk 跟 UVC 库（预计 21/24）。
- **理由**：TV 不是第二种采集协议。`leanback` 强制为 true 会排除手机和国内无 Leanback 的盒子。
- **备选**：TV 独立 flavor/APK——安装与发版成本高，第一期不采用。CameraX EXTERNAL——OEM 支持碎片化，不能作为主路径。

### 5. 默认模式与 TV 降级

- **选择**：优先 1080p30 MJPEG；否则最高稳定模式。Android TV USB 带宽/供电不足时可降 720p。
- **理由**：消费级 HDMI 采集卡常见 1080p30 MJPEG；YUY2 在 USB 2.0 上更容易撑满带宽。

### 6. 成片保存位置

- **选择**：iPad → Photos；Android（含 TV）→ MediaStore Movies。TV 完成后提示「已保存到影片目录」。
- **理由**：系统库可被相册/文件管理器看到；TV 往往没有手机相册 App。

### 7. UI 壳

- **手机/平板**：全屏预览、状态、录制键、计时、预览静音、错误空态。
- **TV**：同样信息架构，控件变大、安全边距、焦点环，全部可用 D-pad 操作。

## Risks / Trade-offs

- [iPhone 无法采集] → 规格明确不支持；Apple 目标仅 iPad。若将来系统开放 UVC，再扩 `.external`。
- [Android OEM 无 isochronous / 假 USB Host] → 打开失败时给出明确错误，禁止黑屏；文档说明并非所有手机/电视都能用。
- [采集卡供电不足] → 空态/错误文案提示带供电 USB Hub；TV 上更常见。
- [UVC 库与 targetSdk 兼容] → 跟进 AUSBC/libuvc 的 Android 10+ USB 权限与 CAMERA/RECORD_AUDIO 要求；真机矩阵尽早验证。
- [采集卡无音频或 UAC 路由错误] → 预览可无声但必须标明；禁止用设备麦冒充采集声；录制按「无采集音频」处理。
- [TV 模拟器不能测 UVC] → 模拟器只验 Leanback 启动与焦点；采集必须用 Shield/带 USB Host 的盒子 + 采集卡。
- [PlatformView 与 Flutter 焦点] → TV 上原生预览层可能抢走焦点；预览区域不作为焦点节点，控件放在独立 overlay。
- [延迟 vs 易维护] → 原生预览换来低延迟，插件要维护两套原生代码；这是跨 iPad/Android 的必要成本。

## Migration Plan

绿场项目，无旧版本可迁。落地顺序：Flutter 脚手架 → plugin 接口与假实现 → Android UVC 预览/音频/录制 → iPad AVFoundation → TV Leanback 与 10-foot UI → 权限/错误态 → 真机验收。回滚即不发版。后续加桌面或推流应新开 OpenSpec change。

## Open Questions

- 具体 UVC 封装（AUSBC vs 直接 libuvc）在实现期用真机选，接口保持稳定。
- iPad 采集卡音频是「摄像头内建麦」还是独立 UAC，需真机确认；会话始终优先外接/设备关联源。
- 国内电视盒 uiMode 是否总是 `TELEVISION`：若不是，用无触摸 + 大屏作为第二判定，避免误用手机布局。
