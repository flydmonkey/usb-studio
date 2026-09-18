# usb-capture-device Specification

## Purpose
Request permissions, discover UVC capture cards, handle hotplug, and fail with specific errors instead of a blank session.

## Requirements
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

### Requirement: Discover connected capture devices
The app SHALL list currently attached USB Video Class capture devices (and their associated audio if exposed) after permissions are granted. If multiple devices are present, the app SHALL let the user select one.

#### Scenario: One capture card attached
- **WHEN** exactly one supported capture device is attached and permissions are granted
- **THEN** the app SHALL present that device as available and MAY connect to it automatically

#### Scenario: Multiple devices attached
- **WHEN** more than one supported capture device is attached
- **THEN** the app SHALL show a selectable list and MUST NOT open more than one at a time

#### Scenario: No device attached
- **WHEN** no supported capture device is attached
- **THEN** the app SHALL show an empty state that tells the user to plug in a UVC capture card

### Requirement: Hotplug connect and disconnect
The app SHALL update device availability when a capture card is plugged in or unplugged. If the active device disconnects, the app SHALL stop preview and recording and show that the device was removed.

#### Scenario: Plug in while app is open
- **WHEN** a supported capture card is attached while the app is in the foreground
- **THEN** the app SHALL add it to the device list without requiring an app restart

#### Scenario: Unplug active device
- **WHEN** the currently open capture card is unplugged
- **THEN** the app SHALL stop preview, abort any in-progress recording, and show a disconnected state

### Requirement: Unsupported hardware
On Android, if USB Host/OTG is missing, UVC isochronous transfer fails, or the device cannot be opened (including insufficient power), the app SHALL show a specific error rather than a blank preview. Errors about power SHALL mention using a powered USB hub when needed.

#### Scenario: Android without USB Host
- **WHEN** the Android device does not provide USB Host
- **THEN** the app MUST show that the hardware cannot use a USB capture card

#### Scenario: UVC open fails on TV or phone
- **WHEN** a USB device is attached but the app cannot start a UVC stream (including isochronous or power failure)
- **THEN** the app MUST show a non-blank error explaining the failure and, when power is a likely cause, mention a powered USB hub

