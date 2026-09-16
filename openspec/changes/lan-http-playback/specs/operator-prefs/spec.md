## MODIFIED Requirements

### Requirement: Persist operator capture preferences
The app SHALL persist segment interval, auto-record, preview enabled, preview mute, monitor volume, monitor delay, recording quality preset, Android save location, RTMP server URL, RTMP stream key, and LAN HTTP playback enabled (preference key `operator.httpLanEnabled`) across process restarts. Defaults SHALL be 10-minute segments, auto-record off, preview on, preview sound on, volume 100%, delay 0ms, standard quality, Android album (`DCIM/UsbCapture`), empty RTMP fields, and LAN HTTP playback off. The stream key MUST NOT be written to application logs.

#### Scenario: Settings survive relaunch
- **WHEN** the user changes these preferences and later relaunches the app
- **THEN** the same values SHALL be restored and applied after the capture device is opened

#### Scenario: Stream fields survive relaunch
- **WHEN** the operator saves an RTMP server URL and stream key and later relaunches the app
- **THEN** both fields SHALL be restored in settings

#### Scenario: LAN playback toggle survives relaunch
- **WHEN** the operator enables 局域网播放 and later relaunches the app
- **THEN** the `operator.httpLanEnabled` toggle SHALL remain on and the app SHALL attempt to restore the HTTP server according to platform support and network availability
