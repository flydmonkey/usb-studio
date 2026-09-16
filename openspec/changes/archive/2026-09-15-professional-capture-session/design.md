## Context

现有 App 已能打开 UVC 采集卡、PlatformView 预览、监听采集卡音频、可选录 MP4。默认自动选 1080p30 MJPEG（电视可降 720p），用户看不到当前信号，也不能改格式、调画面或看电平。Android 采集走 `packages/usb_capture` 的 UVCAndroid `CameraHelper`；iPad 走 AVFoundation `.external`。两端 UI 仍是预览页上的录制/静音两键。

专业采集的核心缺口不在推流或导播台，而在操作员闭环：确认有无 HDMI、确认格式、控制监听、截静帧、录制时知道成片大致体积。

## Goals / Non-Goals

**Goals:**

- 预览期间持续展示信号 HUD（分辨率、帧率、格式、有/无信号）。
- 用户可从设备支持列表选择视频格式；默认策略保持 1080p30 MJPEG / TV 720p。
- 预览按信号宽高比显示；监听可调音量、看峰值、补偿延迟。
- 对设备声明的 UVC 图像控件（亮度/对比度/饱和度/色调）提供调节与复位。
- 静帧保存到系统相册/图片库；录制增加画质档位与可读文件名；预览/录制保持亮屏。
- 手机可沉浸预览，电视可用遥控器切换 HUD/控件显隐；REC 指示始终可见。

**Non-Goals:**

- RTMP/SRT/NDI、多路混流、画中画、示波器、HDR/EDID、隔行处理。
- 暂停录制、App 退到后台继续录、桌面端、iPhone。
- 把每帧拉进 Dart 做滤镜或软件示波器。

## Decisions

### 1. 信号状态由原生上报，HUD 只渲染

- **选择**：插件周期上报 `signal` 事件：`width`、`height`、`fps`、`fourcc`、`hasSignal`、`audioPeak`（0–1）、录制中的 `bytesWritten`（可得则报）。Flutter HUD 不读像素。
- **理由**：PlatformView 像素在原生层；Dart 拷帧会加延迟。
- **备选**：Flutter Texture 抽帧。延迟与 CPU 差，不采用。

无信号判定：优先「超过约 500ms 无新视频帧」；采集卡仍出黑场但帧在走时，不把暗画面当无信号（避免夜场误报）。若平台能提供 HDMI lock 状态则优先用。

### 2. 格式切换在原生会话内完成，录制中禁止切换

- **选择**：`listFormats()` 返回 `{id, width, height, fps, fourcc}`。`setFormat(id)` 停预览、改 size、再开预览。正在录制时返回明确错误，不中断成片。
- **理由**：UVC 改 format 必须重建流；与 MP4 mux 并行会花屏或损坏文件。
- **备选**：每次改格式重开 USB。更稳但 USB 权限弹窗差，仅当 in-session 切换失败时回退。

默认仍自动选 1080p30 MJPEG，否则最高稳定档；电视带宽不足可默认 720p。用户手动选择后覆盖自动策略，直到拔卡或用户再改。

### 3. 预览信箱，不拉伸

- **选择**：PlatformView 外层按信号宽高比 letterbox（黑边），`FittedBox`/`AspectRatio` 或原生 `AspectRatioSurfaceView`。
- **理由**：采集卡几乎都是 16:9；拉伸会让操作员误判构图。
- **备选**：crop-to-fill。电影/预览好看但裁掉画面，专业监视不采用。

### 4. 监听音量、峰值、延迟仍走现有 AudioRecord→AudioTrack 通路

- **选择**：音量在 PCM 写出前缩放并同时 `AudioTrack` 音量；峰值从同一缓冲算 RMS/peak 节流上报（约 10Hz）。延迟用环形缓冲，步进 0/50/100/200ms。静音仍切断监听，不影响是否写入录制音轨。
- **理由**：第一期监听已独立于编码器；不必为监听再开 OpenSL。
- **备选**：系统 AEC/会话延迟 API。采集卡环出不是通话场景，不可靠。

