class SaveLocation {
  const SaveLocation({required this.kind, this.uri, this.folderName});

  static const gallery = 'gallery';
  static const movies = 'movies';
  static const downloads = 'downloads';
  static const custom = 'custom';

  final String kind;
  final String? uri;
  final String? folderName;

  bool get isCustom => kind == custom;

  static String normalize(String? kind) {
    switch (kind) {
      case movies:
      case downloads:
      case custom:
        return kind!;
      default:
        return gallery;
    }
  }

  factory SaveLocation.fromMap(Map<dynamic, dynamic> map) {
    return SaveLocation(
      kind: map['kind'] as String? ?? gallery,
      uri: map['uri'] as String?,
      folderName: map['folderName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'kind': kind, 'uri': uri, 'folderName': folderName};
  }
}
