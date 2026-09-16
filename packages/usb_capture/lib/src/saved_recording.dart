class SavedRecording {
  const SavedRecording({
    required this.id,
    required this.name,
    required this.uri,
    this.durationMs,
    this.bytes,
    this.shareAvailable = true,
    this.deleteAvailable = true,
  });

  final String id;
  final String name;
  final String uri;
  final int? durationMs;
  final int? bytes;
  final bool shareAvailable;
  final bool deleteAvailable;

  factory SavedRecording.fromMap(Map<dynamic, dynamic> map) {
    return SavedRecording(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      uri: map['uri'] as String? ?? '',
      durationMs: (map['durationMs'] as num?)?.toInt(),
      bytes: (map['bytes'] as num?)?.toInt(),
      shareAvailable: map['shareAvailable'] as bool? ?? true,
      deleteAvailable: map['deleteAvailable'] as bool? ?? true,
    );
  }

  String get subtitle {
    final parts = <String>[];
    final duration = durationMs;
    if (duration != null && duration > 0) {
      final totalSeconds = duration ~/ 1000;
      final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      parts.add('$minutes:$seconds');
    }
    final size = bytes;
    if (size != null && size > 0) {
      parts.add(
        size < 1024 * 1024
            ? '${(size / 1024).toStringAsFixed(0)} KB'
            : '${(size / 1024 / 1024).toStringAsFixed(1)} MB',
      );
    }
    return parts.join('  ·  ');
  }
}
