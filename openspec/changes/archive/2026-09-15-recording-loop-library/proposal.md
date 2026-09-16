## Why

预览、录制、中断救片已经能用，但一场一小时的采集仍然断在三处：锁屏或切走进程被杀、整场一个 cache 文件太大、片子只能去系统相册里翻。这三件事必须同一期做完，否则操作员仍然无法独立完成「录完 → 离开手机 → 回来找到文件」。

## What Changes

- Android 录制用前台服务保活：锁屏、切到别的 App、关闭预览都不停录；常驻通知显示正在录制与段号。
- 约每 10 分钟封一段 MP4，立刻写入 `Movies/UsbCapture`，文件名 `USB_yyyyMMdd_HHmmss_01.mp4` 递增。停录只结束当前段，不把多段合成一条。
- 第一次长录引导忽略电池优化（小米等厂商杀后台）。
- App 内片库：列出本应用写入的录像，可播放预览入口、系统分享、删除。电视用大字列表 + D-pad。
- 中断 salvage 仍按段生效：当前段能封装则保存，已发布的前几段不受影响。
- iPad：维持前台录制（不做后台保活）；片库能列出本应用保存到相册的 USB_ 录像并分享/删除。不包含把多段拼成一条、推流、暂停键。

## Capabilities

### New Capabilities

- `recording-library`: 在 App 内列出、分享、删除已保存的采集录像。

### Modified Capabilities

- `session-recording`: 录制在 Android 上于后台继续；按时分段并立即入库；通知与电池优化引导。

## Impact

- Android：`CaptureRecordService` 前台服务（camera / microphone / connectedDevice）、通知、REQUEST_IGNORE_BATTERY_OPTIMIZATIONS、CaptureEngine 迁到服务生命周期、分段 mux。
- Flutter：预览页不因 pause 关闭会话；片库页；REC 显示总时长与当前段号。
- iPad：PHAsset 查询 USB_ 录像；无 UIBackgroundModes 采集。
- 单测覆盖分段序号、片库空态；真机验锁屏续录与片库删除。
