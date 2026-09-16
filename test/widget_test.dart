import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_studio/l10n/app_localizations.dart';
import 'package:usb_studio/library_page.dart';
import 'package:usb_studio/operator_prefs.dart';
import 'package:usb_studio/preview_page.dart';
import 'package:usb_capture/usb_capture.dart';
import 'package:usb_capture/usb_capture_platform_interface.dart';

class _FakePlatform extends UsbCapturePlatform with MockPlatformInterfaceMixin {
  _FakePlatform({
    this.supported = true,
    this.tv = false,
    this.devices = const [],
    this.formats = const [],
    this.pictureControls = const [],
  });

  final bool supported;
  final bool tv;
  final List<CaptureDevice> devices;
  final List<CaptureFormat> formats;
  final List<PictureControl> pictureControls;
  bool recordingStarted = false;
  int lastSegmentMinutes = 10;
  bool streamStarted = false;
  bool streamStopped = false;
  String? lastStreamUrl;
  bool httpServerStarted = false;
  bool httpServerStopped = false;
  final StreamController<CaptureEvent> eventsController =
      StreamController<CaptureEvent>.broadcast();

  @override
  Future<void> close() async {}

  @override
  Stream<CaptureEvent> events() => eventsController.stream;

  @override
  Future<PlatformProfile> getPlatformProfile() async {
    return PlatformProfile(
      usbCaptureSupported: supported,
      televisionUiMode: tv,
      hasUsbHost: supported,
      hasTouchscreen: !tv,
      customSaveFolderSupported: true,
      rtmpStreamSupported: supported,
      httpLanSupported: supported,
    );
  }

  @override
  Future<List<CaptureDevice>> listDevices() async => devices;

  @override
  Future<CaptureStatus> getCaptureStatus() async => const CaptureStatus();

  @override
  Future<void> open(String deviceId) async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> setPreviewMuted(bool muted) async {}

  @override
  Future<List<CaptureFormat>> listFormats() async => formats;

  @override
  Future<void> setFormat(String formatId) async {}

  @override
  Future<void> setMonitorVolume(double volume) async {}

  @override
  Future<void> setMonitorDelay(int delayMs) async {}

  @override
  Future<List<PictureControl>> listPictureControls() async => pictureControls;

  @override
  Future<void> setPictureControl(String id, int value) async {}

  @override
  Future<void> resetPictureControls() async {}

  @override
  Future<void> takeSnapshot() async {}

  @override
  Future<void> setRecordingQuality(String preset) async {}

  @override
  Future<void> startRecording({int segmentMinutes = 10}) async {
    recordingStarted = true;
    lastSegmentMinutes = segmentMinutes;
  }

  @override
  Future<RecordingResult> stopRecording() async {
    return const RecordingResult(
      path: '/movies/a.mp4',
      hasAudio: true,
      savedToMovies: true,
    );
  }

  @override
  Future<void> startStream(String url) async {
    streamStarted = true;
    lastStreamUrl = url;
  }

  @override
  Future<void> stopStream() async {
    streamStopped = true;
  }

  @override
  Future<Map<String, dynamic>> startHttpServer() async {
    httpServerStarted = true;
    return {
      'url': 'http://192.168.1.8:8080/',
      'port': 8080,
      'running': true,
    };
  }

  @override
  Future<void> stopHttpServer() async {
    httpServerStopped = true;
  }

  @override
  Future<Map<String, dynamic>> httpServerStatus() async {
    return {'running': false, 'url': null};
  }

  @override
  Future<List<SavedRecording>> listRecordings() async => recordings;

  @override
  Future<void> shareRecording(String id) async {
    sharedIds.add(id);
  }

  @override
  Future<void> openRecording(String id) async {
    openedIds.add(id);
  }

