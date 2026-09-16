class LanHttpUrl {
  static String display({required String ipv4, required int port}) {
    return 'http://$ipv4:$port/';
  }

  static String? pickIpv4(Iterable<String> addresses) {
    for (final raw in addresses) {
      final host = raw.trim();
      if (host.isEmpty || host == '127.0.0.1' || host == '0.0.0.0') continue;
      if (host.contains(':')) continue;
      final parts = host.split('.');
      if (parts.length != 4) continue;
      if (parts.every((p) => int.tryParse(p) != null)) return host;
    }
    return null;
  }
}
