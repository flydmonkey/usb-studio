import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'USB Studio'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageZhHans.
  ///
  /// In en, this message translates to:
  /// **'Simplified'**
  String get languageZhHans;

  /// No description provided for @languageZhHant.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get languageZhHant;

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @languageKo.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKo;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @sectionRecord.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get sectionRecord;

  /// No description provided for @sectionPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get sectionPreview;

  /// No description provided for @sectionPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get sectionPicture;

  /// No description provided for @sectionStream.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get sectionStream;

  /// No description provided for @sectionLan.
  ///
  /// In en, this message translates to:
  /// **'LAN playback'**
  String get sectionLan;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer  {name}'**
  String aboutDeveloper(String name);

  /// No description provided for @permissionDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone'**
  String get permissionDisclosureTitle;

  /// No description provided for @permissionDisclosureBody.
  ///
  /// In en, this message translates to:
  /// **'USB Studio uses camera and microphone permission for USB capture-card video and audio. It does not use this device\'s built-in selfie camera.'**
  String get permissionDisclosureBody;

  /// No description provided for @permissionDisclosureContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get permissionDisclosureContinue;

  /// No description provided for @permissionDisclosureNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permissionDisclosureNotNow;

  /// No description provided for @recordSegment.
  ///
  /// In en, this message translates to:
  /// **'Segments'**
  String get recordSegment;

  /// No description provided for @recordQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get recordQuality;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save to'**
  String get saveLocation;

  /// No description provided for @changeFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get changeFolder;

  /// No description provided for @autoRecord.
  ///
  /// In en, this message translates to:
  /// **'Auto-record'**
  String get autoRecord;

  /// No description provided for @previewEnabled.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewEnabled;

  /// No description provided for @previewSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get previewSound;

  /// No description provided for @monitorVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume  {percent}%'**
  String monitorVolume(int percent);

  /// No description provided for @monitorDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get monitorDelay;

  /// No description provided for @videoFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get videoFormat;

  /// No description provided for @resetPicture.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetPicture;

  /// No description provided for @streamUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get streamUrl;

  /// No description provided for @streamKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get streamKey;

  /// No description provided for @streamKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Or paste full URL'**
  String get streamKeyHint;

  /// No description provided for @lanPlayback.
  ///
  /// In en, this message translates to:
  /// **'LAN playback'**
  String get lanPlayback;

  /// No description provided for @copyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyUrl;

  /// No description provided for @lanDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Anyone on the same Wi-Fi can open this address to watch; not encrypted.'**
  String get lanDisclosure;

  /// No description provided for @connectWifi.
  ///
  /// In en, this message translates to:
  /// **'Connect to Wi-Fi first'**
  String get connectWifi;

  /// No description provided for @snapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get snapshot;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @startRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get startRecord;

  /// No description provided for @stopRecord.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopRecord;

  /// No description provided for @startStream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get startStream;

  /// No description provided for @stopStream.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get stopStream;

  /// No description provided for @mutePreview.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mutePreview;

  /// No description provided for @unmutePreview.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmutePreview;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullscreen;

  /// No description provided for @insertCaptureCard.
  ///
  /// In en, this message translates to:
  /// **'Insert USB capture'**
  String get insertCaptureCard;

  /// No description provided for @devicesFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} capture devices'**
  String devicesFound(int count);

  /// No description provided for @snapshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Snapshot saved'**
  String get snapshotSaved;

  /// No description provided for @segmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Segment {index}'**
  String segmentStatus(int index);

  /// No description provided for @previewOffCanRecord.
  ///
  /// In en, this message translates to:
  /// **'Preview is off; recording still works'**
  String get previewOffCanRecord;

  /// No description provided for @noSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal'**
  String get noSignal;

  /// No description provided for @waitingSignal.
  ///
  /// In en, this message translates to:
  /// **'Waiting for signal'**
  String get waitingSignal;

  /// No description provided for @segmentOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get segmentOff;

  /// No description provided for @segmentMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String segmentMinutes(int minutes);

  /// No description provided for @qualityTiny.
  ///
  /// In en, this message translates to:
  /// **'Smaller (~15 MB/min)'**
  String get qualityTiny;

  /// No description provided for @qualitySmall.
  ///
  /// In en, this message translates to:
  /// **'Save space (~30 MB/min)'**
  String get qualitySmall;

  /// No description provided for @qualityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard (~60 MB/min)'**
  String get qualityStandard;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High bitrate (~120 MB/min)'**
  String get qualityHigh;

  /// No description provided for @saveGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get saveGallery;

  /// No description provided for @saveMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get saveMovies;

  /// No description provided for @saveDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get saveDownloads;

  /// No description provided for @saveCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get saveCustom;

  /// No description provided for @savedGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get savedGallery;

  /// No description provided for @savedMovies.
  ///
  /// In en, this message translates to:
  /// **'Saved to Movies'**
  String get savedMovies;

  /// No description provided for @savedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads'**
  String get savedDownloads;

  /// No description provided for @savedCustom.
  ///
  /// In en, this message translates to:
  /// **'Saved to custom folder'**
  String get savedCustom;

  /// No description provided for @pictureBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get pictureBrightness;

  /// No description provided for @pictureContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get pictureContrast;

  /// No description provided for @pictureSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get pictureSaturation;

  /// No description provided for @pictureHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get pictureHue;

  /// No description provided for @recOnly.
  ///
  /// In en, this message translates to:
  /// **'REC  {time}'**
  String recOnly(String time);

  /// No description provided for @recSegment.
  ///
  /// In en, this message translates to:
  /// **'REC  {time}  Seg {index}'**
  String recSegment(String time, int index);

  /// No description provided for @cardRemoved.
  ///
  /// In en, this message translates to:
  /// **'Capture card removed'**
  String get cardRemoved;

  /// No description provided for @cardRemovedSavedMovies.
  ///
  /// In en, this message translates to:
  /// **'Capture card removed; saved to Movies'**
  String get cardRemovedSavedMovies;

  /// No description provided for @cardRemovedSaved.
  ///
  /// In en, this message translates to:
  /// **'Capture card removed; recording saved'**
  String get cardRemovedSaved;

  /// No description provided for @recordInterruptedMovies.
  ///
  /// In en, this message translates to:
  /// **'Recording interrupted; saved to Movies'**
  String get recordInterruptedMovies;

  /// No description provided for @recordInterruptedSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording interrupted; recording saved'**
  String get recordInterruptedSaved;

  /// No description provided for @recordFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed.'**
  String get recordFailed;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet. They appear here after a capture is saved.'**
  String get libraryEmpty;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this recording?'**
  String get deleteTitle;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'It cannot be restored from this app.'**
  String get deleteConfirm;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'No share targets available.'**
  String get shareFailed;

  /// No description provided for @shareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device cannot share that file.'**
  String get shareUnavailable;

  /// No description provided for @mergeAction.
  ///
  /// In en, this message translates to:
  /// **'Merge session'**
  String get mergeAction;

  /// No description provided for @mergeProgress.
  ///
  /// In en, this message translates to:
  /// **'Merging session…'**
  String get mergeProgress;

  /// No description provided for @renameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameAction;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename recording'**
  String get renameTitle;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirmAction;

  /// No description provided for @batteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow recording in the background'**
  String get batteryTitle;

  /// No description provided for @batteryBody.
  ///
  /// In en, this message translates to:
  /// **'The system may pause capture after lock or when the app is in the background. Ignore battery optimizations for this app so recording can continue.'**
  String get batteryBody;

  /// No description provided for @batteryOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get batteryOpenSettings;

  /// No description provided for @batteryLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get batteryLater;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera, microphone, or USB permission is required to capture.'**
  String get errorPermission;

  /// No description provided for @errorUsbHost.
  ///
  /// In en, this message translates to:
  /// **'This device does not support USB Host, so a capture card cannot be used.'**
  String get errorUsbHost;

  /// No description provided for @errorUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'USB capture is only supported on Android phones, tablets, and TVs.'**
  String get errorUnsupportedPlatform;

  /// No description provided for @errorUvcFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the capture card. Confirm it is a UVC device.'**
  String get errorUvcFailed;

  /// No description provided for @errorPowerIssue.
  ///
  /// In en, this message translates to:
  /// **'Could not open the capture card; power may be insufficient. Try a powered USB hub.'**
  String get errorPowerIssue;

  /// No description provided for @errorDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Capture card removed.'**
  String get errorDisconnected;

  /// No description provided for @errorNoAudio.
  ///
  /// In en, this message translates to:
  /// **'The capture card did not provide usable audio.'**
  String get errorNoAudio;

  /// No description provided for @errorRecordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording is in progress; format or quality cannot be changed.'**
  String get errorRecordingInProgress;

  /// No description provided for @errorSessionRecording.
  ///
  /// In en, this message translates to:
  /// **'This session is still recording. Stop it before merging.'**
  String get errorSessionRecording;

  /// No description provided for @errorConcatUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Merging recordings is not supported on this platform.'**
  String get errorConcatUnsupported;

  /// No description provided for @errorConcatStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage to merge.'**
  String get errorConcatStorage;

  /// No description provided for @errorConcatFailed.
  ///
  /// In en, this message translates to:
  /// **'Merge failed; original segments were not changed.'**
  String get errorConcatFailed;

  /// No description provided for @errorPreviewOff.
  ///
  /// In en, this message translates to:
  /// **'Turn preview on first.'**
  String get errorPreviewOff;

  /// No description provided for @errorNoPreview.
  ///
  /// In en, this message translates to:
  /// **'Connect a capture card first.'**
  String get errorNoPreview;

  /// No description provided for @errorStreamUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Streaming is not supported on this platform.'**
  String get errorStreamUnsupported;

  /// No description provided for @errorStreamInProgress.
  ///
  /// In en, this message translates to:
  /// **'Streaming is in progress; format or quality cannot be changed.'**
  String get errorStreamInProgress;

  /// No description provided for @errorMissingUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a stream URL first.'**
  String get errorMissingUrl;

  /// No description provided for @errorNoSignalStream.
  ///
  /// In en, this message translates to:
  /// **'No signal; streaming stopped.'**
  String get errorNoSignalStream;

  /// No description provided for @errorConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the stream server.'**
  String get errorConnectFailed;

  /// No description provided for @errorHttpUnsupported.
  ///
  /// In en, this message translates to:
  /// **'LAN playback is not supported on this platform.'**
  String get errorHttpUnsupported;

  /// No description provided for @errorHttpBindFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the LAN playback port.'**
  String get errorHttpBindFailed;

  /// No description provided for @errorHttpNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'Connect to Wi-Fi first.'**
  String get errorHttpNoNetwork;

  /// No description provided for @errorHttpLiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Live encoding did not start; saved recordings can still play.'**
  String get errorHttpLiveFailed;

  /// No description provided for @errorStreamFailed.
  ///
  /// In en, this message translates to:
  /// **'Streaming failed.'**
  String get errorStreamFailed;

  /// No description provided for @errorPlayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open with the system player.'**
  String get errorPlayFailed;

  /// No description provided for @errorRenameTaken.
  ///
  /// In en, this message translates to:
  /// **'A recording with that name already exists. Choose another name.'**
  String get errorRenameTaken;

  /// No description provided for @errorRenameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid name. Remove slashes and other special characters.'**
  String get errorRenameInvalid;

  /// No description provided for @errorRenameUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Renaming is not supported on this platform.'**
  String get errorRenameUnsupported;

  /// No description provided for @errorRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed; the original file was not changed.'**
  String get errorRenameFailed;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get errorUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
