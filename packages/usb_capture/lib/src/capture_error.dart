enum CaptureErrorCode {
  permissionDenied,
  usbHostMissing,
  unsupportedPlatform,
  uvcFailed,
  powerIssue,
  disconnected,
  noAudioSource,
  recordingFailed,
  noPreview,
  streamFailed,
  unknown,
}

class CaptureError implements Exception {
  const CaptureError(this.code, {this.details});

  final CaptureErrorCode code;
  final String? details;

  factory CaptureError.fromCode(String? raw, {String? details}) {
    final code = CaptureErrorCode.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => CaptureErrorCode.unknown,
    );
    return CaptureError(code, details: details);
  }

  static bool isCodecNoMemory(String? details) {
    if (details == null) return false;
    final lower = details.toLowerCase();
    return lower.contains('fffffff4') || lower.contains('no_memory');
  }

  /// Logs and tests. UI copy lives in the app's AppLocalizations.
  String get message {
    final detail = details;
    if (detail == null || detail.isEmpty) return code.name;
    return '${code.name}: $detail';
  }

  @override
  String toString() => 'CaptureError($code, $message)';
}
