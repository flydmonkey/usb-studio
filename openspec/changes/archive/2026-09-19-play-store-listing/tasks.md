## 1. 隐私政策与商店材料

- [x] 1.1 写 `docs/play/privacy.md`（中英对照，含相机/麦克风、本机媒体、RTMP、局域网、无账号/无分析；开发者名与邮箱用占位符）
- [x] 1.2 写 `docs/play/store-listing.md`（五种语言短描述/完整描述、截图要点、UVC 需要相机权限的说明）
- [x] 1.3 写 `docs/play/data-safety.md` 与 `docs/play/reviewer-notes.md`（无卡路径、硬件、FGS、电池优化、演示视频待填）

## 2. Manifest 与电视 banner

- [x] 2.1 app 与 plugin Manifest 声明 `camera` / `camera.autofocus` / `microphone` / `wifi` / `usb.host` / `touchscreen` / `leanback` 均为 `required="false"`
- [x] 2.2 更新 `tv_banner`：320×180，带产品名 `USB Studio`

## 3. 权限说明与通知延后

- [x] 3.1 `requestPermissions` 只申请相机和麦克风，不再带 `POST_NOTIFICATIONS`
- [x] 3.2 未授权时先弹出可 D-pad 的首次说明，确认后再申请；拒绝保持 `permissionDenied`；已授权则跳过
- [x] 3.3 开始录制、推流或打开局域网播放时再申请 Android 13+ 通知权限
- [x] 3.4 Widget 测试：未授权先出说明、确认后才调插件、已授权跳过、无卡仍可开设置

## 4. 设置关于区

- [x] 4.1 增加 `privacyPolicyUrl` 常量、`url_launcher` / `package_info_plus`；设置底部关于：版本号、隐私政策、开源许可
- [x] 4.2 五种语言 ARB 文案（说明对话框 + 关于区）；产品名保持 `USB Studio`

## 5. 签名与 AAB

- [x] 5.1 `key.properties` / keystore 加入 gitignore；release 从该文件读签名，去掉 debug 签名
- [x] 5.2 文档记录 `flutter build appbundle`；README 增加上架材料与隐私 URL 发布步骤

## 6. 验证

- [x] 6.1 `flutter test` 与 `:usb_capture:testDebugUnitTest` 通过
- [ ] 6.2 真机：首次说明 → 相机/麦克风；录制时才要通知；设置能打开隐私政策和许可；无卡可完成上述路径
