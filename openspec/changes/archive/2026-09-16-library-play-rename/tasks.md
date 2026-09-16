## 1. Dart API 与校验

- [x] 1.1 文件名规范化：去空白、补 `.mp4`、拒绝非法字符；同名忽略大小写视为不变
- [x] 1.2 插件 `openRecording` / `renameRecording`、错误文案、capture_logic 单测

## 2. Android / iPad 原生

- [x] 2.1 Android `ACTION_VIEW` 打开系统播放器
- [x] 2.2 Android MediaStore / Downloads / SAF 改 DISPLAY_NAME，重名不覆盖
- [x] 2.3 iPad 系统播放；`renameRecording` 返回不支持

## 3. 片库 UI

- [x] 3.1 点行播放；trailing 按钮不触发播放
- [x] 3.2 Android 重命名对话框；iPad 不显示重命名；电视可 D-pad 聚焦
- [x] 3.3 Widget 测试：点行调用 open；改名后合段入口消失

## 4. 验证

- [x] 4.1 `flutter test` 与相关 Kotlin 单测通过
- [ ] 4.2 红米真机：点行能用系统播放器看片；能改成中文名
