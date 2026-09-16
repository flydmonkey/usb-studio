# recording-library Specification

## Purpose
Let the operator browse, play, rename, merge, share, and delete recordings this app saved, without opening a third-party gallery.

## Requirements
### Requirement: List this app's capture recordings
The app SHALL provide a library screen that lists recordings this app saved (Android: `UsbCapture` items under DCIM, Movies, and Download, plus a user-picked folder when set). Each row SHALL show a readable name and SHALL be usable on television UI mode with D-pad focus. An empty library SHALL explain that recordings appear here after a capture is saved. The library MUST NOT present the entire device gallery as the primary list.

#### Scenario: Saved segments appear in the library
- **WHEN** the user has saved one or more capture recordings and opens the library
- **THEN** the app SHALL list those recordings without requiring a third-party gallery app

#### Scenario: Empty library
- **WHEN** the user opens the library and no capture recordings are available
- **THEN** the app SHALL show an empty state and MUST NOT crash

### Requirement: Share and delete from the library
The user SHALL be able to share a listed recording through the system share sheet and to delete a listed recording after confirmation. Deleting SHALL remove the MediaStore item the app listed. If share is unavailable (for example no targets on some TVs), the app SHALL show a readable failure and MUST leave the file in place.

#### Scenario: Share a recording
- **WHEN** the user chooses share on a listed recording and a share target exists
- **THEN** the system share sheet SHALL be presented with that file

#### Scenario: Delete a recording
- **WHEN** the user confirms delete on a listed recording
- **THEN** the item SHALL disappear from the library and from the platform library collection the app used

#### Scenario: Cancel delete
- **WHEN** the user declines the delete confirmation
- **THEN** the recording MUST remain

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
