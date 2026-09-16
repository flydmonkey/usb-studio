# live-rtmp-stream Specification

## Purpose
Let the operator start and stop Android RTMP ingest from the capture bar, independently of local segmented recording.

## Requirements
### Requirement: Start and stop RTMP ingest from the capture bar
On Android, when a capture session is open, the operator SHALL be able to start and stop RTMP ingest from the capture bar. The app SHALL concatenate the saved server URL and stream key into one ingest URL (`rtmp://` or `rtmps://`) before connecting. Start SHALL wait until the server handshake succeeds or fail with a readable error without leaving a half-open encoder. Stop SHALL disconnect and release the stream encoder surfaces. Starting ingest MUST NOT stop local segmented recording, and starting recording MUST NOT stop ingest. iPad MUST NOT offer start; invoking the plugin SHALL return `streamUnsupported`.

#### Scenario: Start after filling address and key
- **WHEN** the operator has saved a valid RTMP server URL and stream key and a capture session is open
- **THEN** activating 推流 SHALL connect to the concatenated ingest URL and show that ingest is live

#### Scenario: Missing address or key
- **WHEN** the operator activates 推流 with an empty server URL or empty key
- **THEN** the app MUST NOT connect and SHALL tell the operator to fill both fields

#### Scenario: Stream and record together
- **WHEN** ingest is live and the operator starts segmented recording, or recording is already running and the operator starts ingest
- **THEN** both SHALL continue until the operator stops each independently

#### Scenario: iPad has no stream
- **WHEN** the operator uses an iPad
- **THEN** the app MUST NOT show the capture-bar stream control

### Requirement: Dual encode from UVC frames and USB PCM
Android ingest SHALL encode H.264 from a dedicated encoder surface attached to the UVC helper, and AAC from the same USB PCM already used for monitoring, independent of the file `VideoCapture` mux. If USB audio is unavailable, ingest MAY be video-only. Changing capture format or recording quality while ingest is live SHALL be rejected with a readable error.

#### Scenario: Local file keeps recording while ingest runs
- **WHEN** both ingest and recording are active
- **THEN** new local segments SHALL still be written with the existing recorder path

#### Scenario: Format locked while live
- **WHEN** ingest is live and the operator tries to change format or quality
- **THEN** the app MUST keep the current format and explain that streaming is in progress

### Requirement: Ingest stops on disconnect, no-signal, or server failure
If the capture card detaches, video frames stop (no-signal), or the RTMP connection fails after start, the app SHALL stop ingest, release stream encoders, and show a readable `streamFailed` (or disconnected) message. Local recording MAY continue unless the card is gone. The operator MUST be able to start ingest again after the session is healthy.

#### Scenario: HDMI unplugged while live
- **WHEN** ingest is live and the preview reports no-signal
- **THEN** ingest SHALL stop and the operator SHALL see that streaming stopped because there is no signal

#### Scenario: Card unplugged while live
- **WHEN** ingest is live and the USB capture card detaches
- **THEN** ingest SHALL stop along with the session

#### Scenario: Server rejects the stream
- **WHEN** the RTMP handshake fails or the connection drops
- **THEN** ingest SHALL stop and the app SHALL show that it could not reach the stream server
