import 'package:flutter_test/flutter_test.dart';
import 'package:usb_capture/usb_capture.dart';

void main() {
  test('app recording state machine matches plugin', () {
    expect(
      () => const SessionState().startRecording(),
      throwsA(isA<StateError>()),
    );
    final active = const SessionState(sessionOpen: true).startRecording();
    expect(active.isRecording, isTrue);
    expect(active.stopRecording().isRecording, isFalse);
  });
}
