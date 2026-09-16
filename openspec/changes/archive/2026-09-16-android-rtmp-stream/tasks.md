## 1. Dart API 与偏好

- [x] 1.1 `StreamUrl.join`：两栏拼接、`rtmp/rtmps` 校验；`CaptureErrorCode.streamFailed` 文案
- [x] 1.2 插件 `startStream` / `stopStream`；`PlatformProfile.rtmpStreamSupported`；事件 `streamStarted` / `streamStopped`
- [x] 1.3 `OperatorPrefs` 持久化地址与密钥；`SessionState` 推流状态；格式/画质在推流中锁定

## 2. Android / iPad 原生

- [x] 2.1 JitPack RootEncoder rtmp、`INTERNET`；`RtmpStreamSession` 双编码推流
- [x] 2.2 与录像共用 FGS；拔卡/无信号/连接失败停推
- [x] 2.3 iPad `streamUnsupported`

## 3. 采集 UI

- [x] 3.1 采集栏推流开关；设置两栏；LIVE 角标
- [x] 3.2 Widget / 逻辑单测：拼接、缺字段、与录像并存、iPad 无按钮

## 4. 验证

- [x] 4.1 `flutter test` 与 Kotlin 单测通过
- [ ] 4.2 红米安装：填地址密钥能推；可同时录像；无信号/停推可读
