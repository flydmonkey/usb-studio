## MODIFIED Requirements

### Requirement: Optional recording segments
The operator SHALL be able to disable segmentation or choose a segment length of 5, 10, 15, or 30 minutes from a settings dropdown. A value of zero minutes SHALL record the session as one file named `USB_<timestamp>.mp4` without a numeric suffix. Changing the interval while recording MUST be rejected without stopping the recording. The recording indicator SHALL omit the segment index when segmentation is disabled. Default SHALL be 10 minutes. A brief gap between segments is allowed. The app MUST NOT concatenate segments into one file during recording. After segments are published, the operator MAY merge a completed session from the library on Android.

#### Scenario: Disabled segmentation writes one file
- **WHEN** segmentation is off and the user records then stops
- **THEN** the library SHALL contain one timestamped file without a `_NN` suffix

#### Scenario: Chosen interval rolls files
- **WHEN** the operator selects a 5, 10, 15, or 30 minute interval and records longer than that interval
- **THEN** the app SHALL publish a completed segment and continue into the next file without closing the capture device

#### Scenario: Segment publish does not stop the session
- **WHEN** a segment interval elapses during recording
- **THEN** the app SHALL keep the capture device open and SHALL continue recording into the next segment
