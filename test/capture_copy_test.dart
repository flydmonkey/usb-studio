import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usb_capture/usb_capture.dart';
import 'package:usb_studio/capture_copy.dart';
import 'package:usb_studio/l10n/app_localizations.dart';

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('library copy comes from AppLocalizations', () {
    expect(zh.libraryEmpty, contains('还没有录像'));
    expect(zh.deleteTitle, contains('删除'));
    expect(zh.deleteConfirm, contains('无法从本应用恢复'));
    expect(zh.mergeAction, '合并本场');
    expect(en.libraryEmpty, isNot(contains('还没有录像')));
    expect(en.mergeAction, 'Merge session');
  });

  test('errors localize from codes, not CaptureError.message', () {
    expect(
      localizeCaptureError(zh, CaptureError.fromCode('usbHostMissing')),
      contains('USB Host'),
    );
    expect(
      localizeCaptureError(
        zh,
        const CaptureError(
          CaptureErrorCode.recordingFailed,
          details: 'sessionRecording',
        ),
      ),
      contains('停录后再合并'),
    );
    expect(
      localizeCaptureError(
        zh,
        CaptureError.fromCode('streamFailed', details: 'httpNoNetwork'),
      ),
      contains('Wi-Fi'),
    );
    expect(
      localizeCaptureError(
        zh,
        CaptureError.fromCode('streamFailed', details: 'httpLiveFailed'),
      ),
      contains('已录成片'),
    );
    expect(
      localizeCaptureError(
        zh,
        CaptureError.fromCode('streamFailed', details: 'Error 0xfffffff4'),
      ),
      contains('已录成片'),
    );
    expect(
      localizeCaptureError(
        en,
        CaptureError.fromCode('streamFailed', details: 'missingUrl'),
      ),
      contains('stream URL'),
    );
  });

  test('waiting-signal HUD uses l10n, dimensions stay machine-readable', () {
    expect(signalHudLabel(zh, const SignalStatus()), zh.waitingSignal);
    expect(
      signalHudLabel(
        en,
        const SignalStatus(width: 1920, height: 1080, fps: 30),
      ),
      '1920×1080 30fps',
    );
  });
}
