import 'package:flutter_test/flutter_test.dart';
import 'package:usb_capture/src/capture_error.dart';
import 'package:usb_capture/src/capture_event.dart';
import 'package:usb_capture/src/capture_format.dart';
import 'package:usb_capture/src/picture_control.dart';
import 'package:usb_capture/src/platform_profile.dart';
import 'package:usb_capture/src/session_state.dart';
import 'package:usb_capture/src/signal_status.dart';
import 'package:usb_capture/src/capture_audio_policy.dart';
import 'package:usb_capture/src/library_name.dart';
import 'package:usb_capture/src/segment_policy.dart';
import 'package:usb_capture/src/lan_http_url.dart';
import 'package:usb_capture/src/stream_url.dart';

void main() {
  group('CaptureError mapping', () {
    test('maps known platform codes', () {
      expect(
        CaptureError.fromCode('permissionDenied').code,
        CaptureErrorCode.permissionDenied,
      );
      expect(
        CaptureError.fromCode('usbHostMissing').code,
        CaptureErrorCode.usbHostMissing,
      );
      expect(
        CaptureError.fromCode('powerIssue').code,
        CaptureErrorCode.powerIssue,
      );
      expect(
        CaptureError.fromCode('unsupportedPlatform').code,
        CaptureErrorCode.unsupportedPlatform,
      );
    });

    test('diagnostic message is code plus details, not UI copy', () {
      expect(
        CaptureError.fromCode('permissionDenied').message,
        'permissionDenied',
      );
      expect(
        CaptureError.fromCode('recordingFailed', details: 'concatFailed')
            .message,
        'recordingFailed: concatFailed',
      );
      expect(CaptureError.fromCode('usbHostMissing').message, isNot(contains('采集卡')));
    });

    test('unknown codes stay unknown', () {
      expect(CaptureError.fromCode('nope').code, CaptureErrorCode.unknown);
    });
  });

  group('television layout', () {
    test('uses native television uiMode', () {
      expect(
        useTelevisionLayout(
          nativeTelevision: true,
          hasTouch: true,
          shortestSide: 400,
        ),
        isTrue,
      );
    });

    test('uses large untouchable screens as TV boxes', () {
      expect(
        useTelevisionLayout(
          nativeTelevision: false,
          hasTouch: false,
          shortestSide: 720,
        ),
        isTrue,
      );
    });

    test('phones stay touch-first', () {
      expect(
        useTelevisionLayout(
          nativeTelevision: false,
          hasTouch: true,
          shortestSide: 400,
        ),
        isFalse,
      );
    });
  });

  group('recording state machine', () {
    test('cannot start without an open session', () {
      expect(
        () => const SessionState().startRecording(),
        throwsA(isA<StateError>()),
      );
    });

    test('starts and stops while session is open', () {
      final recording = const SessionState(sessionOpen: true).startRecording();
      expect(recording.isRecording, isTrue);
      expect(recording.stopRecording().isRecording, isFalse);
    });

    test('can record with preview turned off', () {
      final recording = const SessionState(
        sessionOpen: true,
        previewEnabled: false,
      ).startRecording();
      expect(recording.isRecording, isTrue);
      expect(recording.previewActive, isFalse);
    });

    test('toggling preview does not close the session', () {
      final hidden = const SessionState(sessionOpen: true).togglePreview();
      expect(hidden.sessionOpen, isTrue);
      expect(hidden.previewEnabled, isFalse);
      expect(hidden.previewActive, isFalse);
      expect(hidden.togglePreview().previewActive, isTrue);
    });

    test('disconnect clears preview and recording', () {
      final disconnected = const SessionState(sessionOpen: true)
          .startRecording()
          .onDisconnected();
      expect(disconnected.previewActive, isFalse);
      expect(disconnected.sessionOpen, isFalse);
      expect(disconnected.isRecording, isFalse);
    });

    test('rejects format change while recording', () {
      final recording = const SessionState(sessionOpen: true).startRecording();
      expect(
        () => CaptureSessionRules.ensureCanChangeFormat(isRecording: recording.isRecording),
        throwsA(
          isA<CaptureError>().having(
            (e) => e.code,
            'code',
            CaptureErrorCode.recordingFailed,
          ),
        ),
      );
    });

    test('allows format change during preview', () {
      CaptureSessionRules.ensureCanChangeFormat(isRecording: false);
    });

    test('rejects snapshot without preview', () {
      expect(
        () => CaptureSessionRules.ensureCanSnapshot(previewActive: false),
        throwsA(
          isA<CaptureError>().having(
            (e) => e.code,
            'code',
            CaptureErrorCode.noPreview,
          ),
        ),
      );
    });

    test('snapshot while session is open but preview is off asks to enable preview', () {
      expect(
        () => CaptureSessionRules.ensureCanSnapshot(
          previewActive: false,
          sessionOpen: true,
        ),
        throwsA(
          isA<CaptureError>().having(
            (e) => e.details,
            'details',
            'previewOff',
          ),
        ),
      );
    });

    test('rejects quality change while recording', () {
      expect(
        () => CaptureSessionRules.ensureCanChangeQuality(isRecording: true),
        throwsA(isA<CaptureError>()),
      );
    });

    test('interrupt with salvage exits recording and marks saved', () {
      final interrupted = const SessionState(sessionOpen: true)
          .startRecording()
          .interruptRecording(saved: true);
      expect(interrupted.isRecording, isFalse);
      expect(interrupted.lastRecordingSalvaged, isTrue);
    });

    test('interrupt without salvage exits recording and does not claim saved', () {
      final interrupted = const SessionState(sessionOpen: true)
          .startRecording()
          .interruptRecording(saved: false);
      expect(interrupted.isRecording, isFalse);
      expect(interrupted.lastRecordingSalvaged, isFalse);
    });

    test('must not fall back to the built-in microphone', () {
      expect(CaptureAudioPolicy.allowBuiltinMicFallback, isFalse);
      expect(CaptureAudioPolicy.canRecordAudio(hasUsbAudioDevice: false), isFalse);
      expect(CaptureAudioPolicy.canRecordAudio(hasUsbAudioDevice: true), isTrue);
    });

    test('groups USB_stamp_NN files and names the merged output', () {
      const stamp = '20260915_153000';
      final names = [
        'USB_20260915_153000_02.mp4',
        'USB_20260915_153000_01.mp4',
        'USB_20260915_153001_01.mp4',
        'USB_20260915_153000.mp4',
        'USB_20260915_153000_merged.mp4',
      ];
      expect(SegmentPolicy.parseSegmentName('USB_${stamp}_01.mp4')?.stamp, stamp);
      expect(SegmentPolicy.parseSegmentName('USB_${stamp}_01.mp4')?.index, 1);
      expect(SegmentPolicy.parseSegmentName('USB_$stamp.mp4'), isNull);
      expect(SegmentPolicy.parseSegmentName('USB_${stamp}_merged.mp4'), isNull);
      expect(SegmentPolicy.canMergeSession(names, 'USB_${stamp}_01.mp4'), isTrue);
      expect(SegmentPolicy.canMergeSession(names, 'USB_20260915_153001_01.mp4'), isFalse);
      expect(SegmentPolicy.canMergeSession(names, 'USB_$stamp.mp4'), isFalse);
      final grouped = SegmentPolicy.groupBySession(names, (name) => name);
      expect(grouped[stamp]?.map((name) => name).toList(), [
        'USB_${stamp}_01.mp4',
        'USB_${stamp}_02.mp4',
      ]);
      expect(SegmentPolicy.mergedFileName(stamp, const []), 'USB_$stamp.mp4');
      expect(
        SegmentPolicy.mergedFileName(stamp, ['USB_$stamp.mp4']),
        'USB_${stamp}_merged.mp4',
      );
      expect(
        SegmentPolicy.mergedFileName(stamp, [
          'USB_$stamp.mp4',
          'USB_${stamp}_merged.mp4',
        ]),
        'USB_${stamp}_merged2.mp4',
      );
    });

    test('segment filenames start at 01 and increment', () {
      const stamp = '20260915_153000';
      expect(SegmentPolicy.fileName(stamp, 1, segmented: true), 'USB_20260915_153000_01.mp4');
      expect(SegmentPolicy.fileName(stamp, 2, segmented: true), 'USB_20260915_153000_02.mp4');
      expect(SegmentPolicy.fileName(stamp, 1, segmented: false), 'USB_20260915_153000.mp4');
      expect(SegmentPolicy.nextIndex(1), 2);
      expect(SegmentPolicy.duration, const Duration(minutes: 10));
      expect(SegmentPolicy.normalizeMinutes(8), 10);
      expect(SegmentPolicy.normalizeMinutes(1), 1);
      expect(SegmentPolicy.allowedMinutes, containsAll([0, 1, 5, 10, 15, 30]));
      expect(
        SegmentPolicy.formatElapsed(
          const Duration(hours: 1, minutes: 2, seconds: 4),
        ),
        '01:02:04',
      );
    });

    test('auto-record waits for reconnect after a manual stop', () {
      expect(
        CaptureSessionRules.shouldAutoStart(
          autoRecord: true,
          sessionOpen: true,
          isRecording: false,
          deferUntilReconnect: false,
        ),
        isTrue,
      );
      expect(
        CaptureSessionRules.shouldAutoStart(
          autoRecord: true,
          sessionOpen: true,
          isRecording: false,
          deferUntilReconnect: true,
        ),
        isFalse,
      );
      expect(
        CaptureSessionRules.shouldAutoStart(
          autoRecord: false,
          sessionOpen: true,
          isRecording: false,
          deferUntilReconnect: false,
        ),
        isFalse,
      );
    });

    test('interrupt salvage does not drop already published segments', () {
      var state = const SessionState(sessionOpen: true).startRecording();
      expect(state.segmentIndex, 1);
      expect(state.publishedSegmentCount, 0);
      state = state.onSegmentPublished(completedIndex: 1);
      state = state.onSegmentPublished(completedIndex: 2);
      expect(state.segmentIndex, 3);
      expect(state.publishedSegmentCount, 2);
      state = state.interruptRecording(saved: true);
      expect(state.isRecording, isFalse);
      expect(state.lastRecordingSalvaged, isTrue);
      expect(state.publishedSegmentCount, 2);
    });
  });

  group('library errors', () {
    test('concat errors keep details for the app to localize', () {
      expect(
        const CaptureError(
          CaptureErrorCode.recordingFailed,
          details: 'sessionRecording',
        ).details,
        'sessionRecording',
      );
      expect(
        const CaptureError(
          CaptureErrorCode.recordingFailed,
          details: 'concatUnsupported',
        ).details,
        'concatUnsupported',
      );
    });

    test('play and rename errors keep details for the app to localize', () {
      expect(
        const CaptureError(
          CaptureErrorCode.unknown,
          details: 'playFailed',
        ).details,
        'playFailed',
      );
      expect(
        const CaptureError(
          CaptureErrorCode.unknown,
          details: 'renameTaken',
        ).details,
        'renameTaken',
      );
      expect(
        const CaptureError(
          CaptureErrorCode.unknown,
          details: 'renameInvalid',
        ).details,
        'renameInvalid',
      );
      expect(
        const CaptureError(
          CaptureErrorCode.unknown,
          details: 'renameUnsupported',
        ).details,
        'renameUnsupported',
      );
    });

    test('normalizes library file names', () {
      expect(LibraryName.normalize('婚礼'), '婚礼.mp4');
      expect(LibraryName.normalize(' 婚礼.mp4 '), '婚礼.mp4');
      expect(LibraryName.normalize('USB_a.MP4'), 'USB_a.mp4');
      expect(LibraryName.normalize(''), isNull);
      expect(LibraryName.normalize('.mp4'), isNull);
      expect(LibraryName.normalize('a/b'), isNull);
      expect(LibraryName.normalize('a:b'), isNull);
      expect(LibraryName.same('婚礼.mp4', '婚礼.MP4'), isTrue);
      expect(
        LibraryName.taken(
          const ['婚礼.mp4', 'USB_a_01.mp4'],
          current: 'USB_a_01.mp4',
          next: '婚礼.mp4',
        ),
        isTrue,
      );
      expect(
        LibraryName.taken(
          const ['USB_a_01.mp4'],
          current: 'USB_a_01.mp4',
          next: 'USB_a_01.mp4',
        ),
        isFalse,
      );
    });
  });

  group('operator models', () {
    test('parses format, signal, picture control and events', () {
      final format = CaptureFormat.fromMap({
        'id': '1:1920x1080@30',
        'width': 1920,
        'height': 1080,
        'fps': 30,
        'fourcc': 'MJPG',
      });
      expect(format.label, '1920×1080 30fps MJPG');
      final signal = SignalStatus.fromMap({
        'width': 1920,
        'height': 1080,
        'fps': 30,
        'fourcc': 'MJPG',
        'hasSignal': true,
        'bytesWritten': 1024,
      });
      expect(signal.hasSignal, isTrue);
      expect(signal.bytesWritten, 1024);
      expect(signal.hudLabel, '1920×1080 30fps MJPG');
      expect(const SignalStatus().hudLabel, isEmpty);
      final control = PictureControl.fromMap({
        'id': 'brightness',
        'label': '亮度',
        'min': 0,
        'max': 100,
        'value': 40,
        'defaultValue': 50,
      });
      expect(control.id, PictureControlId.brightness);
      expect(QualityPreset.parse('high'), QualityPreset.high);
      expect(QualityPreset.parse('tiny'), QualityPreset.tiny);
      expect(QualityPreset.parse('small'), QualityPreset.small);
      final event = CaptureEvent.fromMap({
        'type': 'signal',
        'width': 1280,
        'height': 720,
        'fps': 30,
        'fourcc': 'YUY2',
        'hasSignal': false,
        'peak': 0.4,
      });
      expect(event.type, CaptureEventType.signal);
      expect(event.signal?.hasSignal, isFalse);
      expect(event.audioPeak, 0.4);
      final rolled = CaptureEvent.fromMap({
        'type': 'segmentRolled',
        'path': '/movies/USB_20260915_153000_01.mp4',
        'segmentIndex': 1,
        'sessionContinuing': true,
        'elapsedMs': 600000,
      });
      expect(rolled.type, CaptureEventType.segmentRolled);
      expect(rolled.sessionContinuing, isTrue);
      expect(rolled.segmentIndex, 1);
      expect(
        CaptureEvent.fromMap({'type': 'batteryOptimizationHint'}).type,
        CaptureEventType.batteryOptimizationHint,
      );
      expect(
        CaptureEvent.fromMap({'type': 'streamStarted'}).type,
        CaptureEventType.streamStarted,
      );
    });
  });

  group('lan http url', () {
    test('builds lan http display url and picks ipv4', () {
      expect(
        LanHttpUrl.display(ipv4: '192.168.1.8', port: 8080),
        'http://192.168.1.8:8080/',
      );
      expect(
        LanHttpUrl.pickIpv4(['127.0.0.1', '192.168.1.8', '::1']),
        '192.168.1.8',
      );
      expect(LanHttpUrl.pickIpv4(['127.0.0.1']), isNull);
      expect(
        CaptureError.fromCode('streamFailed', details: 'httpNoNetwork').details,
        'httpNoNetwork',
      );
      expect(
        CaptureError.fromCode('streamFailed', details: 'httpLiveFailed')
            .details,
        'httpLiveFailed',
      );
      expect(CaptureError.isCodecNoMemory('Error 0xfffffff4'), isTrue);
      expect(CaptureError.isCodecNoMemory('no_memory'), isTrue);
      expect(CaptureError.isCodecNoMemory('httpLiveFailed'), isFalse);
    });
  });

  group('rtmp stream url', () {
    test('joins server and key', () {
      expect(
        StreamUrl.join(
          server: 'rtmp://live.example/live/',
          key: 'streamkey',
        ),
        'rtmp://live.example/live/streamkey',
      );
      expect(
        StreamUrl.join(server: 'rtmps://live.example/app', key: '?token=1'),
        'rtmps://live.example/app?token=1',
      );
      expect(StreamUrl.join(server: '', key: 'k'), isNull);
      expect(StreamUrl.join(server: 'http://x', key: 'k'), isNull);
      expect(
        StreamUrl.join(
          server: 'rtmp://live.example/live/stream',
          key: '',
        ),
        'rtmp://live.example/live/stream',
      );
      expect(StreamUrl.join(server: 'rtmp://live.example', key: ''), isNull);
    });

    test('maps stream errors', () {
      expect(
        CaptureError.fromCode('streamFailed', details: 'missingUrl').details,
        'missingUrl',
      );
      expect(
        CaptureError.fromCode('streamFailed', details: 'streamUnsupported')
            .details,
        'streamUnsupported',
      );
    });

    test('can stream while recording', () {
      final live = const SessionState(sessionOpen: true)
          .startRecording()
          .startStreaming();
      expect(live.isRecording, isTrue);
      expect(live.isStreaming, isTrue);
      expect(live.stopStreaming().isRecording, isTrue);
      expect(
        () => CaptureSessionRules.ensureCanChangeQuality(
          isRecording: false,
          isStreaming: true,
        ),
        throwsA(
          isA<CaptureError>().having(
            (error) => error.details,
            'details',
            'streamInProgress',
          ),
        ),
      );
    });
  });

  group('PlatformProfile', () {
    test('reads httpLanSupported from map', () {
      expect(
        PlatformProfile.fromMap({'httpLanSupported': true}).httpLanSupported,
        isTrue,
      );
    });

    test('defaults httpLanSupported to false', () {
      expect(PlatformProfile.fromMap({}).httpLanSupported, isFalse);
    });
  });
}
