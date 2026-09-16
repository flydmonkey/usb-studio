## ADDED Requirements

### Requirement: Persist preview monitor sound
Preview mute, monitor volume, and monitor delay SHALL be saved as operator preferences and applied when a capture session opens. The on-screen mute control SHALL stay in sync with the saved mute preference. Changing mute, volume, or delay SHALL update the live monitor and the saved values. These preferences MUST NOT change whether capture-card audio is written into the recording.

#### Scenario: Mute preference restored
- **WHEN** the operator muted preview, then relaunches and reconnects
- **THEN** preview monitor SHALL remain muted until the operator unmutes

#### Scenario: Bottom mute and settings stay aligned
- **WHEN** the operator toggles preview mute from the capture page or from settings
- **THEN** both surfaces SHALL show the same mute state and the value SHALL be persisted