  @override
  Future<SavedRecording> renameRecording(String id, String displayName) async {
    final next = LibraryName.normalize(displayName);
    if (next == null) {
      throw const CaptureError(
        CaptureErrorCode.unknown,
        details: 'renameInvalid',
      );
    }
    SavedRecording? current;
    for (final item in recordings) {
      if (item.id == id) {
        current = item;
        break;
      }
    }
    if (current == null) {
      throw const CaptureError(
        CaptureErrorCode.unknown,
        details: 'renameFailed',
      );
    }
    if (LibraryName.taken(
      recordings.map((item) => item.name),
      current: current.name,
      next: next,
    )) {
      throw const CaptureError(
        CaptureErrorCode.unknown,
        details: 'renameTaken',
      );
    }
    final updated = SavedRecording(
      id: current.id,
      name: next,
      uri: current.uri,
      durationMs: current.durationMs,
      bytes: current.bytes,
      shareAvailable: current.shareAvailable,
      deleteAvailable: current.deleteAvailable,
    );
    recordings = [
      for (final item in recordings)
        if (item.id == id) updated else item,
    ];
    renamedIds.add(id);
    renamedNames.add(next);
    return updated;
  }

  @override
  Future<void> deleteRecording(String id) async {
    recordings.removeWhere((item) => item.id == id);
  }

  @override
  Future<SavedRecording> concatSession({
    required String sessionStamp,
    required List<String> uris,
    required String displayName,
  }) async {
    concatenatedStamps.add(sessionStamp);
    concatenatedUris.add(List<String>.from(uris));
    final hold = concatHold;
    if (hold != null) {
      await hold.future;
    }
    final merged = SavedRecording(
      id: 'merged-$sessionStamp',
      name: displayName,
      uri: 'content://merged/$sessionStamp',
    );
    recordings = [...recordings, merged];
    return merged;
  }

  @override
  Future<void> openBatterySettings() async {
    batterySettingsOpened = true;
  }

  @override
  Future<void> setSaveLocation({required String kind, String? uri}) async {
    savedKind = kind;
    savedUri = uri;
  }

  @override
  Future<SaveLocation?> pickSaveFolder() async {
    pickFolderCalled = true;
    return pickedFolder;
  }

  @override
  Future<void> setUiLocale(String tag) async {
    uiLocale = tag;
  }

  List<SavedRecording> recordings = [];
  final sharedIds = <String>[];
  final openedIds = <String>[];
  final renamedIds = <String>[];
  final renamedNames = <String>[];
  final concatenatedStamps = <String>[];
  final concatenatedUris = <List<String>>[];
  Completer<void>? concatHold;
  bool batterySettingsOpened = false;
  String? savedKind;
  String? savedUri;
  bool pickFolderCalled = false;
  SaveLocation? pickedFolder;
  String? uiLocale;
}

