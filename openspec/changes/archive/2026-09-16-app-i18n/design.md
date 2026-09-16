## Context

界面、错误、前台通知和局域网首页目前都写死简体中文（Flutter `lib/`、插件 Dart copy、Kotlin 通知 / chooser、`lan_http/index.html`）。`OperatorPrefs` 已持久化采集习惯，但没有语言项。`MaterialApp` 未配置 `localizationsDelegates` / `locale`。操作员已选择：默认跟系统，设置里可手动覆盖。

## Goals / Non-Goals

**Goals:**

- 三种界面语言：`zh-Hans`、`zh-Hant`、`en`。
- 默认跟系统；设置可改为跟随系统 / 简体 / 繁体 / English，键 `operator.localeMode`，默认 `system`。
- 系统映射：简体区域 → `zh-Hans`；繁体区域 → `zh-Hant`。无法匹配时默认 `en`（含其它系统语言、无效 `localeMode`、缺 ARB 键）。
- 采集页、设置、片库、错误、FGS 通知、分享/打开选择器标题、局域网首页都跟当前解析语言。
- 电视 D-pad 能改语言；改完立即刷新，无需重装。

**Non-Goals:**

- 第四种语言；机器翻译；按浏览器 `Accept-Language` 单独翻局域网页。
- 翻译应用名 `USB Studio`、文件名 `USB_<stamp>`、FourCC、码率数字、推流 URL、目录 `DCIM/UsbCapture`。
- 改 Android 系统级 locale（只改本应用 UI）。

## Decisions

### 1. Flutter `gen-l10n` 为 UI 文案源

- **选择**：`l10n.yaml` + `lib/l10n/app_en.arb`（模板）+ `app_zh.arb` + `app_zh_Hant.arb`；`MaterialApp` 使用 `AppLocalizations` 与 `locale: resolved`。
- **理由**：官方方案，三种语言维护成本低；widget 测试可钉 locale。
- **备选**：手写 `LibraryCopy` 三套 Map。已有 copy 类会继续膨胀，插件与 app 重复。

### 2. 错误码在 Flutter 侧翻译

- **选择**：插件继续返回稳定 `CaptureError` code / details；`AppLocalizations` 按 code 出文案。插件 Dart 里现有中文 `message` 改为 fallback 或删除，避免双源。
- **理由**：通知以外的错误都在 Flutter 展示；测试可对 code 断言而不绑死一种语言。
- **备选**：插件按 locale 返回字符串。Kotlin 与 Dart 要同步三套翻译。

### 3. 覆盖语言时显式同步原生

- **选择**：偏好变更后调用插件 `setUiLocale(bcp47)`；Kotlin 用 `createConfigurationContext` 取 `values` / `values-zh-rCN` / `values-zh-rTW`。`values` 为英文，与系统为 en 时的 Android 惯例一致。
- **理由**：FGS 在独立进程/服务上下文，不会自动跟 `MaterialApp.locale`。
- **备选**：只改 Flutter。锁屏通知会一直是简体。

### 4. 局域网页跟应用语言，不跟浏览器

- **选择**：`GET /` 按当前 `setUiLocale` 注入 `lang` 与文案（一份 HTML + 字典，或服务端替换）。语言随操作员设置，不读 `Accept-Language`。
- **理由**：页面由手机提供，观众看的是现场/成片；YAGNI 不做页内语言切换。
- **备选**：三份静态 HTML。改一处文案要改三份结构。

### 5. 解析规则集中在 Dart

- **选择**：`LocaleMode`: `system` | `zh-Hans` | `zh-Hant` | `en`。`system` 时：`zh` + Hans/`CN`/`SG` → 简体；`zh` + Hant/`TW`/`HK`/`MO` → 繁体。解析结果必须是三种之一；无法匹配（其它系统语言、空 locale、未知或损坏的 `localeMode`）一律 `en`。ARB 模板为英文，缺键时 gen-l10n 回落到英文。繁体用台湾用词（設定、錄製、檔案）。
- **理由**：英文是唯一不依赖地区变体的兜底；操作员在日语等系统上仍能读界面，再在设置里改中文。
- **备选**：无法匹配时用简体。与「跟系统」冲突，非中文设备会突然全是中文。

### 6. 设置入口放在采集设置顶部

- **选择**：语言下拉为设置第一项，选项文案自身用目标语言书写（「跟随系统 / Follow system」等），电视可 D-pad 选。
- **理由**：系统语言不是中文时，操作员仍能找到 Language。
- **备选**：放在最底部。与「不常用项靠下」冲突较少，但找语言更慢。

## Risks / Trade-offs

- [漏翻一处写死中文] → 任务按文件清单清扫；测试在 `en` locale 下抽查关键按钮不含「录制」「片库」。
- [覆盖语言后通知仍简体] → `setUiLocale` 后立即 `updateNotification`。
- [widget 测试大面积失败] → 测试 `MaterialApp` 钉 `zh-Hans`，另加 locale 解析与英文冒烟。
- [简繁用词争议] → 繁体固定台湾用词，不提供港版。

## Migration Plan

无破坏性数据迁移。新键 `operator.localeMode` 缺省 `system`：简体系统设备升级后界面仍为简体。回滚即去掉 locale 覆盖，恢复写死中文（不作为发布路径）。

## Open Questions

无。语言来源已由操作员确认为「跟系统 + 设置覆盖」。
