class CaptureFormat {
  const CaptureFormat({
    required this.id,
    required this.width,
    required this.height,
    required this.fps,
    required this.fourcc,
  });

  final String id;
  final int width;
  final int height;
  final int fps;
  final String fourcc;

  String get label => '$width×$height ${fps}fps $fourcc';

  double get aspectRatio => height == 0 ? 16 / 9 : width / height;

  factory CaptureFormat.fromMap(Map<dynamic, dynamic> map) {
    return CaptureFormat(
      id: map['id'] as String? ?? '',
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      fps: (map['fps'] as num?)?.toInt() ?? 0,
      fourcc: map['fourcc'] as String? ?? '',
    );
  }
}

enum QualityPreset {
  tiny,
  small,
  standard,
  high;

  static QualityPreset parse(String? raw) {
    return QualityPreset.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => QualityPreset.standard,
    );
  }

  int get baseBitrate {
    switch (this) {
      case QualityPreset.tiny:
        return 2000000;
      case QualityPreset.small:
        return 4000000;
      case QualityPreset.standard:
        return 8000000;
      case QualityPreset.high:
        return 16000000;
    }
  }
}
