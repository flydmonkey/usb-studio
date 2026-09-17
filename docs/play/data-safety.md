# Data safety (Play Console)

Fill the Data safety form to match this file and `privacy.md`. Do not declare collection the app does not perform.

## Privacy policy URL

https://flydmonkey.github.io/usb-studio/privacy.html  
(same as `privacyPolicyUrl` in `lib/play_listing.dart`)

## Does this app collect or share user data?

**Collected by the developer:** No (no accounts, ads, analytics, or developer-operated upload).

Declare **on-device processing** / **user-generated content stored on device** as below. User-initiated RTMP and LAN HTTP are not “shared with the developer”.

## Data types

| Type | Collected by developer? | Shared by developer? | Notes for the form |
| --- | --- | --- | --- |
| Photos and videos | No (user-generated, stays on device unless the user shares) | No | App creates snapshots/MP4 in shared storage the user chose |
| Audio files | Same as videos | No | Capture-card audio inside the MP4 |
| Camera | Accessed, not sent to developer | No | Required on Android 9+ to open UVC; not the selfie camera |
| Microphone | Accessed, not sent to developer | No | Capture-card / UAC audio |
| Approximate or precise location | No | No | |
| Personal info / account | No | No | No sign-in |
| App activity / crash logs | No | No | No analytics SDK |
| Device or other IDs | No | No | |

If the form asks whether data is processed ephemerally for preview: yes, live frames are shown locally and encoded locally. They are only written to storage when the user snapshots or records, or sent to a URL the user typed (RTMP) / LAN clients the user enabled.

## Security practices

- Data encrypted in transit: **RTMPS** can be encrypted if the operator uses `rtmps://`. Plain `rtmp://` and LAN HTTP are **not** encrypted. Do not claim “all data encrypted in transit”.
- Users can request deletion: **not applicable** (no developer-held account). They delete files on device.
- Independent security review: No.

## Advertising / children / sensitive permissions

- Ads: **No**
- In-app purchases: **No**
- Target audience: typically 18+ or 13+ as a general productivity/media tool — complete IARC; do **not** enroll in Designed for Families unless you meet that program.
- Camera / microphone: core functionality for USB capture. Explain UVC in the permission declaration notes.
