## ADDED Requirements

### Requirement: Optional recording segments
The operator SHALL be able to disable segmentation or choose a segment length of 5, 10, 15, or 30 minutes. A value of zero minutes SHALL record the session as one file named `USB_<timestamp>.mp4` without a numeric suffix. Changing the interval while recording MUST be rejected without stopping the recording. The recording indicator SHALL omit the segment index when segmentation is disabled.

#### Scenario: Disabled segmentation writes one file
- **WHEN** segmentation is off and the user records then stops
- **THEN** the library SHALL contain one timestamped file without a `_NN` suffix

#### Scenario: Chosen interval rolls files
- **WHEN** the operator selects a 5, 10, 15, or 30 minute interval and records longer than that interval
- **THEN** the app SHALL publish a completed segment and continue into the next file without closing the capture device

### Requirement: Auto-start recording after connect
When auto-record is enabled, the app SHALL start recording after a successful connect on launch or after a newly attached device is opened. If the operator manually stops recording, the app MUST NOT auto-start again while that device remains connected. Auto-start MAY resume after process restart or after disconnect followed by a new connect.

#### Scenario: Launch with a card already plugged in
- **WHEN** auto-record is enabled and the app opens the only attached capture device
- **THEN** recording SHALL start without an extra record tap

#### Scenario: Manual stop blocks auto-start until reconnect
- **WHEN** the operator stops recording while auto-record remains enabled
- **THEN** the app MUST NOT start a new recording until the next process start or a later connect after disconnect
