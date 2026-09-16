## ADDED Requirements

### Requirement: Optional start and stop recording
The user SHALL be able to start recording the current capture session and stop it later. Recording MUST be optional: preview SHALL work without recording. On television UI mode, start and stop SHALL be activatable with a remote/D-pad. While recording, the app SHALL show a recording indicator and elapsed time.

#### Scenario: Start recording from preview
- **WHEN** preview is running and the user starts recording
- **THEN** the app SHALL begin capturing the current video and capture-card audio to a file and show recording state with elapsed time

#### Scenario: Stop recording
- **WHEN** recording is in progress and the user stops recording
- **THEN** the app SHALL finalize the file, leave preview running, and clear the recording indicator

#### Scenario: Cannot start without preview
- **WHEN** no capture device is connected or preview is not running
- **THEN** the app MUST NOT start a recording session

#### Scenario: TV remote starts and stops
- **WHEN** the app is in television UI mode and preview is running
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
On iPad, the app SHALL save completed recordings to the Photos library. On Android phones, tablets, and TV, the app SHALL save completed recordings to the system media store in the Movies collection. On TV, the app SHALL show a readable confirmation that the file was saved to the Movies folder, without depending on a phone-style gallery app.

#### Scenario: iPad save
- **WHEN** recording completes on iPad
- **THEN** the MP4 SHALL appear in Photos

#### Scenario: Android phone or TV save
- **WHEN** recording completes on Android
- **THEN** the MP4 SHALL be written to the MediaStore Movies collection

#### Scenario: TV save confirmation
- **WHEN** recording completes in television UI mode
- **THEN** the app SHALL tell the user that the video was saved to the Movies folder

### Requirement: Disconnect during recording
If the capture device is unplugged or the session fails while recording, the app SHALL stop recording, preserve any finalized media that can be salvaged, and show that recording ended because the device disconnected. Preview SHALL enter the disconnected state.

#### Scenario: Unplug while recording
- **WHEN** the active capture card is unplugged during recording
- **THEN** the app SHALL stop recording, show a disconnected/error state, and MUST NOT leave the UI in an indefinite “recording” state
