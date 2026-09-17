# lan-http-playback Specification

## Purpose
Let the operator serve silent live MJPEG preview and saved recordings over LAN HTTP so another device on the same Wi-Fi can watch in a browser.

## Requirements
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

### Requirement: HTTP routes for home page, live MJPEG, and VOD
The server SHALL bind `0.0.0.0`, prefer port `8080`, and increment the port if occupied. It SHALL serve:

| Path | Behavior |
| --- | --- |
| `GET /` | HTML page with one shared player, a live-preview switch (default off), and recording library list |
| `GET /api/recordings` | JSON array `[{id,name,bytes}]` for the home page library list (same ids as in-app library) |
| `GET /api/live` | JSON `{hasCard,mjpeg,paused,ready}` for live overlay state |
| `GET /live.mjpeg` | Live MJPEG (`multipart/x-mixed-replace`) of the latest UVC JPEG. When no JPEG is available the connection MAY wait. The page SHALL show waiting, need-MJPEG, or paused-while-streaming as appropriate |
| `GET /vod/<id>` | Saved MP4 with `video/mp4` and HTTP Range support for progressive playback |

The recording list SHALL use the same source and ids as the in-app library (album / Movies / Downloads / custom folder). Live SHALL NOT include audio.

#### Scenario: Browser opens home without card
- **WHEN** a browser on the same Wi-Fi opens the displayed URL and no capture card session is open
- **THEN** the page SHALL fetch `/api/recordings` and list saved recordings, live preview SHALL stay off, and the shared player SHALL wait until the operator turns live on or picks a recording

#### Scenario: Live preview starts only when switched on
- **WHEN** the operator turns on 实时预览
- **THEN** the shared player SHALL start silent live MJPEG and SHALL stop any recording currently playing in that player

#### Scenario: Recording uses the same player
- **WHEN** the operator picks a recording from the list
- **THEN** the shared player SHALL play that MP4, and live preview SHALL turn off if it was on

#### Scenario: Recordings API returns library JSON
- **WHEN** a client requests `GET /api/recordings`
- **THEN** the server SHALL respond with `application/json` body `[{id,name,bytes}]` matching the in-app recording library

#### Scenario: VOD supports Range
- **WHEN** a client requests `GET /vod/<id>` with a valid `Range` header for an existing file
- **THEN** the server SHALL respond with `206 Partial Content` and the requested byte range

#### Scenario: Missing file returns 404
- **WHEN** a client requests `GET /vod/<id>` for a recording that no longer exists on disk
- **THEN** the server SHALL return `404` without affecting other list entries

### Requirement: Live MJPEG when capture card is connected
When a capture session is open, the capture format is MJPEG, and 局域网播放 is enabled, the server SHALL publish silent live MJPEG by copying JPEG frames from the UVC callback (no H.264 transcode). If the USB capture card detaches or the session ends, live MJPEG SHALL stop updating while VOD routes remain available. If the current format is not MJPEG, the page SHALL tell the operator to switch to MJPEG instead of showing a broken live picture.

#### Scenario: Live appears after card connects
- **WHEN** 局域网播放 is already on, a browser has the home page open with 实时预览 switched on, and the operator opens a healthy MJPEG capture session
- **THEN** the shared player SHALL begin showing silent live video

#### Scenario: Non-MJPEG format is not live
- **WHEN** the capture session is open on a non-MJPEG format
- **THEN** the live area SHALL explain that MJPEG is required

#### Scenario: Card unplug stops live only
- **WHEN** the capture card detaches while 局域网播放 is on
- **THEN** live MJPEG SHALL stop but `/` and `/vod/<id>` SHALL continue to work for existing recordings

### Requirement: Coexist with local recording and RTMP ingest
Starting or stopping 局域网播放 MUST NOT stop local segmented recording or RTMP ingest, and starting recording or ingest MUST NOT stop the HTTP server. LAN-only live SHALL NOT start a MediaCodec session. When RTMP ingest is active, the UVC frame callback SHALL switch to NV21 for ingest and LAN MJPEG SHALL pause until ingest stops. Changing capture format while LAN MJPEG is publishing SHALL be rejected with a readable error, consistent with streaming in progress. Recording quality MAY still be changed while LAN MJPEG is publishing if recording and ingest are idle.

#### Scenario: HTTP with recording and RTMP
- **WHEN** 局域网播放, local segmented recording, and RTMP ingest are all active
- **THEN** each SHALL continue until the operator stops them independently, and LAN live SHALL pause for the duration of ingest

#### Scenario: Format locked during live LAN MJPEG
- **WHEN** live LAN MJPEG is publishing and the operator tries to change format
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

### Requirement: LAN home page follows app UI locale
The LAN HTTP home page (`GET /`) SHALL render chrome, live status, empty states, and errors in the same resolved UI locale as the Android app (`zh-Hans`, `zh-Hant`, `ja`, `ko`, or `en`). The page MUST NOT choose language from the browser `Accept-Language` header. Recording display names in the list SHALL remain the on-disk / MediaStore names. The product name `USB Studio` SHALL stay untranslated.

#### Scenario: English app serves English home page
- **WHEN** the resolved app locale is `en` and a browser on the same Wi-Fi opens the displayed URL
- **THEN** the home page headings and live waiting copy SHALL be English

#### Scenario: Browser language does not override
- **WHEN** the resolved app locale is `zh-Hans` and the browser sends `Accept-Language: en`
- **THEN** the home page SHALL still use Simplified Chinese
