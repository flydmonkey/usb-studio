import 'package:flutter/material.dart';

enum LocaleMode {
  system,
  zhHans,
  zhHant,
  ja,
  ko,
  en;

  static const storageSystem = 'system';
  static const storageZhHans = 'zh-Hans';
  static const storageZhHant = 'zh-Hant';
  static const storageJa = 'ja';
  static const storageKo = 'ko';
  static const storageEn = 'en';

  String get storageKey {
    switch (this) {
      case LocaleMode.system:
        return storageSystem;
      case LocaleMode.zhHans:
        return storageZhHans;
      case LocaleMode.zhHant:
        return storageZhHant;
      case LocaleMode.ja:
        return storageJa;
      case LocaleMode.ko:
        return storageKo;
      case LocaleMode.en:
        return storageEn;
    }
  }

  static const zhHansLocale = Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hans',
  );
  static const zhHantLocale = Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
  );
  static const jaLocale = Locale('ja');
  static const koLocale = Locale('ko');
  static const enLocale = Locale('en');

  static const supportedLocales = <Locale>[
    zhHansLocale,
    zhHantLocale,
    jaLocale,
    koLocale,
    enLocale,
  ];

  static LocaleMode fromStored(String? raw) {
    switch (raw) {
      case null:
        return LocaleMode.system;
      case storageSystem:
        return LocaleMode.system;
      case storageZhHans:
        return LocaleMode.zhHans;
      case storageZhHant:
        return LocaleMode.zhHant;
      case storageJa:
        return LocaleMode.ja;
      case storageKo:
        return LocaleMode.ko;
      case storageEn:
        return LocaleMode.en;
      default:
        return LocaleMode.en;
    }
  }

  Locale resolve([Locale? device]) {
    switch (this) {
      case LocaleMode.zhHans:
        return zhHansLocale;
      case LocaleMode.zhHant:
        return zhHantLocale;
      case LocaleMode.ja:
        return jaLocale;
      case LocaleMode.ko:
        return koLocale;
      case LocaleMode.en:
        return enLocale;
      case LocaleMode.system:
        return mapDevice(device ?? enLocale);
    }
  }

  String toBcp47([Locale? device]) => resolve(device).toLanguageTag();

  static Locale mapDevice(Locale device) {
    final language = device.languageCode.toLowerCase();
    if (language == 'ja') {
      return jaLocale;
    }
    if (language == 'ko') {
      return koLocale;
    }
    if (language == 'en') {
      return enLocale;
    }
    if (language != 'zh') {
      return enLocale;
    }
    final script = device.scriptCode?.toLowerCase();
    final region = device.countryCode?.toUpperCase();
    if (script == 'hant' ||
        region == 'TW' ||
        region == 'HK' ||
        region == 'MO') {
      return zhHantLocale;
    }
    if (script == 'hans' || region == 'CN' || region == 'SG') {
      return zhHansLocale;
    }
    return enLocale;
  }
}
