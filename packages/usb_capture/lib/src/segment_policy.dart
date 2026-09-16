class SessionSegment {
  const SessionSegment({required this.stamp, required this.index});

  final String stamp;
  final int index;
}

class SegmentPolicy {
  static const duration = Duration(minutes: 10);
  static const allowedMinutes = [0, 5, 10, 15, 30];
  static final _segmentName = RegExp(
    r'^USB_(\d{8}_\d{6})_(\d{2})\.mp4$',
    caseSensitive: false,
  );

  static int normalizeMinutes(int minutes) {
    if (allowedMinutes.contains(minutes)) {
      return minutes;
    }
    return duration.inMinutes;
  }

  static bool isSegmented(int minutes) => minutes > 0;

  static SessionSegment? parseSegmentName(String name) {
    final match = _segmentName.firstMatch(name);
    if (match == null) {
      return null;
    }
    return SessionSegment(
      stamp: match.group(1)!,
      index: int.parse(match.group(2)!),
    );
  }

  static bool canMergeSession(Iterable<String> names, String rowName) {
    final parsed = parseSegmentName(rowName);
    if (parsed == null) {
      return false;
    }
    var count = 0;
    for (final name in names) {
      if (parseSegmentName(name)?.stamp == parsed.stamp) {
        count++;
        if (count >= 2) {
          return true;
        }
      }
    }
    return false;
  }

  static Map<String, List<T>> groupBySession<T>(
    Iterable<T> items,
    String Function(T) nameOf,
  ) {
    final grouped = <String, List<T>>{};
    for (final item in items) {
      final parsed = parseSegmentName(nameOf(item));
      if (parsed == null) {
        continue;
      }
      grouped.putIfAbsent(parsed.stamp, () => <T>[]).add(item);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final left = parseSegmentName(nameOf(a))!.index;
        final right = parseSegmentName(nameOf(b))!.index;
        return left.compareTo(right);
      });
    }
    return grouped;
  }

  static String mergedFileName(String stamp, Iterable<String> existingNames) {
    final used = existingNames.map((name) => name.toLowerCase()).toSet();
    bool taken(String name) => used.contains(name.toLowerCase());
    final preferred = 'USB_$stamp.mp4';
    if (!taken(preferred)) {
      return preferred;
    }
    final merged = 'USB_${stamp}_merged.mp4';
    if (!taken(merged)) {
      return merged;
    }
    var n = 2;
    while (taken('USB_${stamp}_merged$n.mp4')) {
      n++;
    }
    return 'USB_${stamp}_merged$n.mp4';
  }

  static String fileName(
    String sessionStamp,
    int index, {
    required bool segmented,
  }) {
    if (!segmented) {
      return 'USB_$sessionStamp.mp4';
    }
    return 'USB_${sessionStamp}_${index.toString().padLeft(2, '0')}.mp4';
  }

  static int nextIndex(int current) => current + 1;

  static String formatElapsed(Duration elapsed) {
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String recLabel({
    required Duration elapsed,
    required int segmentIndex,
    bool segmented = true,
  }) {
    final time = formatElapsed(elapsed);
    if (!segmented) {
      return 'REC  $time';
    }
    return 'REC  $time  第$segmentIndex段';
  }

  static String segmentOptionLabel(int minutes) {
    if (minutes <= 0) {
      return '关闭';
    }
    return '$minutes 分钟';
  }
}
