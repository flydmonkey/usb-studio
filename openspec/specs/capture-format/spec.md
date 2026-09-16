# capture-format Specification

## Purpose
Let the operator see and choose the capture card’s advertised video modes, with a stable automatic default until they pick one.
## Requirements
### Requirement: Enumerate supported video formats
After a capture device is open, the app SHALL list video formats the device advertises, including width, height, frame rate, and pixel format. The list MAY be grouped or filtered to unique width/height/fps/fourcc combinations. Formats that the current platform cannot open MUST NOT be offered as selectable.

#### Scenario: Open device lists formats
- **WHEN** the user has connected a supported capture card
- **THEN** the app SHALL present the advertised video formats for selection

#### Scenario: Empty format list
- **WHEN** the platform cannot enumerate formats
- **THEN** the app SHALL keep the automatic default mode and MUST NOT show a broken empty picker as the only path to preview

### Requirement: User selects capture format
The user SHALL be able to select a listed format. After a successful switch, preview and subsequent recordings SHALL use that format until the user selects another, the device disconnects, or the session closes. While recording, the app MUST reject format changes and MUST leave the recording running.

#### Scenario: Switch format during preview
- **WHEN** preview is running and recording is not, and the user selects another advertised format
- **THEN** the app SHALL restart the video stream in that format and continue preview

#### Scenario: Reject switch while recording
- **WHEN** recording is in progress and the user attempts to change format
- **THEN** the app MUST NOT change format and MUST keep recording

#### Scenario: Switch failure restores previous format
- **WHEN** applying a selected format fails
- **THEN** the app SHALL restore the previous working format when possible and SHALL show a non-blank error

### Requirement: Default format without user choice
Until the user picks a format, the app SHALL keep the existing automatic policy: prefer 1080p30 MJPEG when advertised; otherwise the highest stable mode; on Android TV, fall back to 720p when 1080p cannot be sustained.

#### Scenario: First connect uses automatic policy
- **WHEN** a capture card is opened and the user has not selected a format in this session
- **THEN** the app SHALL apply the automatic 1080p30 MJPEG or fallback policy
