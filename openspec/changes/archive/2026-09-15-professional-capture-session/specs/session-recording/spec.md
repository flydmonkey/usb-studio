## ADDED Requirements

### Requirement: Recording does not require visible preview
The user SHALL be able to start and stop recording while the capture device is open even if live preview is turned off. The app MUST reject recording only when no capture device is connected.

#### Scenario: Start recording with preview off
- **WHEN** a capture device is connected, preview is off, and the user starts recording
- **THEN** the app SHALL begin capturing the current video and capture-card audio to a file

### Requirement: Recording quality preset
The user SHALL be able to choose a video encode quality preset before starting a recording. The app SHALL provide at least `standard` and `high` presets that change video bitrate while keeping H.264+AAC MP4. The selected preset SHALL apply to the next recording. Changing preset while recording is in progress MUST be rejected without stopping the recording.

#### Scenario: Start with high quality
- **WHEN** preview is running, the user selects the high preset, then starts recording
- **THEN** the recording SHALL use the high video bitrate preset

#### Scenario: Reject preset change while recording
- **WHEN** recording is in progress and the user attempts to change quality preset
- **THEN** the app MUST keep the current recording and MUST NOT change encode settings mid-file

### Requirement: Readable recording file name
Completed recordings SHALL use a timestamped, human-readable file name that identifies the capture (for example a `USB_` prefix and local date-time). The name MUST remain unique for recordings started in different seconds.

#### Scenario: Android Movies name
- **WHEN** a recording completes on Android
- **THEN** the MediaStore item SHALL use a timestamped capture file name rather than an opaque system-only title

#### Scenario: iPad Photos name
- **WHEN** a recording completes on iPad
- **THEN** the saved file SHALL use a timestamped capture file name when the platform allows setting it

### Requirement: Recording size in session UI
While recording, the app SHALL show elapsed time and SHALL show an approximate output size when the encoder reports bytes written or when size can be estimated from the active bitrate. The value MAY be approximate.

#### Scenario: Size updates while recording
- **WHEN** recording is in progress
- **THEN** the UI SHALL show elapsed time together with an approximate file size
