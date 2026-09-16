import 'capture_error.dart';
import 'capture_format.dart';
import 'picture_control.dart';
import 'signal_status.dart';

enum RecordingStatus { idle, recording }

class CaptureSessionRules {
  static void ensureCanChangeFormat({
    required bool isRecording,
    bool isStreaming = false,
  }) {
    if (isRecording) {
      throw const CaptureError(
        CaptureErrorCode.recordingFailed,
        details: 'recordingInProgress',
      );
    }
    if (isStreaming) {
      throw const CaptureError(
        CaptureErrorCode.streamFailed,
        details: 'streamInProgress',
      );
    }
  }

  static void ensureCanChangeQuality({
    required bool isRecording,
    bool isStreaming = false,
  }) {
    if (isRecording) {
      throw const CaptureError(
        CaptureErrorCode.recordingFailed,
        details: 'recordingInProgress',
      );
    }
    if (isStreaming) {
      throw const CaptureError(
        CaptureErrorCode.streamFailed,
        details: 'streamInProgress',
      );
    }
  }

  static void ensureCanChangeSegment({required bool isRecording}) {
    if (isRecording) {
      throw const CaptureError(
        CaptureErrorCode.recordingFailed,
        details: 'recordingInProgress',
      );
    }
  }

  static bool shouldAutoStart({
    required bool autoRecord,
    required bool sessionOpen,
    required bool isRecording,
    required bool deferUntilReconnect,
  }) {
    return autoRecord && sessionOpen && !isRecording && !deferUntilReconnect;
  }

  static void ensureCanSnapshot({
    required bool previewActive,
    bool sessionOpen = false,
  }) {
    if (!previewActive) {
      throw CaptureError(
        CaptureErrorCode.noPreview,
        details: sessionOpen ? 'previewOff' : null,
      );
    }
  }

  static String interruptStatus({
    required bool disconnected,
    required bool saved,
    required bool television,
  }) {
    if (disconnected) {
      if (!saved) {
        return '采集卡已拔出';
      }
      return television ? '采集卡已拔出，已保存到影片目录' : '采集卡已拔出，录制已保存';
    }
    if (saved) {
      return television ? '录制中断，已保存到影片目录' : '录制中断，录制已保存';
    }
    return '录制失败。';
  }
}

class SessionState {
  const SessionState({
    this.sessionOpen = false,
    this.previewEnabled = true,
    this.recording = RecordingStatus.idle,
    this.previewMuted = false,
    this.elapsed = Duration.zero,
    this.signal = const SignalStatus(),
    this.audioPeak = 0,
    this.monitorVolume = 1,
    this.monitorDelayMs = 0,
    this.quality = QualityPreset.standard,
    this.immersive = false,
    this.formats = const [],
    this.selectedFormatId,
    this.pictureControls = const [],
    this.audioAvailable = true,
    this.lastRecordingSalvaged = false,
    this.segmentIndex = 1,
    this.publishedSegmentCount = 0,
    this.segmentMinutes = 10,
    this.autoRecord = false,
    this.streaming = false,
  });

  final bool sessionOpen;
  final bool previewEnabled;
  final RecordingStatus recording;
  final bool previewMuted;
  final Duration elapsed;
  final SignalStatus signal;
  final double audioPeak;
  final double monitorVolume;
  final int monitorDelayMs;
  final QualityPreset quality;
  final bool immersive;
  final List<CaptureFormat> formats;
  final String? selectedFormatId;
  final List<PictureControl> pictureControls;
  final bool audioAvailable;
  final bool lastRecordingSalvaged;
  final int segmentIndex;
  final int publishedSegmentCount;
  final int segmentMinutes;
  final bool autoRecord;
  final bool streaming;

  bool get previewActive => sessionOpen && previewEnabled;
  bool get isRecording => recording == RecordingStatus.recording;
  bool get isStreaming => streaming;

  SessionState copyWith({
    bool? sessionOpen,
    bool? previewEnabled,
    RecordingStatus? recording,
    bool? previewMuted,
    Duration? elapsed,
    SignalStatus? signal,
    double? audioPeak,
    double? monitorVolume,
    int? monitorDelayMs,
    QualityPreset? quality,
    bool? immersive,
    List<CaptureFormat>? formats,
    String? selectedFormatId,
    List<PictureControl>? pictureControls,
    bool? audioAvailable,
    bool? lastRecordingSalvaged,
    int? segmentIndex,
    int? publishedSegmentCount,
    int? segmentMinutes,
    bool? autoRecord,
    bool? streaming,
  }) {
    return SessionState(
      sessionOpen: sessionOpen ?? this.sessionOpen,
      previewEnabled: previewEnabled ?? this.previewEnabled,
      recording: recording ?? this.recording,
      previewMuted: previewMuted ?? this.previewMuted,
      elapsed: elapsed ?? this.elapsed,
      signal: signal ?? this.signal,
      audioPeak: audioPeak ?? this.audioPeak,
      monitorVolume: monitorVolume ?? this.monitorVolume,
      monitorDelayMs: monitorDelayMs ?? this.monitorDelayMs,
      quality: quality ?? this.quality,
      immersive: immersive ?? this.immersive,
      formats: formats ?? this.formats,
      selectedFormatId: selectedFormatId ?? this.selectedFormatId,
      pictureControls: pictureControls ?? this.pictureControls,
      audioAvailable: audioAvailable ?? this.audioAvailable,
      lastRecordingSalvaged:
          lastRecordingSalvaged ?? this.lastRecordingSalvaged,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      publishedSegmentCount:
          publishedSegmentCount ?? this.publishedSegmentCount,
      segmentMinutes: segmentMinutes ?? this.segmentMinutes,
      autoRecord: autoRecord ?? this.autoRecord,
      streaming: streaming ?? this.streaming,
    );
  }

  SessionState togglePreview() {
    if (!sessionOpen) {
      return this;
    }
    final enabled = !previewEnabled;
    return copyWith(
      previewEnabled: enabled,
      immersive: enabled ? immersive : false,
    );
  }

  SessionState startRecording() {
    if (!sessionOpen) {
      throw StateError('noPreview');
    }
    return copyWith(
      recording: RecordingStatus.recording,
      elapsed: Duration.zero,
      lastRecordingSalvaged: false,
      segmentIndex: 1,
      publishedSegmentCount: 0,
    );
  }

  SessionState onSegmentPublished({required int completedIndex}) {
    return copyWith(
      publishedSegmentCount: publishedSegmentCount + 1,
      segmentIndex: completedIndex + 1,
    );
  }

  SessionState stopRecording() {
    return copyWith(
      recording: RecordingStatus.idle,
      elapsed: Duration.zero,
      signal: signal.copyWith(bytesWritten: 0),
      lastRecordingSalvaged: false,
    );
  }

  SessionState startStreaming() {
    if (!sessionOpen) {
      throw StateError('noPreview');
    }
    return copyWith(streaming: true);
  }

  SessionState stopStreaming() {
    return copyWith(streaming: false);
  }

  SessionState interruptRecording({required bool saved}) {
    return copyWith(
      recording: RecordingStatus.idle,
      elapsed: Duration.zero,
      lastRecordingSalvaged: saved,
      signal: signal.copyWith(bytesWritten: 0),
    );
  }

  SessionState onDisconnected() {
    return SessionState(
      previewMuted: previewMuted,
      monitorVolume: monitorVolume,
      monitorDelayMs: monitorDelayMs,
      segmentMinutes: segmentMinutes,
      autoRecord: autoRecord,
    );
  }
}
