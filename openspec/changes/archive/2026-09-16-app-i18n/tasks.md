## 1. Locale 解析与偏好

- [x] 1.1 增加 `LocaleMode` 与系统 locale → `zh-Hans` / `zh-Hant` / `en` 映射（含 CN/SG/TW/HK/MO）；无法匹配（含无效偏好）默认英文
- [x] 1.2 `OperatorPrefs.localeMode`（键 `operator.localeMode`，默认 `system`）；单测：解析、持久化、未匹配回落英文

## 2. Flutter gen-l10n

- [x] 2.1 配置 `l10n.yaml`、`generate: true`；ARB：`app_en.arb` 模板、`app_zh.arb`、`app_zh_Hant.arb`（台湾用词）
- [x] 2.2 `MaterialApp` 接入 `AppLocalizations`、`locale`、`supportedLocales`；产品名保持 `USB Studio`

## 3. 界面与错误文案

- [x] 3.1 采集页、设置（语言项置顶）、片库、分段/画质/保存位置等 Flutter 写死中文改为 l10n
- [x] 3.2 `CaptureError` 按 code 在 Flutter 翻译；画面控制按 id 翻译，不采用原生中文 label
- [x] 3.3 Widget 测试钉 `zh-Hans` 以免回归失败；增加英文冒烟（采集栏不含「录制」）与语言覆盖刷新

## 4. 原生通知与局域网页

- [x] 4.1 插件 `setUiLocale`；Android `values` / `values-zh-rCN` / `values-zh-rTW` 通知与 chooser 标题；改语言后刷新 FGS
- [x] 4.2 `GET /` 按应用 locale 出文案，忽略浏览器 `Accept-Language`；录像文件名不翻译

## 5. 验证

- [x] 5.1 `flutter test` 与 `:usb_capture:testDebugUnitTest` 通过
- [x] 5.2 红米：系统简体默认简体；改繁体/英文立即生效；通知与局域网页一致；重开应用保持覆盖

## 6. 日文与韩文

- [x] 6.1 `LocaleMode` 增加 `ja` / `ko`；系统 `ja*` / `ko*` 映射；ARB `app_ja.arb` / `app_ko.arb`；设置下拉增加日本語、한국어
- [x] 6.2 Android `values-ja` / `values-ko`；`UiLocale` 识别 ja/ko；单测与采集栏短文案
