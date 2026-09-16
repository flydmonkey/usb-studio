# operator-prefs Specification

## Purpose
Remember the operator's capture habits across launches so settings are not re-entered every session.

## Requirements
### Requirement: Persist operator capture preferences
The app SHALL persist segment interval, auto-record, preview enabled, preview mute, monitor volume, monitor delay, recording quality preset, and Android save location across process restarts. Defaults SHALL be 10-minute segments, auto-record off, preview on, preview sound on, volume 100%, delay 0ms, standard quality, and Android album (`DCIM/UsbCapture`).

#### Scenario: Settings survive relaunch
- **WHEN** the user changes these preferences and later relaunches the app
- **THEN** the same values SHALL be restored and applied after the capture device is opened
