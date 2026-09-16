## Context

片库行目前只有分享、删除和（Android）合并，`ListTile` 没有 `onTap`。分享走 `ACTION_SEND`。文件名由录制策略写成 `USB_<stamp>[_NN].mp4`，合段也靠这个文件名识别同一场。操作员要回看时点行没反应；也要把成片改成中文名。

## Goals / Non-Goals

**Goals:**

- 点列表标题/整行，用系统播放器打开该 MP4。
- Android 真改文件名；自动补 `.mp4`；非法名与重名失败且不覆盖。
- 改掉分段文件名后，合并入口按现有 `SegmentPolicy` 消失。
- 电视可用 D-pad 点行播放、打开重命名对话框。

**Non-Goals:**

- 应用内播放器、缩略图、进度条。
- iPad 重命名（Photos 资源名不可改）。
- 改录制时的默认命名；合段后自动改名。
- 复制一份再删旧文件的「伪重命名」。

## Decisions

### 1. 播放走系统 Intent / 系统播放界面

- **选择**：Android `ACTION_VIEW` + `video/mp4` + `FLAG_GRANT_READ_URI_PERMISSION`，必要时 `Intent.createChooser`。iPad 用 `AVPlayerViewController`（或等价系统播放）打开该资源 URL。插件方法 `openRecording(id)`。
- **理由**：操作员明确要系统播放器，不要应用内解码。与现有 `shareRecording` 同 URI 解析。
- **备选**：应用内 `video_player`。加依赖、要处理旋转和电视焦点。

### 2. 点行播放，图标按钮不抢播放

- **选择**：`ListTile.onTap` 播放。分享 / 删除 / 合并 / 重命名仍是 trailing `IconButton`（电视可聚焦）。
- **理由**：回看是主操作。点图标不会触发 `onTap`。
- **备选**：单独播放图标。多一个控件，主操作仍不明显。

### 3. 重命名是 MediaStore / SAF 改 DISPLAY_NAME

- **选择**：Dart 先规范化名字（去空白、禁止 `\ / : * ? " < > |` 和控制符、保证 `.mp4`）。同名（忽略大小写）视为成功不写盘。Android：MediaStore `ContentResolver.update` `DISPLAY_NAME`；Downloads 同类；SAF `DocumentFile.renameTo`。冲突或系统拒绝 → `renameTaken` / `renameFailed`。插件 `renameRecording(id, displayName)`。
- **理由**：相册和文件管理器里名字跟着变。操作员要的是真改名。
- **备选**：只存显示别名。系统相册仍是 USB_ 名，对不上。

### 4. iPad 只播不改名

- **选择**：片库在 iPad 仍显示重命名入口则调用后返回 `renameUnsupported`；或隐藏按钮。实现上隐藏更干净（与合段一致）。
- **理由**：`PHAssetResource.originalFilename` 不能当文件重命名 API。
- **备选**：导出副本。占空间、列表重复。

## Risks / Trade-offs

- [MIUI 可能没有默认播放器 / 拒绝 URI] → 可读 `playFailed`，文件不动。
- [MediaStore 改名在部分 Android 版本失败] → 提示失败，不删原文件。
- [改名后合不了] → 已确认可接受；合并仍只认 `USB_<stamp>_<NN>.mp4`。
- [电视上输入中文费劲] → 仍提供对话框，系统 IME 负责。

## Migration Plan

无数据迁移。已有 USB_ 文件可立即播放和改名。

## Open Questions

无。
