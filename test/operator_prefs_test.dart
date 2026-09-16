import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_studio/locale_mode.dart';
import 'package:usb_studio/operator_prefs.dart';

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

  test('localeMode defaults to system when unset', () async {
    final loaded = await OperatorPrefs.load();
    expect(loaded.localeMode, LocaleMode.system);
  });

  test('localeMode override roundtrips through SharedPreferences', () async {
    await const OperatorPrefs(localeMode: LocaleMode.zhHant).save();
    final loaded = await OperatorPrefs.load();
    expect(loaded.localeMode, LocaleMode.zhHant);
  });

  test('invalid localeMode falls back to English', () async {
    SharedPreferences.setMockInitialValues({'operator.localeMode': 'nope'});
    final loaded = await OperatorPrefs.load();
    expect(loaded.localeMode, LocaleMode.en);
    expect(
      loaded.localeMode.resolve(const Locale('zh', 'CN')),
      const Locale('en'),
    );
  });
}
