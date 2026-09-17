// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'USB Studio';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システムに従う';

  @override
  String get languageZhHans => '简体中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get settingsTitle => 'キャプチャ設定';

  @override
  String get close => '閉じる';

  @override
  String get sectionRecord => '録画';

  @override
  String get sectionPreview => 'プレビュー';

  @override
  String get sectionPicture => '画質';

  @override
  String get sectionStream => '配信';

  @override
  String get sectionLan => 'LAN再生';

  @override
  String get sectionAbout => '情報';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String appVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String aboutDeveloper(String name) {
    return '開発者  $name';
  }

  @override
  String get permissionDisclosureTitle => 'カメラとマイク';

  @override
  String get permissionDisclosureBody =>
      'USB Studio は USB キャプチャカードの映像と音声のためにカメラとマイクの権限を使います。この端末のインカメラでは撮影しません。';

  @override
  String get permissionDisclosureContinue => '続ける';

  @override
  String get permissionDisclosureNotNow => '後で';

  @override
  String get recordSegment => '録画分割';

  @override
  String get recordQuality => '録画画質';

  @override
  String get saveLocation => '保存先';

  @override
  String get changeFolder => 'フォルダ変更';

  @override
  String get autoRecord => '接続後に自動録画';

  @override
  String get previewEnabled => 'プレビューを表示';

  @override
  String get previewSound => 'プレビュー音声';

  @override
  String monitorVolume(int percent) {
    return 'モニター音量  $percent%';
  }

  @override
  String get monitorDelay => 'モニター遅延';

  @override
  String get videoFormat => '映像フォーマット';

  @override
  String get resetPicture => '初期化';

  @override
  String get streamUrl => '配信URL';

  @override
  String get streamKey => '配信キー（任意）';

  @override
  String get streamKeyHint => '完全なURLを上に貼っても可';

  @override
  String get lanPlayback => 'LAN再生';

  @override
  String get copyUrl => 'コピー';

  @override
  String get lanDisclosure => '同じWi-FiのHTTPで再生できます。暗号化なし。';

  @override
  String get connectWifi => '先にWi-Fiへ接続';

  @override
  String get snapshot => '静止画';

  @override
  String get settings => '設定';

  @override
  String get library => 'ライブラリ';

  @override
  String get startRecord => '録画';

  @override
  String get stopRecord => '停止';

  @override
  String get startStream => '配信';

  @override
  String get stopStream => '終了';

  @override
  String get mutePreview => '消音';

  @override
  String get unmutePreview => '解除';

  @override
  String get fullscreen => '全画面';

  @override
  String get insertCaptureCard => 'USBキャプチャを接続';

  @override
  String devicesFound(int count) {
    return '$count台のキャプチャを検出';
  }

  @override
  String get snapshotSaved => '静止画を保存しました';

  @override
  String segmentStatus(int index) {
    return '第$index本';
  }

  @override
  String get previewOffCanRecord => 'プレビューOFFでも録画できます';

  @override
  String get noSignal => '信号なし';

  @override
  String get waitingSignal => '信号待ち';

  @override
  String get segmentOff => 'オフ';

  @override
  String segmentMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get qualityTiny => '最小（約15MB/分）';

  @override
  String get qualitySmall => '節約（約30MB/分）';

  @override
  String get qualityStandard => '標準（約60MB/分）';

  @override
  String get qualityHigh => '高ビットレート（約120MB/分）';

  @override
  String get saveGallery => 'ギャラリー';

  @override
  String get saveMovies => '動画';

  @override
  String get saveDownloads => 'ダウンロード';

  @override
  String get saveCustom => 'カスタム';

  @override
  String get savedGallery => 'ギャラリーに保存';

  @override
  String get savedMovies => '動画フォルダに保存';

  @override
  String get savedDownloads => 'ダウンロードに保存';

  @override
  String get savedCustom => 'カスタムに保存';

  @override
  String get pictureBrightness => '明るさ';

  @override
  String get pictureContrast => 'コントラスト';

  @override
  String get pictureSaturation => '彩度';

  @override
  String get pictureHue => '色相';

  @override
  String recOnly(String time) {
    return 'REC  $time';
  }

  @override
  String recSegment(String time, int index) {
    return 'REC  $time  第$index本';
  }

  @override
  String get cardRemoved => 'キャプチャを取り外しました';

  @override
  String get cardRemovedSavedMovies => 'キャプチャを取り外しました。動画フォルダに保存済み';

  @override
  String get cardRemovedSaved => 'キャプチャを取り外しました。録画を保存済み';

  @override
  String get recordInterruptedMovies => '録画が中断されました。動画フォルダに保存済み';

  @override
  String get recordInterruptedSaved => '録画が中断されました。録画を保存済み';

  @override
  String get recordFailed => '録画に失敗しました。';

  @override
  String get libraryEmpty => '録画はまだありません。キャプチャ後にここに表示されます。';

  @override
  String get deleteTitle => 'この録画を削除しますか？';

  @override
  String get deleteConfirm => 'このアプリからは復元できません。';

  @override
  String get deleteAction => '削除';

  @override
  String get cancelAction => 'キャンセル';

  @override
  String get shareAction => '共有';

  @override
  String get shareFailed => '共有先がありません。';

  @override
  String get shareUnavailable => 'この端末では共有できません。';

  @override
  String get mergeAction => 'セッション結合';

  @override
  String get mergeProgress => '結合しています…';

  @override
  String get renameAction => '名前変更';

  @override
  String get renameTitle => '録画の名前変更';

  @override
  String get confirmAction => 'OK';

  @override
  String get batteryTitle => 'バックグラウンド録画を許可';

  @override
  String get batteryBody =>
      'ロックやバックグラウンドでシステムがキャプチャを止めることがあります。電池最適化から除外してください。';

  @override
  String get batteryOpenSettings => '設定を開く';

  @override
  String get batteryLater => '後で';

  @override
  String get errorPermission => 'キャプチャにはカメラ、マイク、USBの権限が必要です。';

  @override
  String get errorUsbHost => 'この端末はUSBホスト非対応のため、キャプチャカードを使えません。';

  @override
  String get errorUnsupportedPlatform =>
      'USBキャプチャはAndroidのスマホ、タブレット、テレビのみ対応です。';

  @override
  String get errorUvcFailed => 'キャプチャを開けません。UVC機器か確認してください。';

  @override
  String get errorPowerIssue =>
      'キャプチャを開けません。給電不足の可能性があります。バスパワーのUSBハブを試してください。';

  @override
  String get errorDisconnected => 'キャプチャを取り外しました。';

  @override
  String get errorNoAudio => 'キャプチャから使える音声がありません。';

  @override
  String get errorRecordingInProgress => '録画中はフォーマットや画質を変更できません。';

  @override
  String get errorSessionRecording => 'このセッションは録画中です。停止してから結合してください。';

  @override
  String get errorConcatUnsupported => 'この環境では録画の結合に対応していません。';

  @override
  String get errorConcatStorage => '空き容量が足りず結合できません。';

  @override
  String get errorConcatFailed => '結合に失敗しました。元の分割は変更していません。';

  @override
  String get errorPreviewOff => '先にプレビューをオンにしてください。';

  @override
  String get errorNoPreview => '先にキャプチャを接続してください。';

  @override
  String get errorStreamUnsupported => 'この環境では配信に対応していません。';

  @override
  String get errorStreamInProgress => '配信中はフォーマットや画質を変更できません。';

  @override
  String get errorMissingUrl => '先に配信URLを入力してください。';

  @override
  String get errorNoSignalStream => '信号なしのため配信を停止しました。';

  @override
  String get errorConnectFailed => '配信サーバーに接続できません。';

  @override
  String get errorHttpUnsupported => 'この環境ではLAN再生に対応していません。';

  @override
  String get errorHttpBindFailed => 'LAN再生のポートを開けません。';

  @override
  String get errorHttpNoNetwork => '先にWi-Fiへ接続してください。';

  @override
  String get errorHttpLiveFailed => 'ライブエンコードを開始できませんでした。保存済み録画は再生できます。';

  @override
  String get errorStreamFailed => '配信に失敗しました。';

  @override
  String get errorPlayFailed => 'システムプレーヤーで開けません。';

  @override
  String get errorRenameTaken => '同じ名前の録画があります。別の名前にしてください。';

  @override
  String get errorRenameInvalid => '名前が無効です。スラッシュなどの記号を除いてください。';

  @override
  String get errorRenameUnsupported => 'この環境では名前変更に対応していません。';

  @override
  String get errorRenameFailed => '名前変更に失敗しました。元のファイルは変更していません。';

  @override
  String get errorUnknown => '不明なエラーが発生しました。';
}
