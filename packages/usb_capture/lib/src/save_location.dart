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

  static String optionLabel(String kind, {String? folderName}) {
    switch (kind) {
      case movies:
        return '影片';
      case downloads:
        return '下载';
      case custom:
        final name = folderName?.trim() ?? '';
        return name.isEmpty ? '自定义' : name;
      default:
        return '相册';
    }
  }

  static String savedStatus(String kind) {
    switch (kind) {
      case movies:
        return '已保存到影片目录';
      case downloads:
        return '已保存到下载';
      case custom:
        return '已保存到自定义';
      default:
        return '已保存到相册';
    }
  }

  String get label => optionLabel(kind, folderName: folderName);

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
