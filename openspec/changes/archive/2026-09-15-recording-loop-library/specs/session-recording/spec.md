## ADDED Requirements

### Requirement: Continue recording when the app is not in the foreground
On Android, while recording is in progress, the app SHALL keep capturing after the user locks the screen or switches to another app. The app SHALL show a persistent notification that recording is active. Stopping recording, unplugging the capture device, or a failed salvage SHALL end the foreground capture. On iPad, recording MAY stop when the app is backgrounded; the app MUST NOT claim iPad background capture in this change.

#### Scenario: Lock screen during Android recording
- **WHEN** the user starts recording on Android and then locks the screen
- **THEN** recording SHALL continue and the notification SHALL remain until the user stops recording or the session ends

#### Scenario: Switch app during Android recording
- **WHEN** the user starts recording on Android and then switches to another app
- **THEN** recording SHALL continue until stop, disconnect, or failure

#### Scenario: Notification returns to the app
- **WHEN** recording is in progress and the user activates the recording notification
- **THEN** the app SHALL return to the capture UI without starting a second recording

### Requirement: Segment recordings on a timer
While a recording session is active, the app SHALL finalize the current file about every 10 minutes, publish it to the platform library immediately, and start the next segment without closing the capture device. Segment files SHALL share a session timestamp and an incrementing two-digit suffix. The UI SHALL show the session elapsed time and the current segment index. A brief gap between segments is allowed. The app MUST NOT concatenate segments into one file in this change.

#### Scenario: Hour-long session produces multiple files
- **WHEN** the user records for more than ten minutes and then stops
- **THEN** the library SHALL contain multiple timestamped segment files and MUST include the last partial segment

#### Scenario: Segment publish does not stop the session
- **WHEN** a segment interval elapses during recording
- **THEN** the app SHALL keep the capture device open and SHALL continue recording into the next segment

### Requirement: Prompt once to ignore battery optimizations
On Android, if battery optimizations still apply to the app, the first time the user starts a recording the app SHALL explain why unrestricted background is needed and SHALL offer the system battery-optimization settings. The prompt MUST NOT appear on every subsequent start after the user has seen it. Recording MUST still start if the user declines.

#### Scenario: First recording offers battery settings
- **WHEN** the user starts recording on Android and optimizations are not ignored
- **THEN** the app SHALL show a one-time explanation and a way to open battery settings

#### Scenario: Later recordings do not nag
- **WHEN** the user has already been shown the battery-optimization prompt
- **THEN** starting recording MUST NOT show that prompt again
