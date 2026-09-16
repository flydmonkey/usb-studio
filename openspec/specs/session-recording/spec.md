# session-recording Specification

## Purpose
Optionally record the open capture session to an H.264+AAC MP4 in the system library, with or without live preview visible.

## Requirements
### Requirement: Optional start and stop recording
The user SHALL be able to start recording the current capture session and stop it later. Recording MUST be optional: preview SHALL work without recording. Preview MUST also be optional: recording SHALL work while the capture device is open even if live preview is turned off. On television UI mode, start and stop SHALL be activatable with a remote/D-pad together with snapshot and mute on the capture bar. While recording, the app SHALL show a recording indicator and elapsed time.

#### Scenario: Start recording from preview
- **WHEN** preview is running and the user starts recording
- **THEN** the app SHALL begin capturing the current video and capture-card audio to a file and show recording state with elapsed time

#### Scenario: Start recording with preview off
- **WHEN** a capture device is connected, live preview is turned off, and the user starts recording
- **THEN** the app SHALL begin recording the capture session and MUST NOT require the preview surface to be visible

#### Scenario: Stop recording
- **WHEN** recording is in progress and the user stops recording
- **THEN** the app SHALL finalize the file, leave the capture session open, and clear the recording indicator

#### Scenario: Cannot start without a connected device
- **WHEN** no capture device is connected
- **THEN** the app MUST NOT start a recording session

#### Scenario: TV remote starts and stops
- **WHEN** the app is in television UI mode and a capture device is connected
- **THEN** the user MUST be able to start and stop recording with the remote/D-pad

### Requirement: Recording contains video and capture audio
A completed recording SHALL be an MP4 containing H.264 video and AAC audio from the capture card when a capture audio source is available. The app MUST NOT substitute the device built-in microphone when capture-card audio is available.

#### Scenario: File has picture and sound
- **WHEN** the user stops a recording that included a capture audio source
- **THEN** the saved MP4 MUST contain the capture video track and the capture-card audio track

#### Scenario: Video-only when no capture audio
- **WHEN** the user records while capture audio is unavailable
- **THEN** the app SHALL still save video and MUST indicate that the file has no capture audio

### Requirement: Persist recordings to the system library
On Android phones, tablets, and TV, the default destination SHALL be the system album at `DCIM/UsbCapture`. The operator SHALL be able to choose album, movies (`Movies/UsbCapture`), downloads (`Download/UsbCapture`), or a user-picked folder. Settings labels for those last two choices SHALL be 「下载」 and 「自定义」. If a custom or downloads write fails, the app MAY fall back to the album rather than discard a salvageable file. The app SHALL tell the operator which destination was used after a save.

#### Scenario: Android default album
- **WHEN** recording completes on Android with the default save location
- **THEN** the MP4 SHALL be written under `DCIM/UsbCapture`

#### Scenario: Android movies or downloads
- **WHEN** the operator selected 影片 or 下载 and recording completes
- **THEN** the MP4 SHALL be written under `Movies/UsbCapture` or `Download/UsbCapture` respectively

#### Scenario: Android custom folder
- **WHEN** the operator picked a custom folder and recording completes
- **THEN** the MP4 SHALL be written into that folder

#### Scenario: Save confirmation
- **WHEN** recording completes
- **THEN** the app SHALL tell the user that the video was saved and SHALL name the selected destination (相册, 影片, 下载, or 自定义)

### Requirement: Disconnect during recording
If the capture device is unplugged or the session fails while recording, the app SHALL stop recording and MUST publish a playable MP4 to the platform library when the interrupted capture produced encoded media. A file that is only a container header, or a take shorter than about 1.5 seconds, MUST NOT be published. The app SHALL then show that recording ended because the device disconnected, and SHALL also tell the user whether the file was saved. Preview SHALL enter the disconnected state. The UI MUST NOT remain in an indefinite recording state.

#### Scenario: Unplug while recording saves the file
- **WHEN** the active capture card is unplugged during recording and a non-empty video file can be finalized
- **THEN** the app SHALL write the MP4 to the operator's Android save location, clear the recording indicator, show a disconnected state, and SHALL tell the user that the recording was saved

#### Scenario: Unplug while recording with nothing to save
- **WHEN** the active capture card is unplugged during recording and no playable encoded video can be finalized
- **THEN** the app SHALL clear the recording indicator, show a disconnected/error state, and MUST NOT claim that a recording was saved

### Requirement: Encoder or session failure during recording
If the encoder or capture session fails while recording (without a clean user stop), the app SHALL use the same salvage rule as disconnect: publish a playable MP4 when encoded media can be finalized, then leave recording state. The app SHALL show an error and SHALL tell the user whether the file was saved.

#### Scenario: Encoder error with salvageable video
- **WHEN** recording fails because of an encoder or session error and a non-empty video file can be finalized
- **THEN** the app SHALL publish the MP4 to the platform library, clear the recording indicator, and SHALL tell the user that the recording was saved

#### Scenario: Encoder error with nothing to save
- **WHEN** recording fails because of an encoder or session error and no non-empty video file can be finalized
- **THEN** the app SHALL clear the recording indicator, show a recording-failed error, and MUST NOT claim that a recording was saved

