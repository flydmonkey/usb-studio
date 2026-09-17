import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:usb_capture/usb_capture.dart';
import 'package:usb_capture/usb_capture_method_channel.dart';
import 'package:usb_capture/usb_capture_platform_interface.dart';

class MockUsbCapturePlatform
    with MockPlatformInterfaceMixin
    implements UsbCapturePlatform {
  @override
  Future<void> close() async {}

  @override
  Stream<CaptureEvent> events() => const Stream.empty();

  @override
  Future<PlatformProfile> getPlatformProfile() async {
    return const PlatformProfile(
      usbCaptureSupported: true,
      televisionUiMode: false,
      hasUsbHost: true,
      hasTouchscreen: true,
    );
  }

  @override
  Future<List<CaptureDevice>> listDevices() async => const [];

  @override
  Future<CaptureStatus> getCaptureStatus() async => const CaptureStatus();

  @override
  Future<void> open(String deviceId) async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<bool> hasCapturePermissions() async => true;

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<void> setPreviewMuted(bool muted) async {}

  @override
  Future<List<CaptureFormat>> listFormats() async => const [];

  @override
  Future<void> setFormat(String formatId) async {}

  @override
  Future<void> setMonitorVolume(double volume) async {}

  @override
  Future<void> setMonitorDelay(int delayMs) async {}

  @override
  Future<List<PictureControl>> listPictureControls() async => const [];

  @override
  Future<void> setPictureControl(String id, int value) async {}

  @override
  Future<void> resetPictureControls() async {}

  @override
  Future<void> takeSnapshot() async {}

  @override
  Future<void> setRecordingQuality(String preset) async {}

  @override
  Future<void> startRecording({int segmentMinutes = 10}) async {}

  @override
  Future<RecordingResult> stopRecording() async {
    return const RecordingResult(path: '/tmp/a.mp4', hasAudio: true);
  }

  @override
  Future<void> startStream(String url) async {}

  @override
  Future<void> stopStream() async {}

  @override
  Future<Map<String, dynamic>> startHttpServer() async {
    return {
      'url': 'http://192.168.1.8:8080/',
      'port': 8080,
      'running': true,
    };
  }

  @override
  Future<void> stopHttpServer() async {}

  @override
  Future<Map<String, dynamic>> httpServerStatus() async {
    return {'running': false, 'url': null};
  }

  @override
  Future<List<SavedRecording>> listRecordings() async => const [];

  @override
  Future<void> shareRecording(String id) async {}

  @override
  Future<void> openRecording(String id) async {}

  @override
  Future<SavedRecording> renameRecording(String id, String displayName) async {
    return SavedRecording(id: id, name: displayName, uri: 'content://$id');
  }

  @override
  Future<void> deleteRecording(String id) async {}

  @override
  Future<SavedRecording> concatSession({
    required String sessionStamp,
    required List<String> uris,
    required String displayName,
  }) async {
    return SavedRecording(id: 'merged', name: displayName, uri: 'content://merged');
  }

  @override
  Future<void> openBatterySettings() async {}

  @override
  Future<void> setSaveLocation({required String kind, String? uri}) async {}

  @override
  Future<SaveLocation?> pickSaveFolder() async => null;

  @override
  Future<void> setUiLocale(String tag) async {}
}

void main() {
  test('MethodChannelUsbCapture is the default instance', () {
    expect(
      UsbCapturePlatform.instance,
      isA<MethodChannelUsbCapture>(),
    );
  });

  test('UsbCapture uses the platform instance', () async {
    final fakePlatform = MockUsbCapturePlatform();
    UsbCapturePlatform.instance = fakePlatform;
    final plugin = UsbCapture();
    final profile = await plugin.getPlatformProfile();
    expect(profile.usbCaptureSupported, isTrue);
    expect(await plugin.listDevices(), isEmpty);
  });

  test('SaveLocation normalizes unknown kinds to gallery', () {
    expect(SaveLocation.normalize(null), SaveLocation.gallery);
    expect(SaveLocation.normalize('movies'), SaveLocation.movies);
    expect(SaveLocation.normalize('downloads'), SaveLocation.downloads);
  });

  test('CaptureStatus restores recording HUD fields', () {
    final status = CaptureStatus.fromMap({
      'sessionOpen': true,
      'recording': true,
      'deviceId': 'usb-1',
      'segmentIndex': 2,
      'elapsedMs': 15000,
    });
    expect(status.sessionOpen, isTrue);
    expect(status.recording, isTrue);
      expect(status.elapsed.inSeconds, 15);
      expect(status.sessionStamp, isNull);
      expect(status.streaming, isFalse);
    });

  test('concatSession method channel maps a merged recording', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('usb_capture');
    final platform = MethodChannelUsbCapture();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'concatSession');
      expect(call.arguments['sessionStamp'], '20260915_153000');
      return {
        'id': 'merged',
        'name': 'USB_20260915_153000.mp4',
        'uri': 'content://merged',
      };
    });
    final merged = await platform.concatSession(
      sessionStamp: '20260915_153000',
      uris: const ['content://1', 'content://2'],
      displayName: 'USB_20260915_153000.mp4',
    );
    expect(merged.name, 'USB_20260915_153000.mp4');
  });

  test('startHttpServer method channel maps bind errors', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('usb_capture');
    final platform = MethodChannelUsbCapture();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'startHttpServer');
      throw PlatformException(code: 'streamFailed', message: 'httpBindFailed');
    });
    expect(
      () => platform.startHttpServer(),
      throwsA(
        isA<CaptureError>().having(
          (e) => e.details,
          'details',
          'httpBindFailed',
        ),
      ),
    );
  });

  test('setUiLocale method channel sends the BCP-47 tag', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('usb_capture');
    final platform = MethodChannelUsbCapture();
    String? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'setUiLocale');
      sent = (call.arguments as Map)['tag'] as String?;
      return null;
    });
    await platform.setUiLocale('zh-Hant');
    expect(sent, 'zh-Hant');
  });

  test('hasCapturePermissions method channel returns bool', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('usb_capture');
    final platform = MethodChannelUsbCapture();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'hasCapturePermissions');
      return false;
    });
    expect(await platform.hasCapturePermissions(), isFalse);
  });

  test('method channel maps permission errors', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('usb_capture');
    final platform = MethodChannelUsbCapture();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'permissionDenied');
    });
    expect(
      () => platform.requestPermissions(),
      throwsA(
        isA<CaptureError>().having(
          (e) => e.code,
          'code',
          CaptureErrorCode.permissionDenied,
        ),
      ),
    );
  });
}
