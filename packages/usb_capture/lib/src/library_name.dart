class LibraryName {
  static final _illegal = RegExp(r'[\\/:*?"<>|\x00-\x1F]');

  static String? normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == '.' || trimmed == '..') return null;
    if (_illegal.hasMatch(trimmed)) return null;
    final stem = trimmed.toLowerCase().endsWith('.mp4')
        ? trimmed.substring(0, trimmed.length - 4)
        : trimmed;
    if (stem.trim().isEmpty) return null;
    if (_illegal.hasMatch(stem)) return null;
    return '$stem.mp4';
  }

  static bool same(String left, String right) {
    return left.toLowerCase() == right.toLowerCase();
  }

  static bool taken(
    Iterable<String> names, {
    required String current,
    required String next,
  }) {
    for (final name in names) {
      if (same(name, current)) {
        continue;
      }
      if (same(name, next)) {
        return true;
      }
    }
    return false;
  }
}
