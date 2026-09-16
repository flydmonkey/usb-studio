# live-av-preview Specification

## Purpose
Show optional live preview and capture-card monitoring audio, with aspect-correct picture and operator listening controls.

## Requirements
### Requirement: Live video preview
While a capture device is connected, the app SHALL offer a live video preview of the capture card output. Preview SHALL be optional: the user MUST be able to turn it off without closing the capture session. When preview is on, it SHALL fill the main viewing area and MUST update continuously until the user turns it off, disconnects, or an error stops the session. After a successful connect, preview SHALL follow the saved preview-enabled preference (default on). The preview on/off control SHALL live in settings and SHALL persist.

#### Scenario: Preview after connect
- **WHEN** the user successfully connects a supported capture card and preview is enabled
- **THEN** the app SHALL show live video from that card in the main view

#### Scenario: Preview stays off after connect
- **WHEN** the operator has turned preview off and later reconnects
- **THEN** the app MUST keep preview off until the operator turns it on again
- **THEN** recording SHALL still be allowed

#### Scenario: Turn preview off
- **WHEN** a capture device is connected and the user turns preview off
- **THEN** the app SHALL hide the live video surface, keep the capture session open, and MUST still allow recording

#### Scenario: Turn preview on
- **WHEN** a capture device is connected, preview is off, and the user turns preview on
- **THEN** the app SHALL resume live video in the main view without requiring a reconnect

#### Scenario: Preferred capture mode
- **WHEN** the device advertises 1080p30 MJPEG
- **THEN** the app SHALL use that mode for preview

#### Scenario: User override
- **WHEN** the user has selected a listed format other than the automatic default
- **THEN** the app SHALL use the selected format for preview

#### Scenario: Fallback capture mode
- **WHEN** 1080p30 MJPEG is unavailable
- **THEN** the app SHALL select the highest stable mode the device supports

#### Scenario: Android TV bandwidth fallback
- **WHEN** USB bandwidth or power on Android TV cannot sustain 1080p
- **THEN** the app SHALL fall back to 720p if that mode works, or SHALL show a specific error
- **THEN** the app MUST NOT leave a silent black screen

### Requirement: Monitor capture-card audio
While preview is running, the app SHALL play audio originating from the capture card (UAC / device-associated microphone), not from the phone, tablet, or TV built-in microphone. Preview audio SHALL stay in sync with the visible video within normal capture latency.

#### Scenario: HDMI audio present
- **WHEN** preview is running and the capture card provides an audio source
- **THEN** the app SHALL play that audio through the device speakers or current audio route

#### Scenario: No capture audio
- **WHEN** preview is running but the capture card exposes no usable audio source
- **THEN** the app SHALL continue video preview and MUST indicate that capture audio is unavailable
- **THEN** the app MUST NOT silently substitute the built-in microphone for preview monitoring

### Requirement: Preview mute
The app SHALL provide a control to mute and unmute preview monitoring audio without stopping the video preview. Muting preview MUST NOT by itself stop recording of capture audio.

#### Scenario: Mute preview
- **WHEN** the user mutes preview while video is playing
- **THEN** monitoring audio MUST stop and video MUST continue

#### Scenario: Unmute preview
- **WHEN** the user unmutes preview
- **THEN** capture-card monitoring audio MUST resume if a capture audio source is available

### Requirement: Television 10-foot preview shell
On Android TV and other television UI modes, the app SHALL use a 10-foot layout: large controls, overscan-safe margins, and full-screen preview. Snapshot, start/stop recording, mute, and device status controls SHALL be reachable with a D-pad or remote. Phone and tablet layouts MAY use touch-first controls.

#### Scenario: TV remote navigation
- **WHEN** the app runs in television UI mode
- **THEN** the user MUST be able to focus and activate snapshot, mute, and record controls with the D-pad without requiring a touchscreen

#### Scenario: Phone layout unchanged by TV rules
- **WHEN** the app runs on a phone or tablet that is not in television UI mode
- **THEN** the app SHALL use the touch-first preview layout

### Requirement: Persist preview monitor sound
Preview mute, monitor volume, and monitor delay SHALL be saved as operator preferences and applied when a capture session opens. The on-screen mute control SHALL stay in sync with the saved mute preference. Changing mute, volume, or delay SHALL update the live monitor and the saved values. These preferences MUST NOT change whether capture-card audio is written into the recording.

#### Scenario: Mute preference restored
- **WHEN** the operator muted preview, then relaunches and reconnects
- **THEN** preview monitor SHALL remain muted until the operator unmutes

#### Scenario: Capture-bar mute and settings stay aligned
- **WHEN** the operator toggles preview mute from the capture bar or from settings
- **THEN** both surfaces SHALL show the same mute state and the value SHALL be persisted

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

