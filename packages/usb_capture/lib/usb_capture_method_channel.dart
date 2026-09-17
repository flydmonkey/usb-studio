import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/capture_device.dart';
import 'src/capture_error.dart';
import 'src/capture_event.dart';
import 'src/capture_format.dart';
import 'src/capture_status.dart';
import 'src/picture_control.dart';
import 'src/platform_profile.dart';
import 'src/recording_result.dart';
import 'src/save_location.dart';
import 'src/saved_recording.dart';
import 'usb_capture_platform_interface.dart';

class MethodChannelUsbCapture extends UsbCapturePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('usb_capture');

  @visibleForTesting
  final eventChannel = const EventChannel('usb_capture/events');

  @override
  Future<PlatformProfile> getPlatformProfile() async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'getPlatformProfile',
    );
    return PlatformProfile.fromMap(map ?? const {});
  }

  @override
  Future<void> requestPermissions() async {
    await _invoke('requestPermissions');
  }

  @override
  Future<bool> hasCapturePermissions() async {
    final value = await methodChannel.invokeMethod<bool>(
      'hasCapturePermissions',
    );
    return value ?? false;
  }

  @override
  Future<void> requestNotificationPermission() async {
    await _invoke('requestNotificationPermission');
  }

  @override
  Future<List<CaptureDevice>> listDevices() async {
    final list = await methodChannel.invokeListMethod<dynamic>('listDevices');
    return (list ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(CaptureDevice.fromMap)
        .toList();
  }

  @override
  Future<CaptureStatus> getCaptureStatus() async {
    try {
      final map = await methodChannel.invokeMapMethod<dynamic, dynamic>(
        'getCaptureStatus',
      );
      return CaptureStatus.fromMap(map ?? const {});
    } on PlatformException catch (error) {
      throw CaptureError.fromCode(error.code, details: error.message);
    }
  }

  @override
  Future<void> open(String deviceId) async {
    await _invoke('open', {'deviceId': deviceId});
  }

  @override
  Future<void> close() async {
    await _invoke('close');
  }

  @override
  Future<void> setPreviewMuted(bool muted) async {
    await _invoke('setPreviewMuted', {'muted': muted});
  }

  @override
  Future<List<CaptureFormat>> listFormats() async {
    final list = await methodChannel.invokeListMethod<dynamic>('listFormats');
    return (list ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(CaptureFormat.fromMap)
        .toList();
  }

  @override
  Future<void> setFormat(String formatId) async {
    await _invoke('setFormat', {'formatId': formatId});
  }

  @override
  Future<void> setMonitorVolume(double volume) async {
    await _invoke('setMonitorVolume', {'volume': volume});
  }

  @override
  Future<void> setMonitorDelay(int delayMs) async {
    await _invoke('setMonitorDelay', {'delayMs': delayMs});
  }

  @override
  Future<List<PictureControl>> listPictureControls() async {
    final list = await methodChannel.invokeListMethod<dynamic>(
      'listPictureControls',
    );
    return (list ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(PictureControl.fromMap)
        .toList();
  }

  @override
  Future<void> setPictureControl(String id, int value) async {
    await _invoke('setPictureControl', {'id': id, 'value': value});
  }

  @override
  Future<void> resetPictureControls() async {
    await _invoke('resetPictureControls');
  }

  @override
  Future<void> takeSnapshot() async {
    await _invoke('takeSnapshot');
  }

  @override
  Future<void> setRecordingQuality(String preset) async {
    await _invoke('setRecordingQuality', {'preset': preset});
  }

  @override
  Future<void> setStreamBitrate(String preset) async {
    await _invoke('setStreamBitrate', {'preset': preset});
  }

  @override
  Future<void> startRecording({int segmentMinutes = 10}) async {
    await _invoke('startRecording', {'segmentMinutes': segmentMinutes});
  }

  @override
  Future<RecordingResult> stopRecording() async {
    final map = await _invokeMap('stopRecording');
    return RecordingResult.fromMap(map);
  }

  @override
  Future<void> startStream(String url) async {
    await _invoke('startStream', {'url': url});
  }

  @override
  Future<void> stopStream() async {
    await _invoke('stopStream');
  }

  @override
  Future<Map<String, dynamic>> startHttpServer() async {
    final map = await _invokeMap('startHttpServer');
    return Map<String, dynamic>.from(map);
  }

  @override
  Future<void> stopHttpServer() async {
    await _invoke('stopHttpServer');
  }

  @override
  Future<Map<String, dynamic>> httpServerStatus() async {
    final map = await _invokeMap('httpServerStatus');
    return Map<String, dynamic>.from(map);
  }

  @override
  Future<List<SavedRecording>> listRecordings() async {
    try {
      final list = await methodChannel.invokeListMethod<dynamic>(
        'listRecordings',
      );
      return (list ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map(SavedRecording.fromMap)
          .toList();
    } on PlatformException catch (error) {
      throw CaptureError.fromCode(error.code, details: error.message);
    }
  }

  @override
  Future<void> shareRecording(String id) async {
    await _invoke('shareRecording', {'id': id});
  }

  @override
  Future<void> openRecording(String id) async {
    await _invoke('openRecording', {'id': id});
  }

  @override
  Future<SavedRecording> renameRecording(String id, String displayName) async {
    final map = await _invokeMap('renameRecording', {
      'id': id,
      'displayName': displayName,
    });
    return SavedRecording.fromMap(map);
  }

  @override
  Future<void> deleteRecording(String id) async {
    await _invoke('deleteRecording', {'id': id});
  }

  @override
  Future<SavedRecording> concatSession({
    required String sessionStamp,
    required List<String> uris,
    required String displayName,
  }) async {
    final map = await _invokeMap('concatSession', {
      'sessionStamp': sessionStamp,
      'uris': uris,
      'displayName': displayName,
    });
    return SavedRecording.fromMap(map);
  }

  @override
  Future<void> openBatterySettings() async {
    await _invoke('openBatterySettings');
  }

  @override
  Future<void> setSaveLocation({required String kind, String? uri}) async {
    await _invoke('setSaveLocation', {'kind': kind, 'uri': uri});
  }

  @override
  Future<SaveLocation?> pickSaveFolder() async {
    try {
      final map = await methodChannel.invokeMapMethod<dynamic, dynamic>(
        'pickSaveFolder',
      );
      if (map == null || map.isEmpty) {
        return null;
      }
      return SaveLocation.fromMap(map);
    } on PlatformException catch (error) {
      throw CaptureError.fromCode(error.code, details: error.message);
    }
  }

  @override
  Future<void> setUiLocale(String tag) async {
    await _invoke('setUiLocale', {'tag': tag});
  }

  @override
  Stream<CaptureEvent> events() {
    return eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return CaptureEvent.fromMap(event);
      }
      return const CaptureEvent(type: CaptureEventType.error);
    });
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      await methodChannel.invokeMethod<void>(method, args);
    } on PlatformException catch (error) {
      throw CaptureError.fromCode(error.code, details: error.message);
    }
  }

  Future<Map<dynamic, dynamic>> _invokeMap(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    try {
      return await methodChannel.invokeMapMethod<dynamic, dynamic>(
            method,
            args,
          ) ??
          const {};
    } on PlatformException catch (error) {
      throw CaptureError.fromCode(error.code, details: error.message);
    }
  }
}
