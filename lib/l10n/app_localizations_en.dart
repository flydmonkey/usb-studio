// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'USB Studio';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZhHans => 'Simplified';

  @override
  String get languageZhHant => 'Traditional';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get close => 'Close';

  @override
  String get sectionRecord => 'Recording';

  @override
  String get sectionPreview => 'Preview';

  @override
  String get sectionPicture => 'Picture';

  @override
  String get sectionStream => 'Streaming';

  @override
  String get sectionLan => 'LAN playback';

  @override
  String get sectionAbout => 'About';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String aboutDeveloper(String name) {
    return 'Developer  $name';
  }

  @override
  String get permissionDisclosureTitle => 'Camera and microphone';

  @override
  String get permissionDisclosureBody =>
      'USB Studio uses camera and microphone permission for USB capture-card video and audio. It does not use this device\'s built-in selfie camera.';

  @override
  String get permissionDisclosureContinue => 'Continue';

  @override
  String get permissionDisclosureNotNow => 'Not now';

  @override
  String get recordSegment => 'Segments';

  @override
  String get recordQuality => 'Quality';

  @override
  String get saveLocation => 'Save to';

  @override
  String get changeFolder => 'Folder';

  @override
  String get autoRecord => 'Auto-record';

  @override
  String get previewEnabled => 'Preview';

  @override
  String get previewSound => 'Sound';

  @override
  String monitorVolume(int percent) {
    return 'Volume  $percent%';
  }

  @override
  String get monitorDelay => 'Delay';

  @override
  String get videoFormat => 'Format';

  @override
  String get resetPicture => 'Reset';

  @override
  String get streamUrl => 'URL';

  @override
  String get streamKey => 'Key';

  @override
  String get streamKeyHint => 'Or paste full URL';

  @override
  String get streamBitrate => 'Bitrate';

  @override
  String get streamMbps1 => '1 Mbps';

  @override
  String get streamMbps2 => '2 Mbps';

  @override
  String get streamMbps4 => '4 Mbps';

  @override
  String get streamMbps6 => '6 Mbps';

  @override
  String get lanPlayback => 'LAN playback';

  @override
  String get copyUrl => 'Copy';

  @override
  String get lanDisclosure =>
      'Anyone on the same Wi-Fi can open this address to watch; not encrypted.';

  @override
  String get connectWifi => 'Connect to Wi-Fi first';

  @override
  String get snapshot => 'Snapshot';

  @override
  String get settings => 'Settings';

  @override
  String get library => 'Library';

  @override
  String get startRecord => 'Record';

  @override
  String get stopRecord => 'Stop';

  @override
  String get startStream => 'Stream';

  @override
  String get stopStream => 'End';

  @override
  String get mutePreview => 'Mute';

  @override
  String get unmutePreview => 'Unmute';

  @override
  String get fullscreen => 'Full';

  @override
  String get insertCaptureCard => 'Insert USB capture';

  @override
  String devicesFound(int count) {
    return 'Found $count capture devices';
  }

  @override
  String get snapshotSaved => 'Snapshot saved';

  @override
  String segmentStatus(int index) {
    return 'Segment $index';
  }

  @override
  String get previewOffCanRecord => 'Preview is off; recording still works';

  @override
  String get previewLanLiveBusy => 'Webpage is watching live preview';

  @override
  String get noSignal => 'No signal';

  @override
  String get waitingSignal => 'Waiting for signal';

  @override
  String get segmentOff => 'Off';

  @override
  String segmentMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get qualityTiny => 'Smaller (~15 MB/min)';

  @override
  String get qualitySmall => 'Save space (~30 MB/min)';

  @override
  String get qualityStandard => 'Standard (~60 MB/min)';

  @override
  String get qualityHigh => 'High bitrate (~120 MB/min)';

  @override
  String get saveGallery => 'Gallery';

  @override
  String get saveMovies => 'Movies';

  @override
  String get saveDownloads => 'Downloads';

  @override
  String get saveCustom => 'Custom';

  @override
  String get savedGallery => 'Saved to gallery';

  @override
  String get savedMovies => 'Saved to Movies';

  @override
  String get savedDownloads => 'Saved to Downloads';

  @override
  String get savedCustom => 'Saved to custom folder';

  @override
  String get pictureBrightness => 'Brightness';

  @override
  String get pictureContrast => 'Contrast';

  @override
  String get pictureSaturation => 'Saturation';

  @override
  String get pictureHue => 'Hue';

  @override
  String recOnly(String time) {
    return 'REC  $time';
  }

  @override
  String recSegment(String time, int index) {
    return 'REC  $time  Seg $index';
  }

  @override
  String get cardRemoved => 'Capture card removed';

  @override
  String get cardRemovedSavedMovies => 'Capture card removed; saved to Movies';

  @override
  String get cardRemovedSaved => 'Capture card removed; recording saved';

  @override
  String get recordInterruptedMovies =>
      'Recording interrupted; saved to Movies';

  @override
  String get recordInterruptedSaved => 'Recording interrupted; recording saved';

  @override
  String get recordFailed => 'Recording failed.';

  @override
  String get libraryEmpty =>
      'No recordings yet. They appear here after a capture is saved.';

  @override
  String get deleteTitle => 'Delete this recording?';

  @override
  String get deleteConfirm => 'It cannot be restored from this app.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get shareAction => 'Share';

  @override
  String get shareFailed => 'No share targets available.';

  @override
  String get shareUnavailable => 'This device cannot share that file.';

  @override
  String get mergeAction => 'Merge session';

  @override
  String get mergeProgress => 'Merging session…';

  @override
  String get renameAction => 'Rename';

  @override
  String get renameTitle => 'Rename recording';

  @override
  String get confirmAction => 'OK';

  @override
  String get batteryTitle => 'Allow recording in the background';

  @override
  String get batteryBody =>
      'The system may pause capture after lock or when the app is in the background. Ignore battery optimizations for this app so recording can continue.';

  @override
  String get batteryOpenSettings => 'Open settings';

  @override
  String get batteryLater => 'Not now';

  @override
  String get errorPermission =>
      'Camera, microphone, or USB permission is required to capture.';

  @override
  String get errorUsbHost =>
      'This device does not support USB Host, so a capture card cannot be used.';

  @override
  String get errorUnsupportedPlatform =>
      'USB capture is only supported on Android phones, tablets, and TVs.';

  @override
  String get errorUvcFailed =>
      'Could not open the capture card. Confirm it is a UVC device.';

  @override
  String get errorPowerIssue =>
      'Could not open the capture card; power may be insufficient. Try a powered USB hub.';

  @override
  String get errorDisconnected => 'Capture card removed.';

  @override
  String get errorNoAudio => 'The capture card did not provide usable audio.';

  @override
  String get errorRecordingInProgress =>
      'Recording is in progress; format or quality cannot be changed.';

  @override
  String get errorSessionRecording =>
      'This session is still recording. Stop it before merging.';

  @override
  String get errorConcatUnsupported =>
      'Merging recordings is not supported on this platform.';

  @override
  String get errorConcatStorage => 'Not enough storage to merge.';

  @override
  String get errorConcatFailed =>
      'Merge failed; original segments were not changed.';

  @override
  String get errorPreviewOff => 'Turn preview on first.';

  @override
  String get errorNoPreview => 'Connect a capture card first.';

  @override
  String get errorStreamUnsupported =>
      'Streaming is not supported on this platform.';

  @override
  String get errorStreamInProgress =>
      'Streaming is in progress; format or quality cannot be changed.';

  @override
  String get errorMissingUrl => 'Enter a stream URL first.';

  @override
  String get errorNoSignalStream => 'No signal; streaming stopped.';

  @override
  String get errorConnectFailed => 'Could not reach the stream server.';

  @override
  String get errorHttpUnsupported =>
      'LAN playback is not supported on this platform.';

  @override
  String get errorHttpBindFailed => 'Could not open the LAN playback port.';

  @override
  String get errorHttpNoNetwork => 'Connect to Wi-Fi first.';

  @override
  String get errorHttpLiveFailed =>
      'Live encoding did not start; saved recordings can still play.';

  @override
  String get errorStreamFailed => 'Streaming failed.';

  @override
  String get errorPlayFailed => 'Could not open with the system player.';

  @override
  String get errorRenameTaken =>
      'A recording with that name already exists. Choose another name.';

  @override
  String get errorRenameInvalid =>
      'Invalid name. Remove slashes and other special characters.';

  @override
  String get errorRenameUnsupported =>
      'Renaming is not supported on this platform.';

  @override
  String get errorRenameFailed =>
      'Rename failed; the original file was not changed.';

  @override
  String get errorUnknown => 'An unknown error occurred.';
}
