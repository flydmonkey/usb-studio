class CaptureDevice {
  const CaptureDevice({
    required this.id,
    required this.name,
    this.hasAudio = false,
  });

  final String id;
  final String name;
  final bool hasAudio;

  factory CaptureDevice.fromMap(Map<dynamic, dynamic> map) {
    return CaptureDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'USB 采集卡',
      hasAudio: map['hasAudio'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'hasAudio': hasAudio,
  };
}
