# picture-controls Specification

## Purpose
Expose only the picture processing controls the capture device actually advertises, and apply them live without interrupting recording.
## Requirements
### Requirement: Adjust advertised picture controls
While a capture device is open, the app SHALL expose brightness, contrast, saturation, and hue controls that the device actually advertises. Controls the device does not advertise MUST be hidden. Changing a control SHALL apply to the live preview immediately. Recording, if active, SHALL continue and SHALL reflect the new picture.

#### Scenario: Adjust brightness during preview
- **WHEN** the device advertises brightness and the user changes it
- **THEN** the live preview SHALL update without reconnecting the USB device

#### Scenario: Hidden unsupported control
- **WHEN** the device does not advertise hue
- **THEN** the app MUST NOT show a hue slider

#### Scenario: Adjust during recording
- **WHEN** recording is in progress and the user changes an advertised picture control
- **THEN** recording MUST continue and the recorded video SHALL use the updated picture

### Requirement: Reset picture controls to device defaults
The app SHALL provide a control that resets advertised picture parameters to the device-reported default values.

#### Scenario: Reset to defaults
- **WHEN** the user activates picture reset
- **THEN** each advertised control SHALL return to the device default

#### Scenario: No picture controls
- **WHEN** the device advertises none of the picture controls
- **THEN** the app SHALL hide the picture panel and MUST NOT show a reset action that does nothing
