import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_capture/usb_capture.dart';

class OperatorPrefs {
  const OperatorPrefs({
    this.segmentMinutes = 10,
    this.autoRecord = false,
    this.previewMuted = false,
    this.monitorVolume = 1,
    this.monitorDelayMs = 0,
    this.previewEnabled = true,
    this.quality = QualityPreset.standard,
    this.saveKind = SaveLocation.gallery,
    this.saveUri,
    this.saveFolderName,
    this.rtmpServer = '',
    this.rtmpKey = '',
    this.httpLanEnabled = false,
  });

  final int segmentMinutes;
  final bool autoRecord;
  final bool previewMuted;
  final double monitorVolume;
  final int monitorDelayMs;
  final bool previewEnabled;
  final QualityPreset quality;
  final String saveKind;
  final String? saveUri;
  final String? saveFolderName;
  final String rtmpServer;
  final String rtmpKey;
  final bool httpLanEnabled;

  static const _segmentKey = 'operator.segmentMinutes';
  static const _autoRecordKey = 'operator.autoRecord';
  static const _mutedKey = 'operator.previewMuted';
  static const _volumeKey = 'operator.monitorVolume';
  static const _delayKey = 'operator.monitorDelayMs';
  static const _previewKey = 'operator.previewEnabled';
  static const _qualityKey = 'operator.quality';
  static const _saveKindKey = 'operator.saveKind';
  static const _saveUriKey = 'operator.saveUri';
  static const _saveFolderKey = 'operator.saveFolderName';
  static const _rtmpServerKey = 'operator.rtmpServer';
  static const _rtmpKeyKey = 'operator.rtmpKey';
  static const _httpLanEnabledKey = 'operator.httpLanEnabled';
  static const _keep = Object();

  OperatorPrefs copyWith({
    int? segmentMinutes,
    bool? autoRecord,
    bool? previewMuted,
    double? monitorVolume,
    int? monitorDelayMs,
    bool? previewEnabled,
    QualityPreset? quality,
    String? saveKind,
    Object? saveUri = _keep,
    Object? saveFolderName = _keep,
    String? rtmpServer,
    String? rtmpKey,
    bool? httpLanEnabled,
  }) {
    return OperatorPrefs(
      segmentMinutes: segmentMinutes ?? this.segmentMinutes,
      autoRecord: autoRecord ?? this.autoRecord,
      previewMuted: previewMuted ?? this.previewMuted,
      monitorVolume: monitorVolume ?? this.monitorVolume,
      monitorDelayMs: monitorDelayMs ?? this.monitorDelayMs,
      previewEnabled: previewEnabled ?? this.previewEnabled,
      quality: quality ?? this.quality,
      saveKind: SaveLocation.normalize(saveKind ?? this.saveKind),
      saveUri: identical(saveUri, _keep) ? this.saveUri : saveUri as String?,
      saveFolderName: identical(saveFolderName, _keep)
          ? this.saveFolderName
          : saveFolderName as String?,
      rtmpServer: rtmpServer ?? this.rtmpServer,
      rtmpKey: rtmpKey ?? this.rtmpKey,
      httpLanEnabled: httpLanEnabled ?? this.httpLanEnabled,
    );
  }

  static Future<OperatorPrefs> load() async {
    final stored = await SharedPreferences.getInstance();
    return OperatorPrefs(
      segmentMinutes: SegmentPolicy.normalizeMinutes(
        stored.getInt(_segmentKey) ?? 10,
      ),
      autoRecord: stored.getBool(_autoRecordKey) ?? false,
      previewMuted: stored.getBool(_mutedKey) ?? false,
      monitorVolume: (stored.getDouble(_volumeKey) ?? 1).clamp(0, 1),
      monitorDelayMs: stored.getInt(_delayKey) ?? 0,
      previewEnabled: stored.getBool(_previewKey) ?? true,
      quality: QualityPreset.parse(stored.getString(_qualityKey)),
      saveKind: SaveLocation.normalize(stored.getString(_saveKindKey)),
      saveUri: stored.getString(_saveUriKey),
      saveFolderName: stored.getString(_saveFolderKey),
      rtmpServer: stored.getString(_rtmpServerKey) ?? '',
      rtmpKey: stored.getString(_rtmpKeyKey) ?? '',
      httpLanEnabled: stored.getBool(_httpLanEnabledKey) ?? false,
    );
  }

  Future<OperatorPrefs> save() async {
    final stored = await SharedPreferences.getInstance();
    await stored.setInt(_segmentKey, segmentMinutes);
    await stored.setBool(_autoRecordKey, autoRecord);
    await stored.setBool(_mutedKey, previewMuted);
    await stored.setDouble(_volumeKey, monitorVolume);
    await stored.setInt(_delayKey, monitorDelayMs);
    await stored.setBool(_previewKey, previewEnabled);
    await stored.setString(_qualityKey, quality.name);
    await stored.setString(_saveKindKey, SaveLocation.normalize(saveKind));
    final uri = saveUri;
    if (uri == null || uri.isEmpty) {
      await stored.remove(_saveUriKey);
    } else {
      await stored.setString(_saveUriKey, uri);
    }
    final folder = saveFolderName;
    if (folder == null || folder.isEmpty) {
      await stored.remove(_saveFolderKey);
    } else {
      await stored.setString(_saveFolderKey, folder);
    }
    await stored.setString(_rtmpServerKey, rtmpServer);
    await stored.setString(_rtmpKeyKey, rtmpKey);
    await stored.setBool(_httpLanEnabledKey, httpLanEnabled);
    return this;
  }
}
