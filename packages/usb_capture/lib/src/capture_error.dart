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

  static bool _isCodecNoMemory(String? details) {
    if (details == null) return false;
    final lower = details.toLowerCase();
    return lower.contains('fffffff4') || lower.contains('no_memory');
  }

  String get message {
    switch (code) {
      case CaptureErrorCode.permissionDenied:
        return '需要相机、麦克风或 USB 权限才能采集。';
      case CaptureErrorCode.usbHostMissing:
        return '此设备不支持 USB Host，无法使用采集卡。';
      case CaptureErrorCode.unsupportedPlatform:
        return 'USB 采集仅支持 USB-C iPad（iPadOS 17+）与 Android。iPhone 无法采集。';
      case CaptureErrorCode.uvcFailed:
        return '无法打开采集卡。请确认设备为 UVC 采集卡。';
      case CaptureErrorCode.powerIssue:
        return '无法打开采集卡，可能供电不足。请尝试带供电的 USB Hub。';
      case CaptureErrorCode.disconnected:
        return '采集卡已拔出。';
      case CaptureErrorCode.noAudioSource:
        return '采集卡未提供可用音频。';
      case CaptureErrorCode.recordingFailed:
        if (details == 'recordingInProgress') {
          return '录制进行中，无法更改格式或画质。';
        }
        if (details == 'sessionRecording') {
          return '这场正在录制，请停录后再合并。';
        }
        if (details == 'concatUnsupported') {
          return '当前平台不支持合并录像。';
        }
        if (details == 'concatStorage') {
          return '存储空间不足，无法合并。';
        }
        if (details == 'concatFailed') {
          return '合并失败，原分段未改动。';
        }
        return details ?? '录制失败。';
      case CaptureErrorCode.noPreview:
        if (details == 'previewOff') {
          return '请先开启预览。';
        }
        return '请先连接采集卡。';
      case CaptureErrorCode.streamFailed:
        if (details == 'streamUnsupported') {
          return '当前平台不支持推流。';
        }
        if (details == 'streamInProgress') {
          return '推流进行中，无法更改格式或画质。';
        }
        if (details == 'missingUrl') {
          return '请先填写推流地址。';
        }
        if (details == 'noSignal') {
          return '无信号，已停止推流。';
        }
        if (details == 'connectFailed') {
          return '无法连接推流服务器。';
        }
        if (details == 'httpUnsupported') {
          return '当前平台不支持局域网播放。';
        }
        if (details == 'httpBindFailed') {
          return '无法打开局域网播放端口。';
        }
        if (details == 'httpNoNetwork') {
          return '请先连接 Wi-Fi。';
        }
        if (details == 'httpLiveFailed' || _isCodecNoMemory(details)) {
          return '现场编码未启动，已录成片仍可播放。';
        }
        return details ?? '推流失败。';
      case CaptureErrorCode.unknown:
        if (details == 'playFailed') {
          return '无法用系统播放器打开。';
        }
        if (details == 'renameTaken') {
          return '已有同名录像，请换一个名称。';
        }
        if (details == 'renameInvalid') {
          return '名称无效。请去掉斜杠等特殊字符。';
        }
        if (details == 'renameUnsupported') {
          return '当前平台不支持重命名。';
        }
        if (details == 'renameFailed') {
          return '重命名失败，原文件未改动。';
        }
        return details ?? '发生未知错误。';
    }
  }

  @override
  String toString() => 'CaptureError($code, $message)';
}