AppLocalizations zhCopy() => lookupAppLocalizations(const Locale('zh'));

Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('zh'),
}) {
  return MaterialApp(
    locale: locale,
    localeResolutionCallback: (_, _) => locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows unsupported message when capture is not supported', (
    tester,
  ) async {
    final fake = _FakePlatform(supported: false);
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Android'), findsWidgets);
    expect(find.text('开始录制'), findsOneWidget);
    expect(find.text('推流'), findsNothing);
  });

  testWidgets('TV layout uses large record control and D-pad focus', (
    tester,
  ) async {
    final fake = _FakePlatform(tv: true);
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1920, 1080)),
        child: localizedApp(
          home: PreviewPage(
            plugin: UsbCapture(),
            profile: await fake.getPlatformProfile(),
            television: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('开始录制'), findsOneWidget);
    expect(find.byTooltip('截图'), findsOneWidget);
    expect(find.text('截图'), findsNothing);
    expect(find.text('预览静音'), findsOneWidget);
    expect(find.text('请插入 USB 采集卡'), findsWidgets);
  });

  testWidgets('record button is present when there is no preview', (
    tester,
  ) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('开始录制'), findsOneWidget);
    expect(find.byTooltip('截图'), findsOneWidget);
    expect(find.text('截图'), findsNothing);
    expect(find.text('预览静音'), findsOneWidget);
    expect(find.text('开启预览'), findsNothing);
    final streamSize = tester.widget<Text>(find.text('推流')).style?.fontSize;
    expect(tester.widget<Text>(find.text('开始录制')).style?.fontSize, streamSize);
    expect(tester.widget<Text>(find.text('预览静音')).style?.fontSize, streamSize);
    await tester.tap(find.text('开始录制'));
    await tester.pump();
    expect(fake.recordingStarted, isFalse);
    expect(find.textContaining('请先连接采集卡'), findsWidgets);
  });

  testWidgets('header is not a live camcorder before a capture card is connected', (
    tester,
  ) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('请插入 USB 采集卡'), findsWidgets);
    expect(find.byIcon(Icons.videocam), findsNothing);
    expect(find.byIcon(Icons.usb_off), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.usb_off)).color,
      Colors.white70,
    );
  });

  testWidgets('can start recording after turning preview off', (tester) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
          initialPrefs: const OperatorPrefs(previewEnabled: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.usb_off), findsNothing);
    expect(find.byIcon(Icons.videocam), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.videocam)).color,
      Colors.lightGreenAccent,
    );
    expect(find.text('采集卡  ·  采集卡'), findsNothing);
    expect(find.text('采集卡'), findsOneWidget);
    expect(find.text('预览已关闭，仍可录制'), findsOneWidget);
    expect(find.text('关闭预览'), findsNothing);
    await tester.tap(find.text('开始录制'));
    await tester.pump();
    expect(fake.recordingStarted, isTrue);
    expect(find.text('停止录制'), findsOneWidget);
  });

  testWidgets('salvaged disconnect clears recording and says saved', (
    tester,
  ) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    addTearDown(fake.eventsController.close);
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('开始录制'));
    await tester.pump();
    expect(find.text('停止录制'), findsOneWidget);
    fake.eventsController.add(
      const CaptureEvent(
        type: CaptureEventType.recordingSaved,
        savedPath: '/movies/a.mp4',
        hasAudio: true,
      ),
    );
    await tester.pump();
    expect(find.text('开始录制'), findsOneWidget);
    fake.eventsController.add(
      const CaptureEvent(
        type: CaptureEventType.disconnected,
        error: CaptureError(CaptureErrorCode.disconnected),
      ),
    );
    await tester.pump();
    expect(find.text('停止录制'), findsNothing);
    expect(find.textContaining('采集卡已拔出，录制已保存'), findsWidgets);
  });

  testWidgets('disconnect without salvage does not claim saved', (
    tester,
  ) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    addTearDown(fake.eventsController.close);
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('开始录制'));
    await tester.pump();
    fake.eventsController.add(
      const CaptureEvent(
        type: CaptureEventType.disconnected,
        error: CaptureError(CaptureErrorCode.disconnected),
      ),
    );
    await tester.pump();
    expect(find.text('停止录制'), findsNothing);
    expect(find.textContaining('采集卡已拔出'), findsWidgets);
    expect(find.textContaining('录制已保存'), findsNothing);
  });

  testWidgets('segment roll keeps recording session open', (tester) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    addTearDown(fake.eventsController.close);
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('开始录制'));
    await tester.pump();
    fake.eventsController.add(
      const CaptureEvent(
        type: CaptureEventType.segmentRolled,
        savedPath: '/movies/USB_a_01.mp4',
        sessionContinuing: true,
        segmentIndex: 1,
      ),
    );
    await tester.pump();
    expect(find.text('停止录制'), findsOneWidget);
    expect(find.textContaining('第2段'), findsWidgets);
  });

  testWidgets('library shows empty copy', (tester) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(home: LibraryPage(plugin: UsbCapture(), television: false)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(zhCopy().libraryEmpty), findsOneWidget);
  });

  testWidgets('library delete asks for confirmation', (tester) async {
    final fake = _FakePlatform()
      ..recordings = const [
        SavedRecording(
          id: '1',
          name: 'USB_20260915_153000_01.mp4',
          uri: 'content://1',
        ),
      ];
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(home: LibraryPage(plugin: UsbCapture(), television: true)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('USB_20260915_153000_01.mp4'), findsOneWidget);
    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    expect(find.text(zhCopy().deleteTitle), findsOneWidget);
    expect(find.text(zhCopy().deleteConfirm), findsOneWidget);
    await tester.tap(find.text(zhCopy().cancelAction));
    await tester.pump();
    expect(fake.recordings, isNotEmpty);
  });

  testWidgets('library merge appears for a two-segment session', (
    tester,
  ) async {
    final hold = Completer<void>();
    final fake = _FakePlatform()
      ..concatHold = hold
      ..recordings = const [
        SavedRecording(
          id: '1',
          name: 'USB_20260915_153000_01.mp4',
          uri: 'content://1',
        ),
        SavedRecording(
          id: '2',
          name: 'USB_20260915_153000_02.mp4',
          uri: 'content://2',
        ),
      ];
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: LibraryPage(
          plugin: UsbCapture(),
          television: true,
          mergeEnabled: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip(zhCopy().mergeAction), findsNWidgets(2));
    await tester.tap(find.byTooltip(zhCopy().mergeAction).first);
    await tester.pump();
    expect(find.text(zhCopy().mergeProgress), findsOneWidget);
    hold.complete();
    await tester.pump();
    await tester.pump();
    expect(fake.concatenatedStamps, ['20260915_153000']);
    expect(fake.concatenatedUris.single, ['content://1', 'content://2']);
    expect(find.text('USB_20260915_153000.mp4'), findsOneWidget);
  });

  testWidgets('library hides merge for a single segment', (tester) async {
    final fake = _FakePlatform()
      ..recordings = const [
        SavedRecording(
          id: '1',
          name: 'USB_20260915_153000_01.mp4',
          uri: 'content://1',
        ),
        SavedRecording(
          id: '2',
          name: 'USB_20260915_153000.mp4',
          uri: 'content://2',
        ),
      ];
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: LibraryPage(
          plugin: UsbCapture(),
          television: false,
          mergeEnabled: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip(zhCopy().mergeAction), findsNothing);
  });

  testWidgets('library tap opens a recording and share does not', (
    tester,
  ) async {
    final fake = _FakePlatform()
      ..recordings = const [
        SavedRecording(
          id: '1',
          name: 'USB_20260915_153000_01.mp4',
          uri: 'content://1',
        ),
      ];
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(home: LibraryPage(plugin: UsbCapture(), television: false)),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('USB_20260915_153000_01.mp4'));
    await tester.pump();
    expect(fake.openedIds, ['1']);
    await tester.tap(find.byTooltip('分享'));
    await tester.pump();
    expect(fake.openedIds, ['1']);
    expect(fake.sharedIds, ['1']);
  });

  testWidgets('library rename changes the name and hides merge', (
    tester,
  ) async {
    final fake = _FakePlatform()
      ..recordings = const [
        SavedRecording(
          id: '1',
          name: 'USB_20260915_153000_01.mp4',
          uri: 'content://1',
        ),
        SavedRecording(
          id: '2',
          name: 'USB_20260915_153000_02.mp4',
          uri: 'content://2',
        ),
      ];
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: LibraryPage(
          plugin: UsbCapture(),
          television: true,
          mergeEnabled: true,
          renameEnabled: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip(zhCopy().mergeAction), findsNWidgets(2));
    await tester.tap(find.byTooltip(zhCopy().renameAction).first);
    await tester.pump();
    expect(find.text(zhCopy().renameTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), '婚礼');
    await tester.tap(find.text(zhCopy().confirmAction));
    await tester.pump();
    await tester.pump();
    expect(fake.renamedNames, ['婚礼.mp4']);
    expect(find.text('婚礼.mp4'), findsOneWidget);
    expect(find.byTooltip(zhCopy().mergeAction), findsNothing);
  });

  testWidgets('auto-record starts after connecting the only device', (
    tester,
  ) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
          initialPrefs: const OperatorPrefs(autoRecord: true),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 30 && !fake.recordingStarted; i++) {
      await tester.pump();
    }
    expect(fake.recordingStarted, isTrue);
    expect(find.text('停止录制'), findsOneWidget);
  });

  testWidgets('settings uses dropdowns for segment and save folder', (
    tester,
  ) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('设置'));
    await tester.pump();
    expect(find.text('录制分段'), findsOneWidget);
    expect(find.text('10 分钟'), findsWidgets);
    expect(find.text('录制'), findsWidgets);
    expect(find.text('预览'), findsWidgets);
    expect(find.text('录制画质'), findsOneWidget);
    expect(find.text('标准（约 60MB/分钟）'), findsWidgets);
    expect(find.text('开启预览'), findsNothing);
    expect(find.text('预览'), findsWidgets);
    expect(find.text('保存位置'), findsOneWidget);
    expect(find.text('相册'), findsWidgets);
    expect(
      tester.getTopLeft(find.text('录制').first).dy,
      lessThan(tester.getTopLeft(find.text('推流地址')).dy),
    );
    expect(
      tester.getTopLeft(find.text('预览').first).dy,
      lessThan(tester.getTopLeft(find.text('局域网播放').first).dy),
    );
  });

  testWidgets(
    'settings sheet stays below the status bar and closes with a button',
    (tester) async {
      tester.view.physicalSize = const Size(400, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 48);
      tester.view.viewPadding = const FakeViewPadding(top: 48);
      addTearDown(tester.view.reset);

      final fake = _FakePlatform(
        devices: const [
          CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true),
        ],
        formats: const [
          CaptureFormat(
            id: 'f1',
            width: 1920,
            height: 1080,
            fps: 60,
            fourcc: 'NV12',
          ),
          CaptureFormat(
            id: 'f2',
            width: 1280,
            height: 720,
            fps: 30,
            fourcc: 'YUY2',
          ),
        ],
        pictureControls: const [
          PictureControl(
            id: PictureControlId.brightness,
            min: 0,
            max: 100,
            value: 50,
            defaultValue: 50,
          ),
          PictureControl(
            id: PictureControlId.contrast,
            min: 0,
            max: 100,
            value: 50,
            defaultValue: 50,
          ),
          PictureControl(
            id: PictureControlId.saturation,
            min: 0,
            max: 100,
            value: 50,
            defaultValue: 50,
          ),
          PictureControl(
            id: PictureControlId.hue,
            min: 0,
            max: 100,
            value: 50,
            defaultValue: 50,
          ),
        ],
      );
      UsbCapturePlatform.instance = fake;
      await tester.pumpWidget(
        localizedApp(
          home: PreviewPage(
            plugin: UsbCapture(),
            profile: await fake.getPlatformProfile(),
            television: false,
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 30 && find.text('采集卡').evaluate().isEmpty; i++) {
        await tester.pump();
      }
      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('关闭'), findsOneWidget);
      expect(tester.getTopLeft(find.text('采集设置')).dy, greaterThanOrEqualTo(48));
      expect(find.textContaining('亮度'), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -280),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('关闭'), findsOneWidget);
      expect(tester.getTopLeft(find.text('采集设置')).dy, greaterThanOrEqualTo(48));
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(find.text('录制分段'), findsNothing);
    },
  );

  testWidgets('stream toggle joins url and can run with recording', (
    tester,
  ) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
          initialPrefs: const OperatorPrefs(
            rtmpServer: 'rtmp://live.example/live/',
            rtmpKey: 'streamkey',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('推流'), findsOneWidget);
    await tester.tap(find.text('推流'));
    await tester.pump();
    expect(fake.streamStarted, isTrue);
    expect(fake.lastStreamUrl, 'rtmp://live.example/live/streamkey');
    expect(find.text('停止推流'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    await tester.tap(find.text('开始录制'));
    await tester.pump();
    expect(fake.recordingStarted, isTrue);
    expect(find.text('停止录制'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('settings shows lan playback toggle on Android', (tester) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('设置'));
    await tester.pump();
    final lanSwitch = find.byKey(const Key('lan-playback'));
    expect(lanSwitch, findsOneWidget);
    await tester.ensureVisible(lanSwitch);
    await tester.pumpAndSettle();
    await tester.tap(lanSwitch);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('http://'), findsOneWidget);
    expect(
      find.text('同一 Wi-Fi 下打开此地址即可播放；未加密'),
      findsOneWidget,
    );
    expect(fake.httpServerStarted, isTrue);
  });

  testWidgets('settings can turn lan playback off after turning on', (
    tester,
  ) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('设置'));
    await tester.pump();
    final lanSwitch = find.byKey(const Key('lan-playback'));
    expect(lanSwitch, findsOneWidget);
    await tester.ensureVisible(lanSwitch);
    await tester.pumpAndSettle();

    await tester.tap(lanSwitch);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('http://'), findsOneWidget);
    expect(fake.httpServerStarted, isTrue);

    await tester.tap(lanSwitch);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('http://'), findsNothing);
    expect(fake.httpServerStopped, isTrue);
    final tile = tester.widget<Switch>(lanSwitch);
    expect(tile.value, isFalse);
  });

  testWidgets('settings hides lan playback when unsupported', (
    tester,
  ) async {
    final fake = _FakePlatform(supported: false);
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('设置'));
    await tester.pump();
    expect(find.text('局域网播放'), findsNothing);
  });

  testWidgets('bootstrap starts http server when lan playback pref is on', (
    tester,
  ) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
          initialPrefs: const OperatorPrefs(httpLanEnabled: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    for (var i = 0; i < 30 && !fake.httpServerStarted; i++) {
      await tester.pump();
    }
    expect(fake.httpServerStarted, isTrue);
  });

  testWidgets('stream without address asks the operator to fill both fields', (
    tester,
  ) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('推流'));
    await tester.pump();
    expect(fake.streamStarted, isFalse);
    expect(find.textContaining('请先填写推流地址'), findsWidgets);
    expect(find.textContaining('密钥'), findsNothing);
  });

  testWidgets('stream with full rtmp url does not need a key', (tester) async {
    final fake = _FakePlatform(
      devices: const [CaptureDevice(id: 'usb-1', name: '采集卡', hasAudio: true)],
    );
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
          initialPrefs: const OperatorPrefs(
            rtmpServer: 'rtmp://live.example/live/stream',
            rtmpKey: '',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('推流'));
    await tester.pump();
    expect(fake.streamStarted, isTrue);
    expect(fake.lastStreamUrl, 'rtmp://live.example/live/stream');
  });

  testWidgets('english locale uses english capture bar', (tester) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Record'), findsOneWidget);
    expect(find.textContaining('录制'), findsNothing);
    expect(find.text('请插入 USB 采集卡'), findsNothing);
    expect(find.text('Insert USB capture'), findsWidgets);
  });

  testWidgets('japanese locale uses japanese capture bar', (tester) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('ja'),
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('録画'), findsOneWidget);
    expect(find.textContaining('录制'), findsNothing);
  });

  testWidgets('korean locale uses korean capture bar', (tester) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('ko'),
        home: PreviewPage(
          plugin: UsbCapture(),
          profile: await fake.getPlatformProfile(),
          television: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('녹화'), findsOneWidget);
    expect(find.textContaining('录制'), findsNothing);
  });

  testWidgets('language override refreshes capture bar', (tester) async {
    final fake = _FakePlatform();
    UsbCapturePlatform.instance = fake;
    var locale = const Locale('zh');
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setSt) {
          return localizedApp(
            locale: locale,
            home: PreviewPage(
              plugin: UsbCapture(),
              profile: PlatformProfile(
                usbCaptureSupported: true,
                televisionUiMode: false,
                hasUsbHost: true,
                hasTouchscreen: true,
                customSaveFolderSupported: true,
                rtmpStreamSupported: true,
                httpLanSupported: true,
              ),
              television: false,
              onLocaleMode: (mode) {
                locale = mode.resolve(const Locale('zh', 'CN'));
                setSt(() {});
              },
            ),
          );
        },
      ),
    );
    await tester.pump();
    expect(find.text('开始录制'), findsOneWidget);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('跟随系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Record'), findsOneWidget);
    expect(fake.uiLocale, 'en');
    expect(find.text('请插入 USB 采集卡'), findsNothing);
    expect(find.text('Insert USB capture'), findsWidgets);
  });
}
