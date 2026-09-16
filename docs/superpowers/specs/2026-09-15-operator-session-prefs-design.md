# Operator session preferences

Approved 2026-09-15.

Preferences persist in Flutter (`shared_preferences`). Native recording receives `segmentMinutes` at start (`0` = one file). Auto-record runs after a successful Flutter connect unless the operator just stopped while the card stayed plugged in. Preview mute, volume, and delay restore after `open` and stay synced with the bottom mute button.
