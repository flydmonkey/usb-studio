# USB 采集

Flutter 应用：预览 USB 采集卡的画面和声音，并可录制成 MP4。

支持 USB-C iPad（iPadOS 17+）、Android 手机/平板（USB OTG）和 Android TV / 电视盒（USB Host）。iPhone 无法采集。

## 运行

```bash
flutter pub get
flutter run
```

Android 调试包：

```bash
flutter build apk --debug
```

## 真机注意

- 采集卡需为 UVC/UAC。供电不足时请用带供电的 USB Hub。
- 不少电视 USB 只能插 U 盘，打开失败时会提示，而不是黑屏。
- 本机若无采集卡，可先跑 `flutter test`；硬件步骤见 `test/hardware_acceptance_test.dart`。
