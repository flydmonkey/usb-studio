# play-disclosure Specification

## Purpose
Expose a public privacy policy and terms of use from settings, and explain camera and microphone use before the system permission prompt, so USB Studio can be reviewed for Google Play.

## Requirements
### Requirement: Public privacy policy matches the in-app link
The app SHALL expose one publicly reachable privacy-policy URL (not a PDF) from capture settings. That URL SHALL be the same address submitted in Google Play Console. The policy text SHALL name the product `USB Studio`, explain camera and microphone access for USB capture-card video and audio (not the built-in selfie camera), local storage of user-generated photos and videos, operator-initiated RTMP ingest to a URL the operator provides, unencrypted LAN HTTP playback on the local network, and that the developer does not operate an account system or analytics collection. Opening the link MUST work without a capture card attached.

#### Scenario: Settings opens the privacy policy
- **WHEN** the operator opens capture settings and activates Privacy policy
- **THEN** the device SHALL open the public privacy-policy URL in the system browser

#### Scenario: Privacy policy is reachable without a capture card
- **WHEN** no USB capture device is attached
- **THEN** the operator MUST still be able to open settings and the privacy-policy link

#### Scenario: Television can open the privacy policy
- **WHEN** the app is in television UI mode
- **THEN** the operator MUST be able to reach and activate the privacy-policy control with the D-pad

### Requirement: Settings expose privacy policy and terms of use
Capture settings SHALL include separate controls at the bottom of the sheet for the privacy policy and terms of use. The privacy-policy control SHALL open the public privacy-policy URL. The terms-of-use control SHALL show the Flutter open-source license page. Settings MUST NOT include an About entry or About dialog.

#### Scenario: Terms of use opens licenses
- **WHEN** the operator activates Terms of use
- **THEN** the app SHALL show the license page listing Flutter and third-party packages

### Requirement: First-run disclosure before camera and microphone
Before the app requests `CAMERA` or `RECORD_AUDIO` on a session where those permissions are not already granted, the app SHALL show a prominent in-app disclosure that camera and microphone access are for USB capture-card video and audio, not the device's built-in selfie camera. The operator MUST confirm before the system permission prompt appears. Dismissing or declining the disclosure SHALL NOT start preview or recording and SHALL leave an actionable `permissionDenied` state. If camera and microphone are already granted, the app MUST NOT show the disclosure again for that purpose.

#### Scenario: Disclosure then system prompt
- **WHEN** camera or microphone permission is not granted and the app needs them to capture
- **THEN** the app SHALL show the disclosure first, and MUST NOT show the system permission dialog until the operator confirms

#### Scenario: Operator declines disclosure
- **WHEN** the operator dismisses or declines the disclosure
- **THEN** the app MUST show an actionable permission error and MUST NOT start preview or recording

#### Scenario: Already granted skips disclosure
- **WHEN** camera and microphone permission are already granted
- **THEN** the app MUST proceed to device discovery without showing the disclosure

#### Scenario: TV remote can complete disclosure
- **WHEN** the app is in television UI mode and the disclosure is visible
- **THEN** the operator MUST be able to confirm or decline it with the D-pad
