## ADDED Requirements

### Requirement: Live video preview
While a capture device is connected, the app SHALL display a live video preview of the capture card output. The preview SHALL fill the main viewing area and MUST update continuously until the user disconnects or an error stops the session.

#### Scenario: Preview after connect
- **WHEN** the user successfully connects a supported capture card
- **THEN** the app SHALL show live video from that card in the main view

#### Scenario: Preferred capture mode
- **WHEN** the device advertises 1080p30 MJPEG
- **THEN** the app SHALL use that mode for preview

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
On Android TV and other television UI modes, the app SHALL use a 10-foot layout: large controls, overscan-safe margins, and full-screen preview. Start/stop recording, mute, and device status controls SHALL be reachable with a D-pad or remote. Phone and tablet layouts MAY use touch-first controls.

#### Scenario: TV remote navigation
- **WHEN** the app runs in television UI mode
- **THEN** the user MUST be able to focus and activate mute and record controls with the D-pad without requiring a touchscreen

#### Scenario: Phone layout unchanged by TV rules
- **WHEN** the app runs on a phone or tablet that is not in television UI mode
- **THEN** the app SHALL use the touch-first preview layout
