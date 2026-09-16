import 'package:flutter_test/flutter_test.dart';
import 'package:usb_capture/usb_capture.dart';

void main() {
  testWidgets('getPlatformProfile', (tester) async {
    final plugin = UsbCapture();
    expect(plugin.getPlatformProfile, isA<Function>());
  });
}
