## 1. 插件 API 与单测

- [x] 1.1 Dart：`listRecordings` / `shareRecording` / `deleteRecording`、分段事件（segment index / elapsed）、电池优化提示事件
- [x] 1.2 单测：分段序号从 01 递增、中断 salvage 不丢掉已发布段、片库空态与删除确认文案

## 2. Android 前台服务与分段

- [x] 2.1 `CaptureRecordService`：startForeground（camera|microphone|connectedDevice），通知显示时长与段号，点通知回 Activity
- [x] 2.2 引擎生命周期改到服务；Flutter `onPause` 不得 close；停止录制或断开后停服务
- [x] 2.3 约 10 分钟停当前 mux、publish `USB_<stamp>_NN.mp4`、相机不关并开下一段；失败则 salvage 当前段并结束会话
- [x] 2.4 首次开录检测电池优化，发一次性引导事件；SharedPreferences 记住已提示

## 3. Android 片库

- [x] 3.1 MediaStore 查询 `Movies/UsbCapture`，返回 id/name/uri/duration 或 size
- [x] 3.2 删除走 ContentResolver；分享走系统 Intent

## 4. iPad 对齐（前台）

- [x] 4.1 前台同样 10 分钟分段并写入 Photos；后台不做保活
- [x] 4.2 列出 USB_ 录像并支持分享/删除（系统做不到的能力则隐藏按钮并说明）

## 5. Flutter UI

- [x] 5.1 预览页 REC 显示总时长与「第 N 段」；进入片库入口（电视可 D-pad）
- [x] 5.2 片库页：列表、空态、分享、删除确认；电视大字与过扫边距
- [x] 5.3 电池优化一次性对话框

## 6. 验证

- [x] 6.1 `flutter analyze` 与单测通过
- [x] 6.2 真机：锁屏/切走续录至少 10 分钟以上并产生多段；片库能看、分享、删除；拔线只丢当前段
