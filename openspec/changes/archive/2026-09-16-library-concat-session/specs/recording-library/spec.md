## ADDED Requirements

### Requirement: Merge one session's segments on Android
On Android, the library SHALL treat recordings named `USB_<sessionStamp>_<NN>.mp4` with the same session stamp as one session. When a session has two or more segments, the operator SHALL be able to merge the whole session from any of those segment rows. Merging SHALL copy the existing encoded video and audio samples into a new MP4 without re-encoding. Original segment files MUST remain. The merged file SHALL be saved to the same Android destination as the first segment. The preferred name SHALL be `USB_<sessionStamp>.mp4`; if that name is already used, the app SHALL use `USB_<sessionStamp>_merged.mp4` or an incrementing `merged` suffix. The app MUST write to a temporary file and publish only after success. Failure MUST leave no partial library item and MUST NOT delete existing recordings. A session with fewer than two segments MUST NOT show merge. iPad MUST NOT offer merge. Television UI mode SHALL expose merge to the D-pad.

#### Scenario: Merge a two-segment session
- **WHEN** the library lists `USB_20260915_153000_01.mp4` and `USB_20260915_153000_02.mp4` and the operator chooses 合并本场 on either row
- **THEN** the library SHALL add a playable `USB_20260915_153000.mp4` (or `_merged` if that name exists) and MUST keep both original segments

#### Scenario: Single segment has no merge
- **WHEN** a session has only one `_NN` file
- **THEN** the app MUST NOT offer merge for that row

#### Scenario: Unsegmented file is not a merge source
- **WHEN** the library lists `USB_20260915_153000.mp4` with no `_NN` siblings
- **THEN** that row MUST NOT offer 合并本场

#### Scenario: Reject merge while that session is recording
- **WHEN** the matching session stamp is still being recorded
- **THEN** the app MUST NOT write a merged file and SHALL tell the operator why

#### Scenario: Failed merge keeps originals
- **WHEN** merge fails because a segment cannot be read, formats differ, or storage is full
- **THEN** the app MUST NOT publish a partial merged item and MUST leave every original segment in place

#### Scenario: iPad has no merge
- **WHEN** the operator opens the library on iPad
- **THEN** the app MUST NOT show 合并本场

#### Scenario: TV can merge with the remote
- **WHEN** the app is in television UI mode and a session has two or more segments
- **THEN** the operator MUST be able to activate 合并本场 with the D-pad
