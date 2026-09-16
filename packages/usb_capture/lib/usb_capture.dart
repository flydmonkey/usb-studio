import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/capture_device.dart';
import 'src/capture_event.dart';
import 'src/capture_format.dart';
import 'src/capture_status.dart';
import 'src/picture_control.dart';
import 'src/platform_profile.dart';
import 'src/recording_result.dart';
import 'src/save_location.dart';
import 'src/saved_recording.dart';
import 'usb_capture_platform_interface.dart';

export 'src/capture_device.dart';
export 'src/capture_error.dart';
export 'src/capture_event.dart';
export 'src/capture_format.dart';
export 'src/capture_status.dart';
export 'src/picture_control.dart';
export 'src/platform_profile.dart';
export 'src/library_copy.dart';
export 'src/library_name.dart';
export 'src/recording_result.dart';
export 'src/saved_recording.dart';
export 'src/save_location.dart';
export 'src/segment_policy.dart';
export 'src/session_state.dart';
export 'src/signal_status.dart';
export 'src/lan_http_url.dart';
export 'src/stream_url.dart';

const usbCapturePreviewViewType = 'usb_capture/preview';

class UsbCapture {
  Future<PlatformProfile> getPlatformProfile() {
    return UsbCapturePlatform.instance.getPlatformProfile();
  }

  Future<void> requestPermissions() {
    return UsbCapturePlatform.instance.requestPermissions();
  }

  Future<List<CaptureDevice>> listDevices() {
    return UsbCapturePlatform.instance.listDevices();
  }

  Future<CaptureStatus> getCaptureStatus() {
    return UsbCapturePlatform.instance.getCaptureStatus();
  }

  Future<void> open(String deviceId) {
    return UsbCapturePlatform.instance.open(deviceId);
  }

  Future<void> close() {
    return UsbCapturePlatform.instance.close();
  }

  Future<void> setPreviewMuted(bool muted) {
    return UsbCapturePlatform.instance.setPreviewMuted(muted);
  }

  Future<List<CaptureFormat>> listFormats() {
    return UsbCapturePlatform.instance.listFormats();
  }

  Future<void> setFormat(String formatId) {
    return UsbCapturePlatform.instance.setFormat(formatId);
  }

  Future<void> setMonitorVolume(double volume) {
    return UsbCapturePlatform.instance.setMonitorVolume(volume);
  }

  Future<void> setMonitorDelay(int delayMs) {
    return UsbCapturePlatform.instance.setMonitorDelay(delayMs);
  }

  Future<List<PictureControl>> listPictureControls() {
    return UsbCapturePlatform.instance.listPictureControls();
  }

  Future<void> setPictureControl(String id, int value) {
    return UsbCapturePlatform.instance.setPictureControl(id, value);
  }

  Future<void> resetPictureControls() {
    return UsbCapturePlatform.instance.resetPictureControls();
  }

  Future<void> takeSnapshot() {
    return UsbCapturePlatform.instance.takeSnapshot();
  }

  Future<void> setRecordingQuality(String preset) {
    return UsbCapturePlatform.instance.setRecordingQuality(preset);
  }

  Future<void> startRecording({int segmentMinutes = 10}) {
    return UsbCapturePlatform.instance.startRecording(
      segmentMinutes: segmentMinutes,
    );
  }

  Future<RecordingResult> stopRecording() {
    return UsbCapturePlatform.instance.stopRecording();
  }

  Future<void> startStream(String url) {
    return UsbCapturePlatform.instance.startStream(url);
  }

  Future<void> stopStream() {
    return UsbCapturePlatform.instance.stopStream();
  }

  Future<Map<String, dynamic>> startHttpServer() {
    return UsbCapturePlatform.instance.startHttpServer();
  }

  Future<void> stopHttpServer() {
    return UsbCapturePlatform.instance.stopHttpServer();
  }

  Future<Map<String, dynamic>> httpServerStatus() {
    return UsbCapturePlatform.instance.httpServerStatus();
  }

  Future<List<SavedRecording>> listRecordings() {
    return UsbCapturePlatform.instance.listRecordings();
  }

  Future<void> shareRecording(String id) {
    return UsbCapturePlatform.instance.shareRecording(id);
  }

  Future<void> openRecording(String id) {
    return UsbCapturePlatform.instance.openRecording(id);
  }

  Future<SavedRecording> renameRecording(String id, String displayName) {
    return UsbCapturePlatform.instance.renameRecording(id, displayName);
  }

  Future<void> deleteRecording(String id) {
    return UsbCapturePlatform.instance.deleteRecording(id);
  }

  Future<SavedRecording> concatSession({
    required String sessionStamp,
    required List<String> uris,
    required String displayName,
  }) {
    return UsbCapturePlatform.instance.concatSession(
      sessionStamp: sessionStamp,
      uris: uris,
      displayName: displayName,
    );
  }

  Future<void> openBatterySettings() {
    return UsbCapturePlatform.instance.openBatterySettings();
  }

  Future<void> setSaveLocation({required String kind, String? uri}) {
    return UsbCapturePlatform.instance.setSaveLocation(kind: kind, uri: uri);
  }

  Future<SaveLocation?> pickSaveFolder() {
    return UsbCapturePlatform.instance.pickSaveFolder();
  }

  Future<void> setUiLocale(String tag) {
    return UsbCapturePlatform.instance.setUiLocale(tag);
  }

  Stream<CaptureEvent> events() {
    return UsbCapturePlatform.instance.events();
  }
}

/// Native preview surface. Not focusable so TV D-pad stays on overlay controls.
class UsbCapturePreview extends StatelessWidget {
  const UsbCapturePreview({super.key});

  @override
  Widget build(BuildContext context) {
    const creationParams = <String, dynamic>{};
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const AndroidView(
          viewType: usbCapturePreviewViewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: StandardMessageCodec(),
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
        );
      default:
        return const SizedBox.expand();
    }
  }
}
