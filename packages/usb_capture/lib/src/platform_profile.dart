class PlatformProfile {
  const PlatformProfile({
    required this.usbCaptureSupported,
    required this.televisionUiMode,
    required this.hasUsbHost,
    required this.hasTouchscreen,
    this.customSaveFolderSupported = false,
    this.rtmpStreamSupported = false,
    this.httpLanSupported = false,
  });

  final bool usbCaptureSupported;
  final bool televisionUiMode;
  final bool hasUsbHost;
  final bool hasTouchscreen;
  final bool customSaveFolderSupported;
  final bool rtmpStreamSupported;
  final bool httpLanSupported;

  factory PlatformProfile.fromMap(Map<dynamic, dynamic> map) {
    return PlatformProfile(
      usbCaptureSupported: map['usbCaptureSupported'] as bool? ?? false,
      televisionUiMode: map['televisionUiMode'] as bool? ?? false,
      hasUsbHost: map['hasUsbHost'] as bool? ?? false,
      hasTouchscreen: map['hasTouchscreen'] as bool? ?? true,
      customSaveFolderSupported:
          map['customSaveFolderSupported'] as bool? ?? false,
      rtmpStreamSupported: map['rtmpStreamSupported'] as bool? ?? false,
      httpLanSupported: map['httpLanSupported'] as bool? ?? false,
    );
  }
}

bool useTelevisionLayout({
  required bool nativeTelevision,
  required bool hasTouch,
  required double shortestSide,
}) {
  if (nativeTelevision) {
    return true;
  }
  return !hasTouch && shortestSide >= 600;
}
