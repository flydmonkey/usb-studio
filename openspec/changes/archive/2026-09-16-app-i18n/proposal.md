## Why

操作界面、错误提示、前台通知和局域网播放页目前全部写死简体中文。系统语言为繁体或英语的操作员无法看懂，也无法在应用内改语言。需要三种界面语言：简体中文、繁体中文、英文。

## What Changes

- 支持三种界面语言：简体中文（`zh-Hans`）、繁体中文（`zh-Hant`）、英文（`en`）。
- 默认跟随系统语言；采集设置增加「语言」选项，可改为跟随系统 / 简体中文 / 繁體中文 / English，并持久化。
- 系统语言映射：简体（含 `zh-CN` / `zh-SG` / `zh-Hans`）→ 简体；繁体（含 `zh-TW` / `zh-HK` / `zh-MO` / `zh-Hant`）→ 繁体。无法匹配到这三种之一时（其它系统语言、无效偏好、缺翻译）一律用英文作为默认语言。
- 操作员可见文案全部走本地化：采集页、设置、片库、错误、前台通知、系统分享/打开选择器标题、局域网 HTTP 首页。
- 不翻译：应用名 `USB Studio`、录像文件名 `USB_<stamp>`、FourCC / 分辨率数字、推流 URL。
- 不增加其它语言；不做运行时自动翻译；不改存储路径 `DCIM/UsbCapture`。

## Capabilities

### New Capabilities

- `operator-i18n`: 三种语言、系统映射、设置覆盖、覆盖范围（含原生通知与局域网页）及不翻译项。

### Modified Capabilities

- `operator-prefs`: 持久化语言选择（默认跟随系统）。
- `lan-http-playback`: 局域网首页文案跟随应用当前语言。

## Impact

- Flutter：`gen-l10n` ARB、`MaterialApp.locale`、设置语言项、`OperatorPrefs`；现有写死中文的 UI / 插件 Dart 文案改为按 locale 取值。
- Android：`values` / `values-zh-rCN` / `values-zh-rTW` 通知与 chooser 标题；插件需知道当前语言。
- 局域网：`index.html` 文案随应用语言生成或分语言资源。
- 测试：widget / 单元测试钉死 locale，避免默认中文断言失效。
