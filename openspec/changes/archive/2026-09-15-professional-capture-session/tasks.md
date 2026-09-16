## 1. 插件 API 与信号事件

- [x] 1.1 扩展 Dart 模型：CaptureFormat、SignalStatus、PictureControl、QualityPreset，以及 signal / audioPeak 事件
- [x] 1.2 扩展插件方法：listFormats、setFormat、setMonitorVolume、setMonitorDelay、listPictureControls、setPictureControl、resetPictureControls、takeSnapshot、setRecordingQuality
- [x] 1.3 为 Android/iOS 增加可编译 stub，单测覆盖格式切换在录制中被拒绝、无预览禁止截图

## 2. Android 信号、格式与画面

- [x] 2.1 用帧回调检测无新帧并上报 hasSignal、width/height/fps/fourcc
- [x] 2.2 实现 listFormats / setFormat（录制中拒绝；失败回退上一档）
- [x] 2.3 用 UVCControl 实现亮度/对比度/饱和度/色调及恢复默认；未声明的控件不暴露
- [x] 2.4 实现 takePicture 静帧写入 MediaStore Images，录制中不得停 mux
- [x] 2.5 录制使用 timestamp 文件名，并按 standard/high 设置视频码率；上报已写字节或估算体积

## 3. Android 监听增强

- [x] 3.1 监听通路增加音量缩放、峰值上报（约 10Hz）、0/50/100/200ms 延迟缓冲
- [x] 3.2 确认预览静音仍只切监听；延迟与音量不改 MP4 音轨时间戳

## 4. iPad 对等能力

- [x] 4.1 从 AVCaptureDevice.formats 列出并切换格式；录制中拒绝切换
- [x] 4.2 实现帧超时无信号、信箱预览、PhotoOutput 静帧写入相册
- [x] 4.3 仅暴露设备实际支持的画面调节；监听音量/峰值/延迟能做则做，否则隐藏峰值

## 5. 预览 UI：HUD、信箱、沉浸、调节面板

- [x] 5.1 预览按信号宽高比 letterbox，叠加分辨率/帧率/格式 HUD 与无信号文案
- [x] 5.2 增加音频峰值条、音量与延迟控制；无采集音频时隐藏峰值
- [x] 5.3 格式列表、画质档位、图像控件面板；电视可用 D-pad 操作
- [x] 5.4 截图按钮；预览/录制时保持亮屏；沉浸模式隐藏底栏但保留 REC（含大致体积）；电视 Back 先退出沉浸

## 6. 验证

- [x] 6.1 `flutter analyze` 与插件/状态机单测通过
- [x] 6.2 真机：有/无 HDMI、改格式、录制中禁止改格式、截图、调亮度、听声电平与延迟、成片文件名与两档画质