iPad 用 `AVAudioEngine`/`AVCaptureAudioDataOutput` 做同样的音量/峰值/延迟；若只能调 session 输出音量，峰值可省略并在 HUD 标明「电平不可用」。

### 5. 图像控件走 UVC Processing Unit / AVFoundation 已暴露项

- **选择**：Android `UVCControl`（brightness/contrast/saturation/hue）。iPad 只暴露 `AVCaptureDevice` 实际支持的调节；没有的控件隐藏，不显示假滑条。提供「恢复默认」（设备 default 值，不是 App 臆造）。
- **理由**：采集卡常用 PU 修 HDMI 过曝/偏色；假控件会破坏信任。
- **备选**：完整 UVC CT/PU/EU 面板。范围过大，本期只做四项图像。

录制中允许调图像（改的是传感器/处理，不改 format）。

### 6. 截图走原生 still，不截 Flutter 控件

- **选择**：Android `CameraHelper.takePicture`（JPEG）；iPad `AVCapturePhotoOutput`。写入 Photos（iPad）或 MediaStore Images（Android）。录制中截图不得停止 mux。
- **理由**：要的是视频帧，不是带 HUD 的 UI 截屏。
- **备选**：`RenderRepaintBoundary`。会带 HUD 且可能不是满分辨率。

### 7. 录制档位只调视频码率，容器仍是 H.264+AAC MP4

- **选择**：两档：`standard`（约 8 Mbps @1080p，720p 按比例）、`high`（约 16 Mbps @1080p）。文件名 `USB_yyyyMMdd_HHmmss.mp4`。HUD 在录制中显示已写字节（编码器提供则用，否则按码率估算）。
- **理由**：操作员要的是稳和「更好看一点」，不是 CRF 专家面板。
- **备选**：自定义码率数字输入。电视遥控差，本期不做。

### 8. 亮屏与沉浸是 Flutter 壳职责

- **选择**：预览或录制时 `WakelockPlus`（或等效）保持亮屏；结束会话释放。沉浸模式隐藏底栏和次要 HUD，保留 REC 徽章；手机点预览切换，电视焦点键或「全屏」按钮切换。
- **理由**：不需要原生改采集图。
- **备选**：把控件画进 OpenGL overlay。TV 焦点更难，不采用。

## Risks / Trade-offs

- [无新帧 vs 黑场内容] → 只用帧超时判定无信号；不以亮度阈值判无信号。
- [改格式重建流失败] → 回退到改之前的 format 并报 `uvcFailed`；不把 USB 权限弹窗误报成供电不足。
- [iPad 外接相机控件/格式列表不全] → 规格允许「设备未声明则隐藏」；Android 为控件主路径。
- [takePicture 与预览抢 surface] → 用 UVCAndroid 的 ImageCapture 路径；失败则提示截图失败，预览必须恢复。
- [延迟补偿加大监听延迟] → 默认 0ms；只影响监听，不改写入 MP4 的时间戳。
- [高码率在弱 USB/弱 SoC 上掉帧] → 默认 standard；失败时提示并可建议降格式。
- [TV 沉浸后找不到退出] → 遥控器 Back 退出沉浸；REC 时仍显示徽章。

## Migration Plan

纯增量：旧自动开流行为保持为默认。无数据迁移。插件新增方法对旧调用方可缺省。回滚即不发该版本；用户无云端状态。

落地顺序：信号事件与 HUD → 格式列表/切换 → 信箱与亮屏 → 监听音量/峰值/延迟 → 图像控件 → 截图 → 录制档位与文件名 → 沉浸预览 → 真机（有/无 HDMI、改格式、录制中截图）。

## Open Questions

- 部分廉价采集卡在无 HDMI 时仍以固定黑帧输出，帧超时不会触发：若真机确认，再考虑可选的「近黑连续 N 秒」提示，默认关闭。
- iPad `AVCaptureDevice.formats` 是否覆盖采集卡全部 MJPEG 模式，需真机列出后再决定 UI 是完整列表还是精简常用档。
