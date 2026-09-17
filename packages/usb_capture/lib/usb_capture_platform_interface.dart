import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/capture_device.dart';
import 'src/capture_event.dart';
import 'src/capture_format.dart';
import 'src/capture_status.dart';
import 'src/picture_control.dart';
import 'src/platform_profile.dart';
import 'src/recording_result.dart';
import 'src/save_location.dart';
import 'src/saved_recording.dart';
import 'usb_capture_method_channel.dart';

abstract class UsbCapturePlatform extends PlatformInterface {
  UsbCapturePlatform() : super(token: _token);

  static final Object _token = Object();

  static UsbCapturePlatform _instance = MethodChannelUsbCapture();

  static UsbCapturePlatform get instance => _instance;

  static set instance(UsbCapturePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<PlatformProfile> getPlatformProfile() {
    throw UnimplementedError('getPlatformProfile() has not been implemented.');
  }

  Future<void> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  Future<bool> hasCapturePermissions() {
    throw UnimplementedError(
      'hasCapturePermissions() has not been implemented.',
    );
  }

  Future<void> requestNotificationPermission() {
    throw UnimplementedError(
      'requestNotificationPermission() has not been implemented.',
    );
  }

  Future<List<CaptureDevice>> listDevices() {
    throw UnimplementedError('listDevices() has not been implemented.');
  }

  Future<CaptureStatus> getCaptureStatus() {
    throw UnimplementedError('getCaptureStatus() has not been implemented.');
  }

  Future<void> open(String deviceId) {
    throw UnimplementedError('open() has not been implemented.');
  }

  Future<void> close() {
    throw UnimplementedError('close() has not been implemented.');
  }

  Future<void> setPreviewMuted(bool muted) {
    throw UnimplementedError('setPreviewMuted() has not been implemented.');
  }

  Future<List<CaptureFormat>> listFormats() {
    throw UnimplementedError('listFormats() has not been implemented.');
  }

  Future<void> setFormat(String formatId) {
    throw UnimplementedError('setFormat() has not been implemented.');
  }

  Future<void> setMonitorVolume(double volume) {
    throw UnimplementedError('setMonitorVolume() has not been implemented.');
  }

  Future<void> setMonitorDelay(int delayMs) {
    throw UnimplementedError('setMonitorDelay() has not been implemented.');
  }

  Future<List<PictureControl>> listPictureControls() {
    throw UnimplementedError('listPictureControls() has not been implemented.');
  }

  Future<void> setPictureControl(String id, int value) {
    throw UnimplementedError('setPictureControl() has not been implemented.');
  }

  Future<void> resetPictureControls() {
    throw UnimplementedError(
      'resetPictureControls() has not been implemented.',
    );
  }

  Future<void> takeSnapshot() {
    throw UnimplementedError('takeSnapshot() has not been implemented.');
  }

  Future<void> setRecordingQuality(String preset) {
    throw UnimplementedError('setRecordingQuality() has not been implemented.');
  }

  Future<void> setStreamBitrate(String preset) {
    throw UnimplementedError('setStreamBitrate() has not been implemented.');
  }

  Future<void> startRecording({int segmentMinutes = 10}) {
    throw UnimplementedError('startRecording() has not been implemented.');
  }

  Future<RecordingResult> stopRecording() {
    throw UnimplementedError('stopRecording() has not been implemented.');
  }

  Future<void> startStream(String url) {
    throw UnimplementedError('startStream() has not been implemented.');
  }

  Future<void> stopStream() {
    throw UnimplementedError('stopStream() has not been implemented.');
  }

  Future<Map<String, dynamic>> startHttpServer() {
    throw UnimplementedError('startHttpServer() has not been implemented.');
  }

  Future<void> stopHttpServer() {
    throw UnimplementedError('stopHttpServer() has not been implemented.');
  }

  Future<Map<String, dynamic>> httpServerStatus() {
    throw UnimplementedError('httpServerStatus() has not been implemented.');
  }

  Future<List<SavedRecording>> listRecordings() {
    throw UnimplementedError('listRecordings() has not been implemented.');
  }

  Future<void> shareRecording(String id) {
    throw UnimplementedError('shareRecording() has not been implemented.');
  }

  Future<void> openRecording(String id) {
    throw UnimplementedError('openRecording() has not been implemented.');
  }

  Future<SavedRecording> renameRecording(String id, String displayName) {
    throw UnimplementedError('renameRecording() has not been implemented.');
  }

  Future<void> deleteRecording(String id) {
    throw UnimplementedError('deleteRecording() has not been implemented.');
  }

  Future<SavedRecording> concatSession({
    required String sessionStamp,
    required List<String> uris,
    required String displayName,
  }) {
    throw UnimplementedError('concatSession() has not been implemented.');
  }

  Future<void> openBatterySettings() {
    throw UnimplementedError('openBatterySettings() has not been implemented.');
  }

  Future<void> setSaveLocation({required String kind, String? uri}) {
    throw UnimplementedError('setSaveLocation() has not been implemented.');
  }

  Future<void> setUiLocale(String tag) {
    throw UnimplementedError('setUiLocale() has not been implemented.');
  }

  Future<SaveLocation?> pickSaveFolder() {
    throw UnimplementedError('pickSaveFolder() has not been implemented.');
  }

  Stream<CaptureEvent> events() {
    throw UnimplementedError('events() has not been implemented.');
  }
}
