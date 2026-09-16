## ADDED Requirements

### Requirement: Optional live preview
The user SHALL be able to turn live preview off and on while a capture device remains connected. Turning preview off MUST NOT close the capture session and MUST NOT by itself stop recording. After a successful connect, preview SHALL start on.

#### Scenario: Record with preview off
- **WHEN** the capture device is open, preview is off, and the user starts recording
- **THEN** the app SHALL record the capture session

#### Scenario: Hide preview during recording
- **WHEN** recording is in progress and the user turns preview off
- **THEN** the app SHALL hide the live video surface and MUST keep the recording running

### Requirement: Aspect-correct preview
Live video SHALL be displayed with the capture signal aspect ratio. The app MUST NOT stretch the picture to fill a mismatched view. Unused areas MAY be letterboxed or pillarboxed.

#### Scenario: 16:9 signal on a taller view
- **WHEN** preview is running with a 16:9 capture format
- **THEN** the picture SHALL keep a 16:9 aspect ratio and MUST NOT appear horizontally or vertically stretched

### Requirement: Monitor volume
The app SHALL provide a volume control for preview monitoring audio. Volume SHALL affect monitoring only. Volume MUST NOT by itself enable or disable whether capture audio is written into a recording. Preview mute SHALL continue to silence monitoring regardless of volume.

#### Scenario: Lower monitor volume
- **WHEN** preview is running with capture audio and the user lowers monitor volume
- **THEN** monitoring loudness SHALL decrease and video MUST continue

#### Scenario: Mute overrides volume
- **WHEN** preview is muted
- **THEN** monitoring MUST stay silent even if volume is above zero

### Requirement: Optional monitor delay
The app SHALL let the user add a small monitoring delay (including a zero-delay option) to better match video. The delay SHALL apply to preview monitoring only and MUST NOT change timestamps written into a recording.

#### Scenario: Apply delay to monitor
- **WHEN** the user selects a non-zero monitor delay
- **THEN** preview audio SHALL be delayed by that amount relative to the undelayed monitor path

#### Scenario: Recording stays undelayed
- **WHEN** monitor delay is non-zero and the user records
- **THEN** the saved audio track MUST NOT be delayed by the monitor compensation

## MODIFIED Requirements

### Requirement: Preferred capture mode
When the device advertises 1080p30 MJPEG and the user has not selected another format, the app SHALL use that mode for preview. If the user has selected a format, the app SHALL use the user-selected format instead.

#### Scenario: Preferred capture mode
- **WHEN** the device advertises 1080p30 MJPEG and the user has not selected another format
- **THEN** the app SHALL use that mode for preview

#### Scenario: User override
- **WHEN** the user has selected a listed format other than the automatic default
- **THEN** the app SHALL use the selected format for preview
