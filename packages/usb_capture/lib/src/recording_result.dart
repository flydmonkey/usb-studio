import 'save_location.dart';

class RecordingResult {
  const RecordingResult({
    required this.path,
    required this.hasAudio,
    this.savedToMovies = false,
    this.saveKind = SaveLocation.gallery,
  });

  final String path;
  final bool hasAudio;
  final bool savedToMovies;
  final String saveKind;

  factory RecordingResult.fromMap(Map<dynamic, dynamic> map) {
    final kind = SaveLocation.normalize(
      map['saveKind'] as String? ??
          ((map['savedToMovies'] as bool? ?? false)
              ? SaveLocation.movies
              : SaveLocation.gallery),
    );
    return RecordingResult(
      path: map['path'] as String? ?? '',
      hasAudio: map['hasAudio'] as bool? ?? false,
      savedToMovies:
          map['savedToMovies'] as bool? ?? kind == SaveLocation.movies,
      saveKind: kind,
    );
  }
}
