# operator-i18n Specification

## Purpose
Let the operator run USB Studio in Simplified Chinese, Traditional Chinese, Japanese, Korean, or English, following the system language by default with a settings override.

## Requirements
### Requirement: Resolve UI locale from system or operator override
The app SHALL support five UI languages: Simplified Chinese (`zh-Hans`), Traditional Chinese (`zh-Hant`), Japanese (`ja`), Korean (`ko`), and English (`en`). The operator preference `operator.localeMode` SHALL be one of `system`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, or `en`, default `system`. When the mode is `system`, the app SHALL map the device locale as follows: Chinese with script/region Hans, CN, or SG → `zh-Hans`; Chinese with script/region Hant, TW, HK, or MO → `zh-Hant`; Japanese (`ja`) → `ja`; Korean (`ko`) → `ko`. English SHALL be the default whenever the locale cannot be matched, including any other device language, a missing device locale, and an unknown or corrupt `localeMode` value. When the mode is a supported override, the app SHALL use that language regardless of the device locale. Changing the mode SHALL refresh visible UI immediately without reinstalling. Missing translation keys SHALL fall back to English.

#### Scenario: Simplified system maps to Simplified
- **WHEN** `operator.localeMode` is `system` and the device locale is `zh-CN`
- **THEN** the UI SHALL use Simplified Chinese

#### Scenario: Traditional system maps to Traditional
- **WHEN** `operator.localeMode` is `system` and the device locale is `zh-TW`
- **THEN** the UI SHALL use Traditional Chinese

#### Scenario: Japanese system maps to Japanese
- **WHEN** `operator.localeMode` is `system` and the device locale is `ja-JP`
- **THEN** the UI SHALL use Japanese

#### Scenario: Korean system maps to Korean
- **WHEN** `operator.localeMode` is `system` and the device locale is `ko-KR`
- **THEN** the UI SHALL use Korean

#### Scenario: Other system language maps to English
- **WHEN** `operator.localeMode` is `system` and the device locale is `fr-FR`
- **THEN** the UI SHALL use English

#### Scenario: Unmatched preference falls back to English
- **WHEN** the stored `operator.localeMode` is missing or not one of `system`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, or `en`
- **THEN** the UI SHALL use English

#### Scenario: Manual English override
- **WHEN** the operator sets language to English while the device locale is `zh-CN`
- **THEN** the UI SHALL use English until the operator changes the setting

### Requirement: Language control in capture settings
Capture settings SHALL place a language control first. The control SHALL offer Follow system, Simplified Chinese, Traditional Chinese, Japanese, Korean, and English. Television UI mode SHALL allow D-pad activation of the control.

#### Scenario: Operator switches to Traditional
- **WHEN** the operator opens capture settings and selects Traditional Chinese
- **THEN** settings, capture chrome, and subsequent screens SHALL show Traditional Chinese copy

#### Scenario: TV can change language with the remote
- **WHEN** the app is in television UI mode
- **THEN** the operator MUST be able to change the language setting with the D-pad

### Requirement: Localize operator-visible copy
All operator-visible strings SHALL follow the resolved UI locale, including capture chrome, settings, library, readable errors, Android foreground notifications, system share/open chooser titles, and the LAN HTTP home page. The app MUST NOT translate the product name `USB Studio`, recording file names matching `USB_<stamp>`, FourCC or resolution numerals, RTMP URLs, or the save folder `DCIM/UsbCapture`. Traditional Chinese copy SHALL use Taiwan wording.

#### Scenario: English capture bar
- **WHEN** the resolved locale is `en` and a capture session is open
- **THEN** the capture bar actions SHALL appear in English and MUST NOT show Simplified Chinese labels such as 录制

#### Scenario: Notification follows override
- **WHEN** the operator overrides the language to English and recording or LAN playback keeps the foreground service running
- **THEN** the notification text SHALL be English

#### Scenario: Brand name stays
- **WHEN** the resolved locale is `zh-Hant` or `en`
- **THEN** the displayed product name SHALL remain `USB Studio`
