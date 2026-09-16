enum PictureControlId {
  brightness,
  contrast,
  saturation,
  hue;

  static PictureControlId? tryParse(String? raw) {
    for (final value in PictureControlId.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  String get label {
    switch (this) {
      case PictureControlId.brightness:
        return 'Brightness';
      case PictureControlId.contrast:
        return 'Contrast';
      case PictureControlId.saturation:
        return 'Saturation';
      case PictureControlId.hue:
        return 'Hue';
    }
  }
}

class PictureControl {
  const PictureControl({
    required this.id,
    required this.min,
    required this.max,
    required this.value,
    required this.defaultValue,
    String? label,
  }) : label = label ?? '';

  final PictureControlId id;
  final int min;
  final int max;
  final int value;
  final int defaultValue;
  final String label;

  String get displayLabel => label.isEmpty ? id.label : label;

  factory PictureControl.fromMap(Map<dynamic, dynamic> map) {
    final id =
        PictureControlId.tryParse(map['id'] as String?) ??
        PictureControlId.brightness;
    return PictureControl(
      id: id,
      min: (map['min'] as num?)?.toInt() ?? 0,
      max: (map['max'] as num?)?.toInt() ?? 100,
      value: (map['value'] as num?)?.toInt() ?? 0,
      defaultValue: (map['defaultValue'] as num?)?.toInt() ?? 0,
      label: map['label'] as String? ?? id.label,
    );
  }
}
