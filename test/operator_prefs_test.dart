import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_camera_capture/operator_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('httpLanEnabled roundtrips through SharedPreferences', () async {
    final saved = await const OperatorPrefs(httpLanEnabled: true).save();
    expect(saved.httpLanEnabled, isTrue);

    final loaded = await OperatorPrefs.load();
    expect(loaded.httpLanEnabled, isTrue);
  });
}
