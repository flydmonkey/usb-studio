# operator-hud Specification

## Purpose
Give the operator live confirmation of signal, audio level, recording size, ingest state, and session controls (immersive view, keep-awake, snapshot) without leaving the capture page.
## Requirements
### Requirement: Signal heads-up display
While preview is running, the app SHALL overlay a compact HUD showing the active capture width, height, frame rate, and pixel format (FourCC or platform equivalent). The HUD SHALL update when the format changes. On television UI mode, HUD text SHALL remain readable at 10-foot distance.

#### Scenario: Preview shows format
- **WHEN** the user successfully connects a capture card and preview is running
- **THEN** the HUD SHALL show the current resolution, frame rate, and pixel format

#### Scenario: Format change updates HUD
- **WHEN** the user selects a different capture format and the new stream starts
- **THEN** the HUD SHALL show the new resolution, frame rate, and pixel format

### Requirement: No-signal indication
When the capture device is open but no new video frames arrive for a short timeout, the app SHALL show a distinct「无信号」state on the preview. The app MUST NOT present a frozen last frame or black screen as if live video were still updating.

#### Scenario: HDMI unplugged from capture card
- **WHEN** the USB capture card remains attached and the HDMI source is removed or not locked
- **THEN** the app SHALL show a no-signal indication and MUST NOT imply that live frames are still arriving

#### Scenario: Signal returns
- **WHEN** video frames resume after a no-signal state
- **THEN** the app SHALL clear the no-signal indication and resume live preview and HUD values

### Requirement: Audio peak meter
While preview is running and a capture audio source is available, the app SHALL display a peak level meter for capture-card audio. Muting preview monitoring MUST NOT freeze the meter if capture audio is still being measured. If the platform cannot measure peak, the app SHALL hide the meter rather than show a fake level.

#### Scenario: Meter moves with capture audio
- **WHEN** preview is running with capture-card audio present
- **THEN** the meter SHALL reflect capture audio peak over time

#### Scenario: No audio source
- **WHEN** capture audio is unavailable
- **THEN** the app MUST NOT show an active peak meter

### Requirement: Keep screen awake during session
While the capture session is open or recording is active, the app SHALL keep the display awake. When the capture device disconnects and recording is not active, the app SHALL allow the system idle timeout again.

#### Scenario: Preview prevents sleep
- **WHEN** live preview is running
- **THEN** the display MUST remain on without user touches

#### Scenario: Recording without preview prevents sleep
- **WHEN** recording is in progress and preview is off
- **THEN** the display MUST remain on

#### Scenario: Session end allows sleep
- **WHEN** the user disconnects the capture device and recording is not active
- **THEN** the app MUST release the keep-awake lock

### Requirement: Immersive preview
The app SHALL allow hiding chrome (bottom controls and secondary HUD) so the picture uses the viewing area. The recording indicator MUST remain visible while recording. On phones and tablets, tapping the preview SHALL toggle immersive mode. On television UI mode, a remote-focusable control or Back SHALL toggle or exit immersive mode.

#### Scenario: Hide chrome on phone
- **WHEN** the user taps the live preview on a non-television layout
- **THEN** the app SHALL hide the bottom controls and keep the picture visible

#### Scenario: Recording badge stays
- **WHEN** immersive mode is on and recording is in progress
- **THEN** the recording indicator MUST remain visible

#### Scenario: TV exits immersive with Back
- **WHEN** immersive mode is on in television UI mode and the user presses Back
- **THEN** the app SHALL restore chrome and MUST NOT exit the app as the first action

### Requirement: Snapshot of current video
While preview is running, the user SHALL be able to save a still image of the current capture video frame (not a screenshot of the Flutter chrome). The image SHALL be saved to the system media store images collection. Taking a snapshot MUST NOT stop preview. Taking a snapshot MUST NOT stop an in-progress recording.

#### Scenario: Save still while previewing
- **WHEN** preview is running and the user takes a snapshot
- **THEN** the app SHALL save a still of the capture video and leave preview running

#### Scenario: Snapshot during recording
- **WHEN** recording is in progress and the user takes a snapshot
- **THEN** the app SHALL save the still and MUST NOT stop the recording

#### Scenario: Cannot snapshot without preview
- **WHEN** preview is not running
- **THEN** the app MUST NOT capture a still

### Requirement: Live ingest badge
While RTMP ingest is active, the capture preview SHALL overlay a distinct LIVE indicator that can appear together with the recording badge. The Android foreground service notification SHALL remain while ingest or recording is active, and its text SHALL mention streaming when ingest is live.

#### Scenario: LIVE shows during ingest
- **WHEN** ingest is live and preview is visible
- **THEN** the operator SHALL see a LIVE badge even if recording is also running

#### Scenario: Notification covers stream-only
- **WHEN** ingest is live and recording is idle
- **THEN** the foreground notification SHALL remain and indicate streaming
