class SignalStatus {
  const SignalStatus({
    this.width = 0,
    this.height = 0,
    this.fps = 0,
    this.fourcc = '',
    this.hasSignal = false,
    this.bytesWritten = 0,
  });

  final int width;
  final int height;
  final int fps;
  final String fourcc;
  final bool hasSignal;
  final int bytesWritten;

  double get aspectRatio => height == 0 ? 16 / 9 : width / height;

  String get hudLabel {
    if (width <= 0 || height <= 0) {
      return '';
    }
    final rate = fps > 0 ? ' ${fps}fps' : '';
    final format = fourcc.isEmpty ? '' : ' $fourcc';
    return '$width×$height$rate$format';
  }

  factory SignalStatus.fromMap(Map<dynamic, dynamic> map) {
    return SignalStatus(
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      fps: (map['fps'] as num?)?.toInt() ?? 0,
      fourcc: map['fourcc'] as String? ?? '',
      hasSignal: map['hasSignal'] as bool? ?? false,
      bytesWritten: (map['bytesWritten'] as num?)?.toInt() ?? 0,
    );
  }

  SignalStatus copyWith({
    int? width,
    int? height,
    int? fps,
    String? fourcc,
    bool? hasSignal,
    int? bytesWritten,
  }) {
    return SignalStatus(
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      fourcc: fourcc ?? this.fourcc,
      hasSignal: hasSignal ?? this.hasSignal,
      bytesWritten: bytesWritten ?? this.bytesWritten,
    );
  }
}
