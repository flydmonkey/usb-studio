## ADDED Requirements

### Requirement: Start and stop LAN HTTP playback from settings
On Android, when `httpLanSupported` is true, the operator SHALL be able to turn 局域网播放 on and off from capture settings. The preference SHALL persist across restarts (default off). Turning on SHALL start a local HTTP server without requiring a capture session to be open. Turning off SHALL stop the server and invalidate the displayed URL. iPad MUST NOT show the control; invoking the plugin on unsupported platforms SHALL return `httpUnsupported`.

#### Scenario: Toggle on without capture card
- **WHEN** the operator enables 局域网播放 and the device has a LAN IPv4 address
- **THEN** the app SHALL start the HTTP server and show a copyable URL such as `http://192.168.1.8:8080/`

#### Scenario: Toggle off stops service
- **WHEN** the operator disables 局域网播放
- **THEN** the HTTP server SHALL stop and the URL SHALL no longer be reachable on the LAN

#### Scenario: iPad has no LAN playback
- **WHEN** the operator uses an iPad
- **THEN** the app MUST NOT show the 局域网播放 setting

### Requirement: Show URL only when LAN IPv4 is available
When 局域网播放 is enabled, the app SHALL display the copyable base URL only if a non-loopback IPv4 address is available (typically via Wi-Fi). If no suitable address exists, the app MUST NOT show a URL and SHALL tell the operator to connect to Wi-Fi first.

#### Scenario: No network shows guidance
- **WHEN** 局域网播放 is enabled but no LAN IPv4 can be determined
- **THEN** the settings UI SHALL show that Wi-Fi is required instead of an HTTP URL

#### Scenario: URL updates after port change
- **WHEN** the preferred port is occupied and the server binds to the next free port
- **THEN** the displayed URL SHALL reflect the actual port

### Requirement: HTTP routes for home page, live HLS, and VOD
The server SHALL bind `0.0.0.0`, prefer port `8080`, and increment the port if occupied. It SHALL serve:

| Path | Behavior |
| --- | --- |
| `GET /` | HTML page with live player (hls.js) and recording library list |
| `GET /api/recordings` | JSON array `[{id,name,bytes}]` for the home page library list (same ids as in-app library) |
| `GET /live.m3u8` and segment files | Live HLS (H.264 + AAC). When no capture card is open, return a readable failure state so the page shows waiting for capture card |
| `GET /vod/<id>` | Saved MP4 with `video/mp4` and HTTP Range support for progressive playback |

The recording list SHALL use the same source and ids as the in-app library (album / Movies / Downloads / custom folder).

#### Scenario: Browser opens home without card
- **WHEN** a browser on the same Wi-Fi opens the displayed URL and no capture card session is open
- **THEN** the page SHALL fetch `/api/recordings` and list saved recordings, and the live area SHALL indicate waiting for the capture card

#### Scenario: Recordings API returns library JSON
- **WHEN** a client requests `GET /api/recordings`
- **THEN** the server SHALL respond with `application/json` body `[{id,name,bytes}]` matching the in-app recording library

#### Scenario: VOD supports Range
- **WHEN** a client requests `GET /vod/<id>` with a valid `Range` header for an existing file
- **THEN** the server SHALL respond with `206 Partial Content` and the requested byte range

#### Scenario: Missing file returns 404
- **WHEN** a client requests `GET /vod/<id>` for a recording that no longer exists on disk
- **THEN** the server SHALL return `404` without affecting other list entries

### Requirement: Live HLS when capture card is connected
When a capture session is open and 局域网播放 is enabled, the server SHALL publish live HLS with H.264 video and AAC audio, with end-to-end latency on the order of a few seconds. If the USB capture card detaches or the session ends, live HLS SHALL stop updating while VOD routes remain available.

#### Scenario: Live appears after card connects
- **WHEN** 局域网播放 is already on, a browser has the home page open, and the operator opens a healthy capture session
- **THEN** the live player SHALL begin showing video and audio within a few seconds

#### Scenario: Card unplug stops live only
- **WHEN** the capture card detaches while 局域网播放 is on
- **THEN** live HLS SHALL stop but `/` and `/vod/<id>` SHALL continue to work for existing recordings

### Requirement: Coexist with local recording and RTMP ingest
Starting or stopping 局域网播放 MUST NOT stop local segmented recording or RTMP ingest, and starting recording or ingest MUST NOT stop the HTTP server. Live encoding for HLS SHALL share the same H.264/AAC encoder path as RTMP when ingest is active (tee encoded frames to HLS); when ingest is idle but a capture session is open, the app MAY run an HLS-only encoder session. Changing capture format or recording quality while live LAN encoding is active SHALL be rejected with a readable error, consistent with streaming in progress.

#### Scenario: HTTP with recording and RTMP
- **WHEN** 局域网播放, local segmented recording, and RTMP ingest are all active
- **THEN** each SHALL continue until the operator stops them independently

#### Scenario: Format locked during live LAN encode
- **WHEN** live LAN encoding is active and the operator tries to change format or quality
- **THEN** the app MUST keep the current format and explain that streaming is in progress

### Requirement: Foreground service while LAN playback is on
While 局域网播放 is enabled and the HTTP server is running, the app SHALL keep the existing capture foreground service (or equivalent) active so the LAN URL remains reachable after the screen locks. The notification text SHALL mention 局域网播放 when the server is running.

#### Scenario: Screen locked URL still works
- **WHEN** 局域网播放 is on and the operator locks the device
- **THEN** another device on the same Wi-Fi SHALL still be able to open the displayed URL

### Requirement: Security disclosure in settings
The settings UI SHALL include one sentence stating that anyone on the same Wi-Fi can open the address to watch (no encryption).

#### Scenario: Operator sees disclosure
- **WHEN** the operator opens 局域网播放 settings on Android
- **THEN** they SHALL see the unencrypted LAN access notice