### Requirement: Recording quality preset
The user SHALL be able to choose a video encode quality preset from a settings dropdown before starting a recording. The app SHALL provide `tiny`, `small`, `standard`, and `high` presets (shown as 更小, 省空间, 标准, 高码率) that change video bitrate while keeping H.264+AAC MP4. The selected preset SHALL persist and SHALL apply to the next recording. Default SHALL be `standard`. Changing preset while recording is in progress MUST be rejected without stopping the recording.

#### Scenario: Start with a lower bitrate
- **WHEN** the operator selects 省空间, then starts recording
- **THEN** the recording SHALL use the small video bitrate preset

#### Scenario: High quality still available
- **WHEN** the operator selects 高码率, then starts recording
- **THEN** the recording SHALL use the high video bitrate preset

#### Scenario: Reject preset change while recording
- **WHEN** recording is in progress and the user attempts to change quality preset
- **THEN** the app MUST keep the current recording and MUST NOT change encode settings mid-file

### Requirement: Readable recording file name
Completed recordings SHALL use a timestamped, human-readable file name that identifies the capture (for example a `USB_` prefix and local date-time). The name MUST remain unique for recordings started in different seconds.

#### Scenario: Android file name
- **WHEN** a recording completes on Android
- **THEN** the saved item SHALL use a timestamped capture file name rather than an opaque system-only title

### Requirement: Recording size in session UI
While recording, the app SHALL show elapsed time and SHALL show an approximate output size when the encoder reports bytes written or when size can be estimated from the active bitrate. The value MAY be approximate.

#### Scenario: Size updates while recording
- **WHEN** recording is in progress
- **THEN** the UI SHALL show elapsed time together with an approximate file size

### Requirement: Continue recording when the app is not in the foreground
On Android, while recording is in progress, the app SHALL keep capturing after the user locks the screen or switches to another app. The app SHALL show a persistent notification that recording is active. Stopping recording, unplugging the capture device, or a failed salvage SHALL end the foreground capture.

#### Scenario: Lock screen during Android recording
- **WHEN** the user starts recording on Android and then locks the screen
- **THEN** recording SHALL continue and the notification SHALL remain until the user stops recording or the session ends

#### Scenario: Switch app during Android recording
- **WHEN** the user starts recording on Android and then switches to another app
- **THEN** recording SHALL continue until stop, disconnect, or failure

#### Scenario: Notification returns to the app
- **WHEN** recording is in progress and the user activates the recording notification
- **THEN** the app SHALL return to the capture UI without starting a second recording

#### Scenario: Capture UI restored while Android recording continues
- **WHEN** Android is still recording in the foreground service and the capture page is recreated
- **THEN** the UI SHALL show recording in progress with elapsed time and MUST NOT start a second recording

### Requirement: Optional recording segments
The operator SHALL be able to disable segmentation or choose a segment length of 1, 5, 10, 15, or 30 minutes from a settings dropdown. A value of zero minutes SHALL record the session as one file named `USB_<timestamp>.mp4` without a numeric suffix. Changing the interval while recording MUST be rejected without stopping the recording. The recording indicator SHALL omit the segment index when segmentation is disabled. Default SHALL be 10 minutes. A brief gap between segments is allowed. The app MUST NOT concatenate segments into one file during recording. After segments are published, the operator MAY merge a completed session from the library on Android.

#### Scenario: Disabled segmentation writes one file
- **WHEN** segmentation is off and the user records then stops
- **THEN** the library SHALL contain one timestamped file without a `_NN` suffix

#### Scenario: Chosen interval rolls files
- **WHEN** the operator selects a 1, 5, 10, 15, or 30 minute interval and records longer than that interval
- **THEN** the app SHALL publish a completed segment and continue into the next file without closing the capture device

#### Scenario: Segment publish does not stop the session
- **WHEN** a segment interval elapses during recording
- **THEN** the app SHALL keep the capture device open and SHALL continue recording into the next segment

### Requirement: Auto-start recording after connect
When auto-record is enabled, the app SHALL start recording after a successful connect on launch or after a newly attached device is opened. If the operator manually stops recording, the app MUST NOT auto-start again while that device remains connected. Auto-start MAY resume after process restart or after disconnect followed by a new connect.

#### Scenario: Launch with a card already plugged in
- **WHEN** auto-record is enabled and the app opens the only attached capture device
- **THEN** recording SHALL start without an extra record tap

#### Scenario: Manual stop blocks auto-start until reconnect
- **WHEN** the operator stops recording while auto-record remains enabled
- **THEN** the app MUST NOT start a new recording until the next process start or a later connect after disconnect

### Requirement: Prompt once to ignore battery optimizations
On Android, if battery optimizations still apply to the app, the first time the user starts a recording the app SHALL explain why unrestricted background is needed and SHALL offer the system battery-optimization settings. The prompt MUST NOT appear on every subsequent start after the user has seen it. Recording MUST still start if the user declines.

#### Scenario: First recording offers battery settings
- **WHEN** the user starts recording on Android and optimizations are not ignored
- **THEN** the app SHALL show a one-time explanation and a way to open battery settings

#### Scenario: Later recordings do not nag
- **WHEN** the user has already been shown the battery-optimization prompt
- **THEN** starting recording MUST NOT show that prompt again

