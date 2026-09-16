class CaptureStatus {
  const CaptureStatus({
    this.sessionOpen = false,
    this.recording = false,
    this.deviceId,
    this.segmentIndex = 1,
    this.elapsedMs = 0,
    this.sessionStamp,
    this.streaming = false,
  });

  final bool sessionOpen;
  final bool recording;
  final String? deviceId;
  final int segmentIndex;
  final int elapsedMs;
  final String? sessionStamp;
  final bool streaming;

  Duration get elapsed => Duration(milliseconds: elapsedMs < 0 ? 0 : elapsedMs);

  factory CaptureStatus.fromMap(Map<dynamic, dynamic> map) {
    return CaptureStatus(
      sessionOpen: map['sessionOpen'] as bool? ?? false,
      recording: map['recording'] as bool? ?? false,
      deviceId: map['deviceId'] as String?,
      segmentIndex: (map['segmentIndex'] as num?)?.toInt() ?? 1,
      elapsedMs: (map['elapsedMs'] as num?)?.toInt() ?? 0,
      sessionStamp: map['sessionStamp'] as String?,
      streaming: map['streaming'] as bool? ?? false,
    );
  }
}
