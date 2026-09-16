## MODIFIED Requirements

### Requirement: Disconnect during recording
If the capture device is unplugged or the session fails while recording, the app SHALL stop recording and MUST publish a playable MP4 to the platform library when the interrupted capture produced a non-empty video file. The app SHALL then show that recording ended because the device disconnected, and SHALL also tell the user whether the file was saved. Preview SHALL enter the disconnected state. The UI MUST NOT remain in an indefinite recording state.

#### Scenario: Unplug while recording saves the file
- **WHEN** the active capture card is unplugged during recording and a non-empty video file can be finalized
- **THEN** the app SHALL write the MP4 to Photos (iPad) or MediaStore Movies (Android), clear the recording indicator, show a disconnected state, and SHALL tell the user that the recording was saved

#### Scenario: Unplug while recording with nothing to save
- **WHEN** the active capture card is unplugged during recording and no non-empty video file can be finalized
- **THEN** the app SHALL clear the recording indicator, show a disconnected/error state, and MUST NOT claim that a recording was saved

## ADDED Requirements

### Requirement: Encoder or session failure during recording
If the encoder or capture session fails while recording (without a clean user stop), the app SHALL use the same salvage rule as disconnect: publish a playable MP4 when a non-empty video file can be finalized, then leave recording state. The app SHALL show an error and SHALL tell the user whether the file was saved.

#### Scenario: Encoder error with salvageable video
- **WHEN** recording fails because of an encoder or session error and a non-empty video file can be finalized
- **THEN** the app SHALL publish the MP4 to the platform library, clear the recording indicator, and SHALL tell the user that the recording was saved

#### Scenario: Encoder error with nothing to save
- **WHEN** recording fails because of an encoder or session error and no non-empty video file can be finalized
- **THEN** the app SHALL clear the recording indicator, show a recording-failed error, and MUST NOT claim that a recording was saved
