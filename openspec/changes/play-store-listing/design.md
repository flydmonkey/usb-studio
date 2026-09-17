## Context

采集、录制、推流、局域网播放已经能用。上架卡在政策与发布工程：没有公网/应用内隐私政策；`_bootstrap` 一启动就 `requestPermissions()`，把相机、麦克风和 Android 13+ 通知绑在一起；Manifest 只把 `camera` 标成非必需，麦克风和 Wi-Fi 仍会隐含成必需硬件；release 仍用 debug 签名，仓库里也没有商店文案和 Data safety 草稿。手机和电视继续共用同一包，不撤 `LEANBACK_LAUNCHER`。

## Goals / Non-Goals

**Goals:**

- 应用内与 Play Console 使用同一份可公开访问的隐私政策。
- 首次申请相机/麦克风前先说明用途（USB 采集卡，不是自拍摄像头）；通知权限延后到需要前台服务时。
- 设置可打开隐私政策、开源许可，并显示版本号。
- 电视可安装：麦克风、自动对焦、Wi-Fi 均为非必需；banner 带应用名。
- 仓库提供隐私政策正文、商店文案、Data safety、审核备注；release 用正式签名打 AAB。

**Non-Goals:**

- 账号、内购、广告、分析 SDK、把录像上传到开发者服务器。
- 拆成两个包（手机 / 电视分开上架）。
- 实现 GitHub Pages 托管流水线（文档写清发布步骤即可）。
- 改采集算法或新增采集功能。

## Decisions

### 1. 隐私政策以仓库 Markdown 为源，应用打开公网 URL

- **选择**：正文放 `docs/play/privacy.md`（中英对照）。应用常量 `privacyPolicyUrl` 打开同一公网地址（GitHub Pages 或等价静态页，禁止 PDF）。设置「隐私政策」用系统浏览器/`url_launcher` 打开。Play Console 填同一 URL。
- **理由**：政策要求商店页和应用内都能访问；一份源避免 Data safety 和应用内说法不一致。
- **备选**：应用内嵌离线全文。离线副本容易和公网页漂移，且审核仍要公网 URL。

### 2. 首次说明对话框，确认后再申请相机和麦克风

- **选择**：冷启动若尚未授予 `CAMERA`/`RECORD_AUDIO`，先弹出可 D-pad 操作的说明（用途 + 继续 / 暂不）。点继续才调现有 `requestPermissions()`，且该方法不再附带 `POST_NOTIFICATIONS`。拒绝或关掉说明 → 现有 `permissionDenied` 空状态，可从该状态再走说明。已经授权则跳过说明。
- **理由**：政策要求敏感权限先披露、再按场景申请。采集是核心功能，启动时要相机/麦克风说得通，但不能和通知捆在一起。
- **备选**：每次进预览都说明。已经授权的用户会被反复打断。

### 3. 通知权限跟前台服务走

- **选择**：开始录制、开始推流、打开局域网播放时，若 Android 13+ 尚未授予通知权限，再申请 `POST_NOTIFICATIONS`。不为此单独做第二套长说明（系统会显示用途为通知）。
- **理由**：通知只为 FGS 保活，不是采集前置条件。
- **备选**：继续在启动时一起要。容易被判「一次要过多权限」。

### 4. 关于区放在设置底部

- **选择**：设置最后一组「关于」：版本（`package_info_plus` 读 `versionName`）、隐私政策、开源许可（Flutter `showLicensePage`）。不新增独立 About 路由。
- **理由**：语言仍在最上方；法律入口不挡日常采集设置。电视 D-pad 能滚到底部。
- **备选**：独立 About 页。对当前单页设置结构过重。

### 5. Manifest 补齐隐含硬件为非必需；banner 印应用名

- **选择**：在 app 与 plugin Manifest 增加 `microphone`、`camera.autofocus`、`wifi`，皆 `required="false"`。保留现有 `camera` / `usb.host` / `touchscreen` / `leanback` 非必需。`tv_banner` 仍 320×180，叠上 `USB Studio` 字样（品牌不翻译，不必做多语言 banner）。
- **理由**：`RECORD_AUDIO` / `CAMERA` / `ACCESS_WIFI_STATE` 会隐含硬件，不声明 false 会把无麦电视和有线电视滤掉。
- **备选**：去掉 `LEANBACK_LAUNCHER` 只上手机。第一版拒审面更小，但已做 10 英尺布局，提案选择一起送。

### 6. 上架材料进 `docs/play/`，签名不进 git

- **选择**：
  - `docs/play/store-listing.md`：短描述、完整描述（五种界面语言）、截图要点、相机权限说明句。
  - `docs/play/data-safety.md`：按「开发者不收集；本机媒体；用户主动 RTMP；局域网未加密 HTTP」填写。
  - `docs/play/reviewer-notes.md`：硬件、权限理由、无卡可走路径、演示视频待填。
  - `android/key.properties` + `*.jks` gitignore；`build.gradle.kts` 读该文件做 release 签名；文档说明 `flutter build appbundle`。
- **理由**：代码解决不了 Play Console 表单，但文案必须和实现一致。
- **备选**：只在聊天里给文案。无法版本化，容易和后续功能漂移。

## Risks / Trade-offs

- [审核员没有采集卡，判「应用不能用」] → 无卡空状态保持可操作；审核备注写清硬件与演示视频；设置/隐私政策/片库不插卡也能打开。
- [相机权限被当成未使用后置摄像头] → 说明对话框、商店描述、审核备注都写 Android 9+ 访问 UVC 需要 `CAMERA`。
- [忽略电池优化被打回] → 已有用户确认对话框，不在启动时静默跳系统页；审核备注说明锁屏续录。
- [GitHub Pages 未开，隐私 URL 404] → 上架前必须先发布静态页；应用常量集中一处，改 URL 不必改 UI。
- [隐私政策开发者名称与 Play 账号不一致] → `privacy.md` 用占位「Play 开发者账号显示名」，发布前人工填实。
- [16 KB 页对齐回归] → 打 AAB 后用 Play 预启动报告确认 UVC 原生库。

## Migration Plan

无用户数据迁移。升级后已授权相机/麦克风的用户不再看到首次说明。未授权用户会先看到说明再出系统权限框。回滚：去掉对话框与关于区，权限恢复启动时一次申请（不作为发布路径）。

## Open Questions

- 公网隐私政策的确切 URL（取决于 GitHub Pages 或自有域名）——实现时用单一常量，文档写发布步骤。
- Play 开发者账号显示名 / 联系邮箱——隐私政策和商店页发布前填入 `docs/play/privacy.md` 占位符。
