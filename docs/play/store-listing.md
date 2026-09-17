# Play Store listing copy

Privacy policy URL (Play Console and in-app):  
https://flydmonkey.github.io/usb-studio/privacy.html  

Source: `docs/privacy.html`. Enable GitHub Pages on branch `master`, folder `/docs`. Play developer name: **flydmonkey**. Contact: **shunsora@outlook.com**.

**Camera permission (paste into the Play Console declaration / listing):**  
On Android 9+, Camera permission is required to access a USB Video Class (UVC) capture device. USB Studio does not use the built-in selfie or rear camera as the capture source.

## Short description (max 80 characters)

| Locale | Copy |
| --- | --- |
| en | Preview, record, and stream HDMI from a USB capture card on phone or TV. |
| zh-CN | 用 USB 采集卡在手机或电视上预览、录制 HDMI，并可推流或局域网播放。 |
| zh-TW | 用 USB 擷取卡在手機或電視上預覽、錄製 HDMI，並可推流或區域網播放。 |
| ja | USBキャプチャカードでHDMIをプレビュー・録画。配信とLAN再生にも対応。 |
| ko | USB 캡처 카드로 HDMI를 미리보고 녹화하며, 송출과 LAN 재생을 지원합니다. |

## Full description

### English

USB Studio connects an HDMI USB capture card to your Android phone, tablet, or TV. Preview the UVC picture, monitor the card's audio, take a snapshot, record H.264 + AAC MP4, push RTMP/RTMPS, or watch on another device on the same Wi-Fi.

This app is for USB capture cards (UVC, usually with UAC audio). It does not capture the phone's built-in camera.

You need:

- Android 7.0 or later
- A UVC HDMI capture card
- USB OTG on phones/tablets, or USB Host on TVs and boxes
- A powered USB hub if the port cannot supply enough power

On Android 9 and later, Camera permission is required so the system can grant USB video access. Microphone permission is for the capture card's audio. The app explains this before asking.

Features:

- Live preview with no-signal messaging instead of a blank screen
- Monitor volume, mute, and 0–200 ms delay
- Snapshots of the capture picture (not the app UI)
- Segmented MP4 recording that can continue after lock or backgrounding
- Library: open, share, rename, delete, merge segments from the same session
- RTMP/RTMPS streaming, which can run at the same time as local recording
- Optional LAN HTTP playback (not encrypted, not exposed to the public internet)

Not supported: iOS, desktop, built-in camera, RTSP/SRT/WebRTC.

### 简体中文

USB Studio 把 HDMI USB 采集卡接到 Android 手机、平板或电视上：预览 UVC 画面、监听采集卡声音、截图、录成 H.264 + AAC 的 MP4，也可以推 RTMP/RTMPS，或在同一 Wi-Fi 下用浏览器看。

本应用只用于 USB 采集卡（UVC，通常带 UAC 音频），不用手机自带摄像头。

需要：Android 7.0+；UVC HDMI 采集卡；手机/平板用 USB OTG，电视/盒子用 USB Host；供电不足时用带供电的 USB Hub。

Android 9 及以上必须有相机权限，系统才会允许访问 USB 视频设备。麦克风权限用于采集卡音频。申请前应用内会说明。

不支持：iOS、桌面、内置摄像头、RTSP/SRT/WebRTC。局域网播放未加密、不穿透公网。

### 繁體中文

USB Studio 把 HDMI USB 擷取卡接到 Android 手機、平板或電視：預覽 UVC 畫面、監聽擷取卡聲音、截圖、錄成 H.264 + AAC 的 MP4，也可以推 RTMP/RTMPS，或在同一 Wi-Fi 下用瀏覽器看。

本應用只用於 USB 擷取卡，不用手機內建相機。Android 9 以上需要相機權限才能存取 USB 視訊裝置。麥克風權限用於擷取卡音訊。

不支援 iOS、桌面、內建相機。區域網播放未加密、不穿透公網。

### 日本語

USB Studio は HDMI USB キャプチャカードを Android のスマホ・タブレット・テレビに接続します。UVC 映像のプレビュー、音声モニター、スナップショット、H.264 + AAC の MP4 録画、RTMP/RTMPS 配信、同じ Wi-Fi 上のブラウザ再生に対応します。

内蔵カメラは使いません。Android 9 以降では USB 映像デバイスへのアクセスにカメラ権限が必要です。マイク権限はキャプチャカードの音声用です。

非対応: iOS、デスクトップ、内蔵カメラ、RTSP/SRT/WebRTC。LAN 再生は暗号化されず、インターネット公開もしません。

### 한국어

USB Studio는 HDMI USB 캡처 카드를 Android 휴대폰, 태블릿, TV에 연결합니다. UVC 화면 미리보기, 캡처 카드 소리 모니터, 스냅샷, H.264+AAC MP4 녹화, RTMP/RTMPS 송출, 같은 Wi-Fi의 브라우저 재생을 지원합니다.

기본 카메라는 사용하지 않습니다. Android 9 이상에서는 USB 비디오 장치에 접근하려면 카메라 권한이 필요합니다. 마이크 권한은 캡처 카드 오디오용입니다.

지원하지 않음: iOS, 데스크톱, 내장 카메라, RTSP/SRT/WebRTC. LAN 재생은 암호화되지 않으며 공인 인터넷으로 노출되지 않습니다.

## Screenshots to capture

Phone (at least 2, better 4–8): empty state with “insert capture card”; live preview + record; settings (including About / privacy); library.

TV (required while `LEANBACK_LAUNCHER` is present): 10-foot preview; settings reachable with D-pad; TV banner showing **USB Studio**.

Do not imply the built-in camera is the source. Show a capture card or HDMI source in at least one shot.

## Graphic assets (Play Console, not in the APK)

- High-res icon: 512 × 512 PNG
- Feature graphic: 1024 × 500 PNG
- TV banner in the APK is 320 × 180 (`android:banner`)
