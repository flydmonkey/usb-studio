## ADDED Requirements

### Requirement: Persist operator capture preferences
The app SHALL persist segment interval, auto-record, preview mute, monitor volume, and monitor delay across process restarts. Defaults SHALL be 10-minute segments, auto-record off, preview sound on, volume 100%, delay 0ms.

#### Scenario: Settings survive relaunch
- **WHEN** the user changes these preferences and later relaunches the app
- **THEN** the same values SHALL be restored and applied after the capture device is opened
