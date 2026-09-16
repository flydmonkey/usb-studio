## 1. 偏好与单测

- [x] 1.1 `OperatorPrefs` / `AutoRecordPolicy`：分段预设、自动开录推迟规则、预览声音三项持久化字段
- [x] 1.2 单测：0 分钟不分段文件名与 REC 文案；手动停止后不自动开录，重连后会

## 2. 原生分段

- [x] 2.1 Android `startRecording(segmentMinutes)`：0 不分段且通知不显示段号
- [x] 2.2 iPad 同样按分钟分段或整场单文件

## 3. Flutter

- [x] 3.1 设置页：分段预设、自动开录、预览声音；与底部静音、音量、延迟同步并保存
- [x] 3.2 连接成功后恢复监听；允许时自动开录
- [x] 3.3 `flutter analyze` 与单测通过后安装到真机
