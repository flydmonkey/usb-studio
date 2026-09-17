import 'capture_device.dart';
import 'capture_error.dart';
import 'signal_status.dart';

enum CaptureEventType {
  attached,
  detached,
  disconnected,
  audioUnavailable,
  recordingSaved,
  segmentRolled,
  batteryOptimizationHint,
  signal,
  audioPeak,
  streamStarted,
  streamStopped,
  lanLiveBusy,
  error,
}

class CaptureEvent {
  const CaptureEvent({
    required this.type,
    this.device,
    this.deviceId,
    this.error,
    this.savedPath,
    this.hasAudio,
    this.signal,
    this.audioPeak,
    this.sessionContinuing = false,
    this.segmentIndex,
    this.elapsedMs,
    this.busy = false,
  });

  final CaptureEventType type;
  final CaptureDevice? device;
  final String? deviceId;
  final CaptureError? error;
  final String? savedPath;
  final bool? hasAudio;
  final SignalStatus? signal;
  final double? audioPeak;
  final bool sessionContinuing;
  final int? segmentIndex;
  final int? elapsedMs;
  final bool busy;

  factory CaptureEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String? ?? 'error';
    final type = CaptureEventType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => CaptureEventType.error,
    );
    final deviceMap = map['device'];
    final hasSignalFields =
        map.containsKey('width') ||
        map.containsKey('hasSignal') ||
        map.containsKey('fourcc') ||
        map.containsKey('bytesWritten');
    return CaptureEvent(
      type: type,
      device: deviceMap is Map ? CaptureDevice.fromMap(deviceMap) : null,
      deviceId: map['deviceId'] as String?,
      error: map['code'] != null
          ? CaptureError.fromCode(
              map['code'] as String?,
              details: map['message'] as String?,
            )
          : null,
      savedPath: map['path'] as String?,
      hasAudio: map['hasAudio'] as bool?,
      signal: hasSignalFields ? SignalStatus.fromMap(map) : null,
      audioPeak: (map['peak'] as num?)?.toDouble(),
      sessionContinuing: map['sessionContinuing'] as bool? ?? false,
      segmentIndex: (map['segmentIndex'] as num?)?.toInt(),
      elapsedMs: (map['elapsedMs'] as num?)?.toInt(),
      busy: map['busy'] as bool? ?? false,
    );
  }
}
