import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usb_studio/locale_mode.dart';

void main() {
  group('LocaleMode.fromStored', () {
    test('missing value means follow system', () {
      expect(LocaleMode.fromStored(null), LocaleMode.system);
    });

    test('parses supported overrides', () {
      expect(LocaleMode.fromStored('system'), LocaleMode.system);
      expect(LocaleMode.fromStored('zh-Hans'), LocaleMode.zhHans);
      expect(LocaleMode.fromStored('zh-Hant'), LocaleMode.zhHant);
      expect(LocaleMode.fromStored('ja'), LocaleMode.ja);
      expect(LocaleMode.fromStored('ko'), LocaleMode.ko);
      expect(LocaleMode.fromStored('en'), LocaleMode.en);
    });

    test('unmatched stored value falls back to English', () {
      expect(LocaleMode.fromStored('fr'), LocaleMode.en);
      expect(LocaleMode.fromStored(''), LocaleMode.en);
      expect(LocaleMode.fromStored('zh'), LocaleMode.en);
    });
  });

  group('LocaleMode.resolve', () {
    test('maps simplified system locales', () {
      expect(
        LocaleMode.system.resolve(const Locale('zh', 'CN')).toLanguageTag(),
        'zh-Hans',
      );
      expect(
        LocaleMode.system.resolve(const Locale('zh', 'SG')).toLanguageTag(),
        'zh-Hans',
      );
      expect(
        LocaleMode.system
            .resolve(
              const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
            )
            .toLanguageTag(),
        'zh-Hans',
      );
    });

    test('maps traditional system locales', () {
      expect(
        LocaleMode.system.resolve(const Locale('zh', 'TW')).toLanguageTag(),
        'zh-Hant',
      );
      expect(
        LocaleMode.system.resolve(const Locale('zh', 'HK')).toLanguageTag(),
        'zh-Hant',
      );
      expect(
        LocaleMode.system.resolve(const Locale('zh', 'MO')).toLanguageTag(),
        'zh-Hant',
      );
      expect(
        LocaleMode.system
            .resolve(
              const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
            )
            .toLanguageTag(),
        'zh-Hant',
      );
    });

    test('maps Japanese and Korean system locales', () {
      expect(
        LocaleMode.system.resolve(const Locale('ja', 'JP')),
        const Locale('ja'),
      );
      expect(
        LocaleMode.system.resolve(const Locale('ko', 'KR')),
        const Locale('ko'),
      );
    });

    test('unmatched system locale falls back to English', () {
      expect(
        LocaleMode.system.resolve(const Locale('fr', 'FR')),
        const Locale('en'),
      );
      expect(
        LocaleMode.system.resolve(const Locale('th')),
        const Locale('en'),
      );
    });

    test('manual override ignores device locale', () {
      expect(
        LocaleMode.en.resolve(const Locale('zh', 'CN')),
        const Locale('en'),
      );
      expect(
        LocaleMode.ja.resolve(const Locale('zh', 'CN')),
        const Locale('ja'),
      );
      expect(
        LocaleMode.zhHant.resolve(const Locale('en', 'US')).toLanguageTag(),
        'zh-Hant',
      );
    });
  });
}
