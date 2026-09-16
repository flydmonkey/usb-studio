# recording-library Specification

## Purpose
Let the operator browse, share, and delete recordings this app saved, without opening a third-party gallery.

## Requirements
### Requirement: List this app's capture recordings
The app SHALL provide a library screen that lists recordings this app saved (Android: `UsbCapture` items under DCIM, Movies, and Download, plus a user-picked folder when set; iPad: USB_-prefixed items the app can query). Each row SHALL show a readable name and SHALL be usable on television UI mode with D-pad focus. An empty library SHALL explain that recordings appear here after a capture is saved. The library MUST NOT present the entire device gallery as the primary list.

#### Scenario: Saved segments appear in the library
- **WHEN** the user has saved one or more capture recordings and opens the library
- **THEN** the app SHALL list those recordings without requiring a third-party gallery app

#### Scenario: Empty library
- **WHEN** the user opens the library and no capture recordings are available
- **THEN** the app SHALL show an empty state and MUST NOT crash

### Requirement: Share and delete from the library
The user SHALL be able to share a listed recording through the system share sheet and to delete a listed recording after confirmation. Deleting SHALL remove the MediaStore or Photos item the app listed. If share is unavailable (for example no targets on some TVs), the app SHALL show a readable failure and MUST leave the file in place.

#### Scenario: Share a recording
- **WHEN** the user chooses share on a listed recording and a share target exists
- **THEN** the system share sheet SHALL be presented with that file

#### Scenario: Delete a recording
- **WHEN** the user confirms delete on a listed recording
- **THEN** the item SHALL disappear from the library and from the platform library collection the app used

#### Scenario: Cancel delete
- **WHEN** the user declines the delete confirmation
- **THEN** the recording MUST remain
