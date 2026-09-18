# Notes for Google Play reviewers

USB Studio (`io.github.flydmonkey.usbstudio`) is a **USB HDMI capture-card** app. Reviewers usually do not have a UVC capture dongle. The app must still launch, show an empty state, and open Settings / Privacy policy / Library without a card.

## Hardware

- UVC HDMI capture card (USB Video Class). Audio is typically UAC from the same dongle.
- Phone/tablet: USB OTG. TV/box: USB Host. Some TV USB ports only accept flash drives; the app then shows a specific error.
- A powered hub may be required.
- This is **not** a built-in camera app.

## Demo video

`[TODO: paste YouTube or Drive link showing preview, record, library, RTMP, LAN playback]`

Until the video is uploaded, the no-card paths below are enough to confirm the APK is not broken.

## What to do without a capture card

1. Launch. Grant or deny after the in-app explanation (Camera + Microphone are for the USB card, not the selfie camera).
2. See the empty state asking to insert a USB capture card. The app must not crash or stay on a blank camcorder viewfinder.
3. Open **Settings** (including on TV with D-pad): language, recording, Privacy policy, Terms of use.
4. Open **Library** (empty state is OK).
5. Optional: enable LAN playback; the UI should show an HTTP URL or “connect to Wi-Fi”. This server is local and unencrypted.

## Permissions

- **CAMERA:** Android 9+ requires it to access USB video devices (UVC). The app does not open the built-in selfie/rear camera as the capture source.
- **RECORD_AUDIO:** Capture-card audio.
- **POST_NOTIFICATIONS:** Requested when recording, RTMP, or LAN playback starts, so a foreground service notification can stay up.
- **Foreground service types:** camera / microphone / connectedDevice while capturing; mediaPlayback when only LAN playback is on.
- **REQUEST_IGNORE_BATTERY_OPTIMIZATIONS:** Optional, after a user-facing dialog, so lock-screen recording is not killed. Do not treat a “Not now” as a failure.

## TV

The same package includes `LEANBACK_LAUNCHER`. Banner includes the name **USB Studio**. Camera, microphone, autofocus, and Wi-Fi are declared `required="false"` so TVs without those sensors can install.

## Contact

shunsora@outlook.com
