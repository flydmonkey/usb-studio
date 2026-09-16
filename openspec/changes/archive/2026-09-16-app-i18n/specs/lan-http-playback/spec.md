## ADDED Requirements

### Requirement: LAN home page follows app UI locale
The LAN HTTP home page (`GET /`) SHALL render chrome, live status, empty states, and errors in the same resolved UI locale as the Android app (`zh-Hans`, `zh-Hant`, or `en`). The page MUST NOT choose language from the browser `Accept-Language` header. Recording display names in the list SHALL remain the on-disk / MediaStore names. The product name `USB Studio` SHALL stay untranslated.

#### Scenario: English app serves English home page
- **WHEN** the resolved app locale is `en` and a browser on the same Wi-Fi opens the displayed URL
- **THEN** the home page headings and live waiting copy SHALL be English

#### Scenario: Browser language does not override
- **WHEN** the resolved app locale is `zh-Hans` and the browser sends `Accept-Language: en`
- **THEN** the home page SHALL still use Simplified Chinese
