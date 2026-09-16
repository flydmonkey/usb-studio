## ADDED Requirements

### Requirement: Play a listed recording in the system player
The operator SHALL be able to play a listed recording by activating the row (title area). The app SHALL hand the file to the platform's system video player (Android: `ACTION_VIEW` for `video/mp4`; iPad: system playback of that asset). The app MUST NOT decode the file in an in-app player. Share, delete, merge, and rename controls MUST remain independently activatable and MUST NOT start playback. If no player can open the file, the app SHALL show a readable failure and MUST leave the file in place. Television UI mode SHALL allow D-pad activation of the row to play.

#### Scenario: Tap a row opens the system player
- **WHEN** the operator activates a listed recording row
- **THEN** the system player SHALL open that recording

#### Scenario: Trailing actions do not play
- **WHEN** the operator activates share, delete, merge, or rename on a row
- **THEN** the app MUST NOT start playback for that action

#### Scenario: Play failure keeps the file
- **WHEN** no system player can open the recording
- **THEN** the app SHALL show a readable failure and MUST leave the recording in the library

#### Scenario: TV can play with the remote
- **WHEN** the app is in television UI mode and a recording is listed
- **THEN** the operator MUST be able to play it by activating the row with the D-pad

### Requirement: Rename a listed recording on Android
On Android, the operator SHALL be able to rename a listed recording. The new display name MAY be any non-empty string after trim; the app SHALL append `.mp4` if the operator omits that extension. Names containing path separators or the characters `\ / : * ? " < > |` MUST be rejected. If another listed recording already uses that name (case-insensitive), the app MUST NOT overwrite it. A rename that only changes letter case of the current name, or matches the current name, MAY be treated as success without rewriting. Success SHALL change the on-disk / MediaStore / SAF display name and refresh the library row. Failure MUST leave the original file and name. After a name no longer matches `USB_<sessionStamp>_<NN>.mp4`, merge MUST NOT appear for that row. iPad MUST NOT offer rename. Television UI mode SHALL expose rename to the D-pad.

#### Scenario: Rename to a Chinese title
- **WHEN** the operator renames `USB_20260915_153000.mp4` to `婚礼`
- **THEN** the library SHALL show `婚礼.mp4` and the platform item SHALL use that display name

#### Scenario: Invalid name is rejected
- **WHEN** the operator submits a blank name or a name containing `/`
- **THEN** the app MUST NOT change the file and SHALL explain that the name is invalid

#### Scenario: Duplicate name is rejected
- **WHEN** the library already lists `婚礼.mp4` and the operator tries to rename another item to `婚礼.mp4`
- **THEN** the app MUST NOT overwrite the existing file and SHALL tell the operator the name is taken

#### Scenario: Merge disappears after breaking the segment name
- **WHEN** the operator renames `USB_20260915_153000_01.mp4` to `上半场.mp4` and a sibling `_02` still exists
- **THEN** that renamed row MUST NOT offer 合并本场

#### Scenario: iPad has no rename
- **WHEN** the operator opens the library on iPad
- **THEN** the app MUST NOT show rename

#### Scenario: TV can rename with the remote
- **WHEN** the app is in television UI mode on Android
- **THEN** the operator MUST be able to activate rename with the D-pad
