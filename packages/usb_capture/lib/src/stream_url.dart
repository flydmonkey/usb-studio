class StreamUrl {
  static String? join({required String server, required String key}) {
    var host = server.trim();
    var streamKey = key.trim();
    if (host.isEmpty && _isRtmp(streamKey)) {
      host = streamKey;
      streamKey = '';
    }
    if (host.isEmpty || !_isRtmp(host)) {
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

  static bool _isRtmp(String value) {
    final scheme = value.toLowerCase();
    return scheme.startsWith('rtmp://') || scheme.startsWith('rtmps://');
  }

  static bool _hasAppPath(String host) {
    final rest = host.substring(host.indexOf('://') + 3);
    return rest.contains('/');
  }
}
