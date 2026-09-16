## 1. 状态机与 UI

- [x] 1.1 单测：中断且有可救文件时会话退出 recording，并带「已保存」；无可救文件时退出 recording 且不得声称已保存
- [x] 1.2 预览页在 `recordingSaved` 之后收到 `disconnected`/`error` 时，清除 REC，状态同时说明中断原因和保存结果

## 2. Android salvage

- [x] 2.1 `handleDisconnect` / `close` 在录制中改为 salvage（mux + MediaStore），不再 `save = false` 丢 temp
- [x] 2.2 `VideoCapture.onError` 走同一 salvage；成功发 `recordingSaved` 再发 `error`/`disconnected`；temp 为空或 mux 失败则只报失败
- [x] 2.3 `stopRecording` 超时仍尝试发布非空视频文件（可视频-only）

## 3. iPad 对齐

- [x] 3.1 断开或 close 时先 `stopRecording` 并等待完成回调写入 Photos，再 `session.stopRunning`
- [x] 3.2 成功发 `recordingSaved`，再发 `disconnected`；无文件则只发中断/失败

## 4. 验证

- [x] 4.1 `flutter analyze` 与相关单测通过
- [x] 4.2 真机：录制中拔卡，影片库出现可播 MP4，UI 离开录制态并提示已保存；刚开录立刻拔卡（无内容）不得提示已保存
