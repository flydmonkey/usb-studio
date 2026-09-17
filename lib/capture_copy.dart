import 'package:usb_capture/usb_capture.dart';
import 'package:usb_studio/l10n/app_localizations.dart';

String localizeCaptureError(AppLocalizations l10n, CaptureError error) {
  switch (error.code) {
    case CaptureErrorCode.permissionDenied:
      return l10n.errorPermission;
    case CaptureErrorCode.usbHostMissing:
      return l10n.errorUsbHost;
    case CaptureErrorCode.unsupportedPlatform:
      return l10n.errorUnsupportedPlatform;
    case CaptureErrorCode.uvcFailed:
      return l10n.errorUvcFailed;
    case CaptureErrorCode.powerIssue:
      return l10n.errorPowerIssue;
    case CaptureErrorCode.disconnected:
      return l10n.errorDisconnected;
    case CaptureErrorCode.noAudioSource:
      return l10n.errorNoAudio;
    case CaptureErrorCode.recordingFailed:
      switch (error.details) {
        case 'recordingInProgress':
          return l10n.errorRecordingInProgress;
        case 'sessionRecording':
          return l10n.errorSessionRecording;
        case 'concatUnsupported':
          return l10n.errorConcatUnsupported;
        case 'concatStorage':
          return l10n.errorConcatStorage;
        case 'concatFailed':
          return l10n.errorConcatFailed;
        default:
          return error.details ?? l10n.recordFailed;
      }
    case CaptureErrorCode.noPreview:
      return error.details == 'previewOff'
          ? l10n.errorPreviewOff
          : l10n.errorNoPreview;
    case CaptureErrorCode.streamFailed:
      switch (error.details) {
        case 'streamUnsupported':
          return l10n.errorStreamUnsupported;
        case 'streamInProgress':
          return l10n.errorStreamInProgress;
        case 'missingUrl':
          return l10n.errorMissingUrl;
        case 'noSignal':
          return l10n.errorNoSignalStream;
        case 'connectFailed':
          return l10n.errorConnectFailed;
        case 'httpUnsupported':
          return l10n.errorHttpUnsupported;
        case 'httpBindFailed':
          return l10n.errorHttpBindFailed;
        case 'httpNoNetwork':
          return l10n.errorHttpNoNetwork;
        default:
          if (error.details == 'httpLiveFailed' ||
              CaptureError.isCodecNoMemory(error.details)) {
            return l10n.errorHttpLiveFailed;
          }
          return error.details ?? l10n.errorStreamFailed;
      }
    case CaptureErrorCode.unknown:
      switch (error.details) {
        case 'playFailed':
          return l10n.errorPlayFailed;
        case 'renameTaken':
          return l10n.errorRenameTaken;
        case 'renameInvalid':
          return l10n.errorRenameInvalid;
        case 'renameUnsupported':
          return l10n.errorRenameUnsupported;
        case 'renameFailed':
          return l10n.errorRenameFailed;
        default:
          return error.details ?? l10n.errorUnknown;
      }
  }
}

String pictureControlLabel(AppLocalizations l10n, PictureControlId id) {
  switch (id) {
    case PictureControlId.brightness:
      return l10n.pictureBrightness;
    case PictureControlId.contrast:
      return l10n.pictureContrast;
    case PictureControlId.saturation:
      return l10n.pictureSaturation;
    case PictureControlId.hue:
      return l10n.pictureHue;
  }
}

String qualityLabel(AppLocalizations l10n, QualityPreset preset) {
  switch (preset) {
    case QualityPreset.tiny:
      return l10n.qualityTiny;
    case QualityPreset.small:
      return l10n.qualitySmall;
    case QualityPreset.standard:
      return l10n.qualityStandard;
    case QualityPreset.high:
      return l10n.qualityHigh;
  }
}

String streamBitrateLabel(AppLocalizations l10n, StreamBitrate bitrate) {
  switch (bitrate) {
    case StreamBitrate.mbps1:
      return l10n.streamMbps1;
    case StreamBitrate.mbps2:
      return l10n.streamMbps2;
    case StreamBitrate.mbps4:
      return l10n.streamMbps4;
    case StreamBitrate.mbps6:
      return l10n.streamMbps6;
  }
}

String saveLocationLabel(
  AppLocalizations l10n,
  String kind, {
  String? folderName,
}) {
  switch (kind) {
    case SaveLocation.movies:
      return l10n.saveMovies;
    case SaveLocation.downloads:
      return l10n.saveDownloads;
    case SaveLocation.custom:
      final name = folderName?.trim() ?? '';
      return name.isEmpty ? l10n.saveCustom : name;
    default:
      return l10n.saveGallery;
  }
}

String savedStatusLabel(AppLocalizations l10n, String kind) {
  switch (kind) {
    case SaveLocation.movies:
      return l10n.savedMovies;
    case SaveLocation.downloads:
      return l10n.savedDownloads;
    case SaveLocation.custom:
      return l10n.savedCustom;
    default:
      return l10n.savedGallery;
  }
}

String segmentOptionLabel(AppLocalizations l10n, int minutes) {
  if (minutes <= 0) {
    return l10n.segmentOff;
  }
  return l10n.segmentMinutes(minutes);
}

String recHudLabel(
  AppLocalizations l10n, {
  required Duration elapsed,
  required int segmentIndex,
  required bool segmented,
}) {
  final time = SegmentPolicy.formatElapsed(elapsed);
  if (!segmented) {
    return l10n.recOnly(time);
  }
  return l10n.recSegment(time, segmentIndex);
}

String interruptStatusLabel(
  AppLocalizations l10n, {
  required bool disconnected,
  required bool saved,
  required bool television,
}) {
  if (disconnected) {
    if (!saved) {
      return l10n.cardRemoved;
    }
    return television ? l10n.cardRemovedSavedMovies : l10n.cardRemovedSaved;
  }
  if (saved) {
    return television
        ? l10n.recordInterruptedMovies
        : l10n.recordInterruptedSaved;
  }
  return l10n.recordFailed;
}

String signalHudLabel(AppLocalizations l10n, SignalStatus signal) {
  if (signal.width <= 0 || signal.height <= 0) {
    return l10n.waitingSignal;
  }
  return signal.hudLabel;
}

String headerTitle({required String status, String? deviceName}) {
  if (deviceName == null || deviceName.isEmpty) return status;
  if (status.isEmpty || status == deviceName) return deviceName;
  return '$deviceName  ·  $status';
}
