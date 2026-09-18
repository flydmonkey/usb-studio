## MODIFIED Requirements

### Requirement: Runtime permissions for capture
The app SHALL request camera and microphone permission before opening a USB capture device, and only after the in-app capture disclosure has been confirmed when those permissions are not already granted. The camera and microphone request MUST NOT include notification permission. On Android, the app SHALL also request USB device permission when a candidate UVC device is attached. On Android 13 or later, the app SHALL request notification permission when the operator starts recording, starts RTMP ingest, or enables LAN HTTP playback, not during capture bootstrap. On Android TV, permission prompts SHALL be completable with a remote/D-pad.

#### Scenario: Permissions granted
- **WHEN** the user grants camera, microphone, and (on Android) USB permission
- **THEN** the app proceeds to device discovery and connection

#### Scenario: Permission denied
- **WHEN** the user denies camera, microphone, or USB permission
- **THEN** the app MUST show an actionable error and MUST NOT start preview or recording

#### Scenario: TV remote confirms USB permission
- **WHEN** an Android TV or set-top box shows the USB permission dialog
- **THEN** the user MUST be able to accept or deny it with the remote, and the app MUST reflect the result

#### Scenario: Bootstrap does not request notifications
- **WHEN** the app requests capture permissions at bootstrap
- **THEN** the system prompt MUST include camera and microphone and MUST NOT include notification permission

#### Scenario: Notification requested for foreground capture
- **WHEN** the operator starts recording, starts RTMP ingest, or enables LAN HTTP playback on Android 13 or later without notification permission
- **THEN** the app SHALL request notification permission before starting or keeping the foreground service

## ADDED Requirements

### Requirement: Optional hardware features for TV and phone install
On Android, the merged manifest SHALL declare `android.hardware.camera`, `android.hardware.camera.autofocus`, `android.hardware.microphone`, `android.hardware.wifi`, `android.hardware.usb.host`, `android.hardware.touchscreen`, and `android.software.leanback` with `android:required="false"`. The app MUST remain installable on devices that lack a built-in camera, microphone, or Wi-Fi. The TV home-screen banner SHALL include the product name `USB Studio`.

#### Scenario: Microphone is not required
- **WHEN** a device has USB host but no microphone hardware
- **THEN** Play / PackageManager MUST NOT treat microphone as a required feature of this app

#### Scenario: Wi-Fi is not required
- **WHEN** a television has Ethernet but no Wi-Fi
- **THEN** Play / PackageManager MUST NOT treat Wi-Fi as a required feature of this app

#### Scenario: TV banner shows the product name
- **WHEN** the app is shown on an Android TV launcher
- **THEN** the 320×180 banner artwork SHALL include the text `USB Studio`
