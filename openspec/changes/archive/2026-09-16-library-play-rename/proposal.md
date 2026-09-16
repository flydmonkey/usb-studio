## Why

片库列表目前点一行没有任何反应，操作员无法回看成片；文件名又固定为 `USB_` 时间戳，事后没法改成可读的中文名。回看和改名是片库日常操作，比继续加采集能力更急。

## What Changes

- 点片库一行（标题区域）用系统播放器打开该 MP4，而不是应用内播放器。
- 行尾增加「重命名」：对话框改显示名，真正改磁盘/相册文件名；未写扩展名时自动补 `.mp4`。
- 非法字符、空名、与已有文件重名时提示且不覆盖。
- 改掉 `USB_<stamp>_<NN>.mp4` 形态后，「合并本场」按现有规则消失。操作员已接受这一代价。
- iPad 支持系统播放；重命名仅 Android（Photos 不能改 originalFilename）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `recording-library`: 列表行可播放；Android 可重命名列出的录像。

## Impact

- Flutter `LibraryPage`：`onTap` 播放，重命名对话框与文案。
- 插件：`openRecording`、`renameRecording`；Android `ACTION_VIEW` 与 MediaStore/SAF 改名；iPad 打开系统播放、重命名返回不支持。
- Widget / 插件单测覆盖播放调用与改名校验。
