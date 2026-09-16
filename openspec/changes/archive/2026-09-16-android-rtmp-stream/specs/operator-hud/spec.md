## ADDED Requirements

### Requirement: Live ingest badge
While RTMP ingest is active, the capture preview SHALL overlay a distinct LIVE indicator that can appear together with the recording badge. The Android foreground service notification SHALL remain while ingest or recording is active, and its text SHALL mention streaming when ingest is live.

#### Scenario: LIVE shows during ingest
- **WHEN** ingest is live and preview is visible
- **THEN** the operator SHALL see a LIVE badge even if recording is also running

#### Scenario: Notification covers stream-only
- **WHEN** ingest is live and recording is idle
- **THEN** the foreground notification SHALL remain and indicate streaming
