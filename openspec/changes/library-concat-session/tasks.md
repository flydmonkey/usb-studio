## 1. 分组与插件 API

- [x] 1.1 Dart：`SegmentPolicy` 解析 session stamp / `_NN`、判断一场可否合并、生成 `USB_<stamp>.mp4` 与占用时的 `_merged` 名
- [x] 1.2 插件增加 `concatSession`（接收 stamp + 分段 uri 列表）；iOS 返回明确不支持
- [x] 1.3 单测：两段可合、单段不可合、无后缀文件不是分段、命名冲突走 `_merged`

## 2. Android remux

- [x] 2.1 `MediaExtractor` + `MediaMuxer` 按 `_NN` 顺序拷贝视频/音频样本，时间戳接在上一段之后
- [x] 2.2 先写 cache，成功后再 `CaptureSave.publishMovie`；失败删 cache、不碰原分段
- [x] 2.3 这场正在录制则拒绝；轨道不一致、读失败、空间不足返回可读错误
- [ ] 2.4 用两段小 MP4 验证合成片可解析且原文件仍在

## 3. 片库 UI

- [x] 3.1 Android 片库平铺列表：同一场 ≥ 2 段时任一行显示「合并本场」；iPad 隐藏
- [x] 3.2 合并中显示进度；完成后刷新列表；失败 snack/对话框说明原因
- [x] 3.3 电视布局下合并按钮可 D-pad 聚焦
- [x] 3.4 Widget 测试：两段出现合并、单段不出现、点合并会调插件

## 4. 真机

- [ ] 4.1 红米上对已有分段点合并，合成片能播，原 `_01/_02` 还在，再合一次得到 `_merged`
