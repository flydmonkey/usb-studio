class StreamUrl {
  static String? join({required String server, required String key}) {
    final host = server.trim();
    final streamKey = key.trim();
    if (host.isEmpty) {
      return null;
    }
    final scheme = host.toLowerCase();
    if (!scheme.startsWith('rtmp://') && !scheme.startsWith('rtmps://')) {
      return null;
    }
    if (streamKey.isEmpty) {
      return _hasAppPath(host) ? host : null;
    }
    if (streamKey.startsWith('?')) {
      return '$host$streamKey';
    }
    return '${host.replaceFirst(RegExp(r'/+$'), '')}/$streamKey';
  }

  static bool _hasAppPath(String host) {
    final rest = host.substring(host.indexOf('://') + 3);
    return rest.contains('/');
  }
}
