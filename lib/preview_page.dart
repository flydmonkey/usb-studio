import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:usb_studio/capture_copy.dart';
import 'package:usb_studio/l10n/app_localizations.dart';
import 'package:usb_studio/library_page.dart';
import 'package:usb_studio/locale_mode.dart';
import 'package:usb_studio/operator_prefs.dart';
import 'package:usb_studio/play_listing.dart';
import 'package:usb_capture/usb_capture.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.plugin,
    required this.profile,
    required this.television,
    this.initialPrefs,
    this.onLocaleMode,
  });

  final UsbCapture plugin;
  final PlatformProfile profile;
  final bool television;
  final OperatorPrefs? initialPrefs;
  final ValueChanged<LocaleMode>? onLocaleMode;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> with WidgetsBindingObserver {
  SessionState _session = const SessionState();
  List<CaptureDevice> _devices = const [];
  CaptureDevice? _active;
  CaptureError? _error;
  String Function(AppLocalizations)? _statusOf;
  StreamSubscription<CaptureEvent>? _events;
  Timer? _ticker;
  DateTime? _recordStartedAt;
  OperatorPrefs _prefs = const OperatorPrefs();
  int _prefsEpoch = 0;
  bool _deferAutoRecord = false;
  String? _httpUrl;
  String? _httpError;
  String _appVersion = '';
  final GlobalKey _previewViewKey = GlobalKey();

  bool get _tv => widget.television;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _events = widget.plugin.events().listen(_onEvent);
    final seeded = widget.initialPrefs;
    if (seeded != null) {
      _prefs = seeded;
      _session = _session.copyWith(
        previewMuted: seeded.previewMuted,
        monitorVolume: seeded.monitorVolume,
        monitorDelayMs: seeded.monitorDelayMs,
        segmentMinutes: seeded.segmentMinutes,
        autoRecord: seeded.autoRecord,
        previewEnabled: seeded.previewEnabled,
        quality: seeded.quality,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(_loadVersion());
      if (widget.initialPrefs == null) {
        await _loadPrefs();
      } else {
        await _applySaveLocation(_prefs);
      }
      await _bootstrap();
      if (_prefs.httpLanEnabled && widget.profile.httpLanSupported) {
        await _startHttpServer();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _session.isRecording &&
        _recordStartedAt != null) {
      setState(() {
        _session = _session.copyWith(
          elapsed: DateTime.now().difference(_recordStartedAt!),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _events?.cancel();
    WakelockPlus.disable();
    if (!_session.isRecording) {
      widget.plugin.close();
    }
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    final epoch = _prefsEpoch;
    final prefs = await OperatorPrefs.load();
    if (!mounted || epoch != _prefsEpoch) return;
    setState(() {
      _prefs = prefs;
      _session = _session.copyWith(
        previewMuted: prefs.previewMuted,
        monitorVolume: prefs.monitorVolume,
        monitorDelayMs: prefs.monitorDelayMs,
        segmentMinutes: prefs.segmentMinutes,
        autoRecord: prefs.autoRecord,
        previewEnabled: prefs.previewEnabled,
        quality: prefs.quality,
        immersive: prefs.previewEnabled && _session.immersive,
      );
    });
    await _applySaveLocation(prefs);
    await _syncNativeLocale(prefs.localeMode);
  }

  Future<void> _persist(OperatorPrefs next) async {
    final previousMode = _prefs.localeMode;
    _prefsEpoch++;
    final epoch = _prefsEpoch;
    _prefs = next;
    final saved = await next.save();
    if (!mounted || epoch != _prefsEpoch) return;
    setState(() {
      _prefs = saved;
      _session = _session.copyWith(
        previewMuted: saved.previewMuted,
        monitorVolume: saved.monitorVolume,
        monitorDelayMs: saved.monitorDelayMs,
        segmentMinutes: saved.segmentMinutes,
        autoRecord: saved.autoRecord,
        previewEnabled: saved.previewEnabled,
        quality: saved.quality,
        immersive: saved.previewEnabled && _session.immersive,
      );
    });
    await _applySaveLocation(saved);
    if (saved.localeMode != previousMode) {
      await _syncNativeLocale(saved.localeMode);
      widget.onLocaleMode?.call(saved.localeMode);
    }
  }

  Future<void> _syncNativeLocale(LocaleMode mode) async {
    try {
      await widget.plugin.setUiLocale(
        mode.toBcp47(View.of(context).platformDispatcher.locale),
      );
    } catch (_) {}
  }

  Future<void> _applySaveLocation(OperatorPrefs prefs) async {
    try {
      await widget.plugin.setSaveLocation(
        kind: prefs.saveKind,
        uri: prefs.saveUri,
      );
    } catch (_) {
      // Keep local prefs even if native is unavailable in tests.
    }
  }

  Future<void> _startHttpServer() async {
    await _ensureNotifications();
    try {
      final result = await widget.plugin.startHttpServer();
      if (!mounted) return;
      setState(() {
        _httpUrl = result['url'] as String?;
        _httpError = null;
      });
    } on CaptureError catch (error) {
      if (!mounted) return;
      setState(() {
        _httpUrl = null;
        _httpError = localizeCaptureError(_l10n, error);
      });
    }
  }

  Future<void> _stopHttpServer() async {
    try {
      await widget.plugin.stopHttpServer();
    } catch (_) {
      // Keep local prefs even if native is unavailable in tests.
    }
    if (!mounted) return;
    setState(() {
      _httpUrl = null;
      _httpError = null;
    });
  }

  Future<void> _setHttpLan(bool enabled) async {
    await _persist(_prefs.copyWith(httpLanEnabled: enabled));
    if (enabled) {
      await _startHttpServer();
    } else {
      await _stopHttpServer();
    }
  }

  Future<void> _bootstrap() async {
    if (!widget.profile.usbCaptureSupported) {
      setState(
        () => _error = const CaptureError(CaptureErrorCode.unsupportedPlatform),
      );
      return;
    }
    if (!widget.profile.hasUsbHost) {
      setState(
        () => _error = const CaptureError(CaptureErrorCode.usbHostMissing),
      );
      return;
    }
    try {
      if (!await _ensureCapturePermissions()) {
        return;
      }
      final restored = await _restoreNativeSession();
      if (!restored) {
        await _refreshDevices(autoConnect: true);
      }
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<bool> _ensureCapturePermissions() async {
    final already = await widget.plugin.hasCapturePermissions();
    if (!already) {
      if (!mounted) return false;
      final proceed = await _showCaptureDisclosure();
      if (!proceed) {
        if (mounted) {
          setState(
            () => _error = const CaptureError(CaptureErrorCode.permissionDenied),
          );
        }
        return false;
      }
    }
    try {
      await widget.plugin.requestPermissions();
      return true;
    } on CaptureError catch (error) {
      if (mounted) setState(() => _error = error);
      return false;
    }
  }

  Future<bool> _showCaptureDisclosure() async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          key: const Key('permission-disclosure'),
          title: Text(l10n.permissionDisclosureTitle),
          content: Text(l10n.permissionDisclosureBody),
          actions: [
            TextButton(
              key: const Key('permission-disclosure-not-now'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.permissionDisclosureNotNow),
            ),
            TextButton(
              key: const Key('permission-disclosure-continue'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.permissionDisclosureContinue),
            ),
          ],
        );
      },
    );
    return proceed == true;
  }

  Future<void> _ensureNotifications() async {
    try {
      await widget.plugin.requestNotificationPermission();
    } catch (_) {}
  }

  Future<bool> _restoreNativeSession() async {
    CaptureStatus status;
    try {
      status = await widget.plugin.getCaptureStatus();
    } catch (_) {
      return false;
    }
    if (!status.sessionOpen) {
      return false;
    }
    final devices = await widget.plugin.listDevices();
    CaptureDevice? device;
    for (final item in devices) {
      if (item.id == status.deviceId) {
        device = item;
        break;
      }
    }
    device ??= devices.length == 1 ? devices.first : null;
    if (device == null) {
      return false;
    }
    setState(() => _devices = devices);
    await _connect(device, adoptRecording: status);
    return true;
  }

  Future<void> _refreshDevices({
    bool autoConnect = false,
    bool preserveStatus = false,
  }) async {
    try {
      final devices = await widget.plugin.listDevices();
      setState(() {
        _devices = devices;
        if (preserveStatus) {
          return;
        }
        if (devices.isEmpty) {
          _statusOf = (l10n) => l10n.insertCaptureCard;
        } else {
          _error = null;
          if (devices.length == 1) {
            final name = devices.first.name;
            _statusOf = (_) => name;
          } else {
            final count = devices.length;
            _statusOf = (l10n) => l10n.devicesFound(count);
          }
        }
      });
      if (autoConnect && devices.length == 1) {
        await _connect(devices.first);
      }
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _connect(
    CaptureDevice device, {
    CaptureStatus? adoptRecording,
  }) async {
    try {
      await widget.plugin.open(device.id);
      final formats = await widget.plugin.listFormats();
      final controls = await widget.plugin.listPictureControls();
      setState(() {
        _active = device;
        _session = SessionState(
          sessionOpen: true,
          previewEnabled: _prefs.previewEnabled,
          previewMuted: _prefs.previewMuted,
          monitorVolume: _prefs.monitorVolume,
          monitorDelayMs: _prefs.monitorDelayMs,
          segmentMinutes: _prefs.segmentMinutes,
          autoRecord: _prefs.autoRecord,
          quality: _prefs.quality,
          signal: const SignalStatus(
            hasSignal: true,
            width: 1920,
            height: 1080,
            fps: 30,
          ),
          formats: formats,
          pictureControls: controls,
          selectedFormatId: formats.isEmpty ? null : formats.first.id,
          audioAvailable: device.hasAudio,
          lanLiveBusy: _session.lanLiveBusy,
        );
        _error = null;
        _statusOf = (_) => device.name;
      });
      await widget.plugin.setPreviewMuted(_prefs.previewMuted);
      await widget.plugin.setMonitorVolume(_prefs.monitorVolume);
      await widget.plugin.setMonitorDelay(_prefs.monitorDelayMs);
      try {
        await widget.plugin.setRecordingQuality(_prefs.quality.name);
      } on CaptureError {
        // Quality applies on the next successful set from settings.
      }
      try {
        await widget.plugin.setStreamBitrate(_prefs.streamBitrate.name);
      } on CaptureError {
        // Stream bitrate applies on the next successful set from settings.
      }
      if (adoptRecording != null && adoptRecording.recording) {
        _adoptRecording(adoptRecording);
      } else {
        await _maybeAutoRecord();
      }
      await _syncWakelock();
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  void _adoptRecording(CaptureStatus status) {
    final elapsed = status.elapsed;
    final index = status.segmentIndex < 1 ? 1 : status.segmentIndex;
    _recordStartedAt = DateTime.now().subtract(elapsed);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final origin = _recordStartedAt;
      if (origin == null || !mounted) {
        return;
      }
      setState(() {
        _session = _session.copyWith(
          elapsed: DateTime.now().difference(origin),
        );
      });
    });
    setState(() {
      _session = _session.copyWith(
        recording: RecordingStatus.recording,
        elapsed: elapsed,
        segmentIndex: index,
      );
    });
  }

  Future<void> _syncWakelock() async {
    try {
      if (_session.sessionOpen || _session.isRecording) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
  }

  Future<void> _setPreviewEnabled(bool enabled) async {
    await _persist(_prefs.copyWith(previewEnabled: enabled));
    await _syncWakelock();
  }

  Future<void> _setSaveKind(String kind) async {
    await _persist(_prefs.copyWith(saveKind: kind));
  }

  Future<void> _pickSaveFolder() async {
    try {
      final picked = await widget.plugin.pickSaveFolder();
      if (picked == null || !mounted) {
        return;
      }
      await _persist(
        _prefs.copyWith(
          saveKind: SaveLocation.custom,
          saveUri: picked.uri,
          saveFolderName: picked.folderName,
        ),
      );
    } on CaptureError catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _toggleMute() async {
    final muted = !_session.previewMuted;
    await widget.plugin.setPreviewMuted(muted);
    await _persist(_prefs.copyWith(previewMuted: muted));
  }

  Future<void> _setPreviewSound(bool enabled) async {
    final muted = !enabled;
    await widget.plugin.setPreviewMuted(muted);
    await _persist(_prefs.copyWith(previewMuted: muted));
  }

  Future<void> _setAutoRecord(bool enabled) async {
    await _persist(_prefs.copyWith(autoRecord: enabled));
  }

  Future<void> _setSegment(int minutes) async {
    try {
      CaptureSessionRules.ensureCanChangeSegment(
        isRecording: _session.isRecording,
      );
      await _persist(
        _prefs.copyWith(
          segmentMinutes: SegmentPolicy.normalizeMinutes(minutes),
        ),
      );
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _maybeAutoRecord() async {
    if (_session.isRecording) {
      return;
    }
    if (!CaptureSessionRules.shouldAutoStart(
      autoRecord: _prefs.autoRecord,
      sessionOpen: _session.sessionOpen,
      isRecording: _session.isRecording,
      deferUntilReconnect: _deferAutoRecord,
    )) {
      return;
    }
    await _beginRecording();
  }

  Future<void> _beginRecording() async {
    await _ensureNotifications();
    await widget.plugin.startRecording(segmentMinutes: _prefs.segmentMinutes);
    final started = DateTime.now();
    _recordStartedAt = started;
    setState(() => _session = _session.startRecording());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final origin = _recordStartedAt ?? started;
      setState(() {
        _session = _session.copyWith(
          elapsed: DateTime.now().difference(origin),
        );
      });
    });
    await _syncWakelock();
  }

  Future<void> _toggleRecord() async {
    if (!_session.sessionOpen) {
      setState(() => _error = const CaptureError(CaptureErrorCode.noPreview));
      return;
    }
    try {
      if (_session.isRecording) {
        _ticker?.cancel();
        final result = await widget.plugin.stopRecording();
        _recordStartedAt = null;
        _deferAutoRecord = true;
        setState(() {
          _session = _session.stopRecording();
          final kind = result.saveKind;
          _statusOf = (l10n) => savedStatusLabel(l10n, kind);
          if (!result.hasAudio) {
            _error = const CaptureError(CaptureErrorCode.noAudioSource);
          }
        });
        await _syncWakelock();
      } else {
        await _beginRecording();
      }
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _toggleStream() async {
    if (!widget.profile.rtmpStreamSupported) {
      const error = CaptureError(
        CaptureErrorCode.streamFailed,
        details: 'streamUnsupported',
      );
      setState(() {
        _error = error;
        _statusOf = (l10n) => localizeCaptureError(l10n, error);
      });
      return;
    }
    if (!_session.sessionOpen) {
      setState(() => _error = const CaptureError(CaptureErrorCode.noPreview));
      return;
    }
    try {
      if (_session.isStreaming) {
        await widget.plugin.stopStream();
        setState(() => _session = _session.stopStreaming());
      } else {
        final url = StreamUrl.join(
          server: _prefs.rtmpServer,
          key: _prefs.rtmpKey,
        );
        if (url == null) {
          const error = CaptureError(
            CaptureErrorCode.streamFailed,
            details: 'missingUrl',
          );
          setState(() {
            _error = error;
            _statusOf = (l10n) => localizeCaptureError(l10n, error);
          });
          return;
        }
        await _ensureNotifications();
        await widget.plugin.startStream(url);
        setState(() {
          _session = _session.startStreaming();
          _error = null;
        });
      }
    } on CaptureError catch (error) {
      setState(() {
        _session = _session.stopStreaming();
        _error = error;
        _statusOf = (l10n) => localizeCaptureError(l10n, error);
      });
    }
    await _syncWakelock();
  }

  Future<void> _snapshot() async {
    try {
      CaptureSessionRules.ensureCanSnapshot(
        previewActive: _session.previewActive,
        sessionOpen: _session.sessionOpen,
      );
      await widget.plugin.takeSnapshot();
      setState(() => _statusOf = (l10n) => l10n.snapshotSaved);
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _setFormat(String id) async {
    try {
      CaptureSessionRules.ensureCanChangeFormat(
        isRecording: _session.isRecording,
        isStreaming: _session.isStreaming,
      );
      await widget.plugin.setFormat(id);
      setState(() => _session = _session.copyWith(selectedFormatId: id));
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _setQuality(QualityPreset preset) async {
    try {
      CaptureSessionRules.ensureCanChangeQuality(
        isRecording: _session.isRecording,
        isStreaming: _session.isStreaming,
      );
      await widget.plugin.setRecordingQuality(preset.name);
      await _persist(_prefs.copyWith(quality: preset));
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _setStreamBitrate(StreamBitrate bitrate) async {
    try {
      CaptureSessionRules.ensureCanChangeStreamBitrate(
        isStreaming: _session.isStreaming,
      );
      await widget.plugin.setStreamBitrate(bitrate.name);
      await _persist(_prefs.copyWith(streamBitrate: bitrate));
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
  }

  Future<void> _setVolume(double volume) async {
    await widget.plugin.setMonitorVolume(volume);
    await _persist(_prefs.copyWith(monitorVolume: volume));
  }

  Future<void> _setDelay(int delayMs) async {
    await widget.plugin.setMonitorDelay(delayMs);
    await _persist(_prefs.copyWith(monitorDelayMs: delayMs));
  }

  Future<void> _setPicture(PictureControl control, int value) async {
    await widget.plugin.setPictureControl(control.id.name, value);
    setState(() {
      _session = _session.copyWith(
        pictureControls: [
          for (final item in _session.pictureControls)
            if (item.id == control.id)
              PictureControl(
                id: item.id,
                min: item.min,
                max: item.max,
                value: value,
                defaultValue: item.defaultValue,
                label: item.displayLabel,
              )
            else
              item,
        ],
      );
    });
  }

  Future<void> _resetPicture() async {
    await widget.plugin.resetPictureControls();
    final controls = await widget.plugin.listPictureControls();
    setState(() => _session = _session.copyWith(pictureControls: controls));
  }

  void _toggleImmersive() {
    if (!_session.previewActive) return;
    setState(
      () => _session = _session.copyWith(immersive: !_session.immersive),
    );
  }

  void _onEvent(CaptureEvent event) {
    switch (event.type) {
      case CaptureEventType.attached:
        _refreshDevices(autoConnect: _active == null);
      case CaptureEventType.detached:
        _refreshDevices();
      case CaptureEventType.disconnected:
        _onDisconnected(event);
      case CaptureEventType.audioUnavailable:
        setState(() {
          _error = const CaptureError(CaptureErrorCode.noAudioSource);
          _session = _session.copyWith(audioAvailable: false);
        });
      case CaptureEventType.recordingSaved:
        _onRecordingSaved(event);
      case CaptureEventType.segmentRolled:
        _onSegmentRolled(event);
      case CaptureEventType.batteryOptimizationHint:
        _showBatteryDialog();
      case CaptureEventType.signal:
        if (event.signal != null) {
          setState(() => _session = _session.copyWith(signal: event.signal));
        }
      case CaptureEventType.audioPeak:
        if (event.audioPeak != null) {
          setState(
            () => _session = _session.copyWith(audioPeak: event.audioPeak),
          );
        }
      case CaptureEventType.streamStarted:
        setState(() => _session = _session.copyWith(streaming: true));
      case CaptureEventType.streamStopped:
        setState(() => _session = _session.stopStreaming());
      case CaptureEventType.lanLiveBusy:
        setState(() => _session = _session.copyWith(lanLiveBusy: event.busy));
      case CaptureEventType.error:
        _onCaptureError(event);
    }
  }

  void _onRecordingSaved(CaptureEvent event) {
    if (event.sessionContinuing) {
      _onSegmentRolled(event);
      return;
    }
    _ticker?.cancel();
    _recordStartedAt = null;
    setState(() {
      _session = _session.interruptRecording(saved: true);
      _statusOf = (l10n) => savedStatusLabel(l10n, _prefs.saveKind);
      if (event.hasAudio == false) {
        _error = const CaptureError(CaptureErrorCode.noAudioSource);
      }
    });
    _syncWakelock();
  }

  void _onSegmentRolled(CaptureEvent event) {
    setState(() {
      _session = _session.onSegmentPublished(
        completedIndex: event.segmentIndex ?? _session.segmentIndex,
      );
      final index = _session.segmentIndex;
      _statusOf = (l10n) => l10n.segmentStatus(index);
    });
  }

  Future<void> _showBatteryDialog() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              _l10n.batteryTitle,
              style: TextStyle(fontSize: _tv ? 24 : 18),
            ),
            content: Text(
              _l10n.batteryBody,
              style: TextStyle(fontSize: _tv ? 20 : 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  _l10n.batteryLater,
                  style: TextStyle(fontSize: _tv ? 20 : 16),
                ),
              ),
              TextButton(
                autofocus: _tv,
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  _l10n.batteryOpenSettings,
                  style: TextStyle(fontSize: _tv ? 20 : 16),
                ),
              ),
            ],
          );
        },
      );
      if (go == true && mounted) {
        await widget.plugin.openBatterySettings();
      }
    });
  }

  Future<void> _openLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            LibraryPage(plugin: widget.plugin, television: _tv),
      ),
    );
  }

  void _onDisconnected(CaptureEvent event) {
    _ticker?.cancel();
    _recordStartedAt = null;
    _deferAutoRecord = false;
    setState(() {
      final saved = _session.lastRecordingSalvaged;
      _active = null;
      _session = _session.onDisconnected();
      _error = event.error ?? const CaptureError(CaptureErrorCode.disconnected);
      _statusOf = (l10n) => interruptStatusLabel(
        l10n,
        disconnected: true,
        saved: saved,
        television: _tv,
      );
    });
    _syncWakelock();
    _refreshDevices(preserveStatus: true);
  }

  void _onCaptureError(CaptureEvent event) {
    if (event.error?.code == CaptureErrorCode.streamFailed) {
      setState(() {
        _session = _session.stopStreaming();
        _error = event.error;
        final err = event.error;
        _statusOf = err == null
            ? _statusOf
            : (l10n) => localizeCaptureError(l10n, err);
      });
      _syncWakelock();
      return;
    }
    _ticker?.cancel();
    if (event.error?.code == CaptureErrorCode.disconnected ||
        event.error?.code == CaptureErrorCode.recordingFailed) {
      if (!event.sessionContinuing) {
        _recordStartedAt = null;
      }
    }
    setState(() {
      final saved = _session.lastRecordingSalvaged;
      if (_session.isRecording) {
        _session = _session.interruptRecording(saved: saved);
      }
      _error = event.error;
      if (event.error?.code == CaptureErrorCode.disconnected) {
        _active = null;
        _session = _session.onDisconnected();
        _statusOf = (l10n) => interruptStatusLabel(
          l10n,
          disconnected: true,
          saved: saved,
          television: _tv,
        );
      } else if (saved) {
        _statusOf = (l10n) => interruptStatusLabel(
          l10n,
          disconnected: false,
          saved: true,
          television: _tv,
        );
      }
    });
    _syncWakelock();
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(privacyPolicyUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openAbout() async {
    final television = _tv;
    final version = _appVersion;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final textStyle = TextStyle(fontSize: television ? 20 : 16);
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'USB Studio',
            key: const Key('about-product-name'),
            style: TextStyle(
              fontSize: television ? 24 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (version.isNotEmpty) ...[
                Text(l10n.appVersion(version), style: textStyle),
                SizedBox(height: television ? 12 : 8),
              ],
              Text(l10n.aboutDeveloper(playDeveloperName), style: textStyle),
              SizedBox(height: television ? 16 : 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('about-privacy-policy'),
                  onPressed: _openPrivacyPolicy,
                  child: Text(l10n.privacyPolicy),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('about-licenses'),
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'USB Studio',
                      applicationVersion: version,
                    );
                  },
                  child: Text(l10n.openSourceLicenses),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
        return StatefulBuilder(
          builder: (context, setModal) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            _l10n.settingsTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _tv ? 22 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _l10n.close,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, size: _tv ? 32 : 22),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, _tv ? 48 : 24),
                      child: _SettingsSheet(
                        television: _tv,
                        session: _session,
                        onFormat: _setFormat,
                        onQuality: _setQuality,
                        onVolume: (volume) async {
                          await _setVolume(volume);
                          setModal(() {});
                        },
                        onDelay: (delay) async {
                          await _setDelay(delay);
                          setModal(() {});
                        },
                        onPicture: _setPicture,
                        onResetPicture: _resetPicture,
                        onSegment: (minutes) async {
                          await _setSegment(minutes);
                          setModal(() {});
                        },
                        onAutoRecord: (enabled) async {
                          await _setAutoRecord(enabled);
                          setModal(() {});
                        },
                        onPreviewSound: (enabled) async {
                          await _setPreviewSound(enabled);
                          setModal(() {});
                        },
                        onPreviewEnabled: (enabled) async {
                          await _setPreviewEnabled(enabled);
                          setModal(() {});
                        },
                        onSaveKind: (kind) async {
                          await _setSaveKind(kind);
                          setModal(() {});
                        },
                        onPickFolder: () async {
                          await _pickSaveFolder();
                          setModal(() {});
                        },
                        onRtmpServer: (value) {
                          unawaited(
                            _persist(_prefs.copyWith(rtmpServer: value)),
                          );
                        },
                        onRtmpKey: (value) {
                          unawaited(_persist(_prefs.copyWith(rtmpKey: value)));
                        },
                        onStreamBitrate: (bitrate) async {
                          await _setStreamBitrate(bitrate);
                          setModal(() {});
                        },
                        onHttpLan: (enabled) async {
                          await _setHttpLan(enabled);
                          setModal(() {});
                        },
                        onLocaleMode: (mode) async {
                          await _persist(_prefs.copyWith(localeMode: mode));
                          setModal(() {});
                        },
                        prefs: _prefs,
                        customFolderSupported:
                            widget.profile.customSaveFolderSupported,
                        rtmpStreamSupported:
                            widget.profile.rtmpStreamSupported,
                        httpLanSupported: widget.profile.httpLanSupported,
                        httpUrl: _httpUrl,
                        httpError: _httpError,
                        onAbout: _openAbout,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = _session.immersive ? 0.0 : (_tv ? 48.0 : 16.0);
    final buttonStyle = _tv
        ? const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)
        : const TextStyle(fontSize: 16);
    return PopScope(
      canPop: !_session.immersive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _session.immersive) {
          setState(() => _session = _session.copyWith(immersive: false));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                if (!_session.immersive)
                  _Header(
                    status: _statusOf?.call(_l10n) ??
                        (_error == null
                            ? 'USB Studio'
                            : localizeCaptureError(_l10n, _error!)),
                    deviceName: _active?.name,
                    error: _error,
                    television: _tv,
                    devices: _devices,
                    onSelect: _connect,
                    onSettings: _openSettings,
                    onLibrary: _openLibrary,
                    onSnapshot: _snapshot,
                  ),
                if (!_session.immersive) const SizedBox(height: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _tv ? null : _toggleImmersive,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        _session.immersive ? 0 : 12,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xFF111111)),
                          if (_session.previewActive)
                            Center(
                              child: AspectRatio(
                                aspectRatio: _session.signal.aspectRatio,
                                child: UsbCapturePreview(key: _previewViewKey),
                              ),
                            ),
                          if (_session.sessionOpen && !_session.previewEnabled)
                            _PreviewOffState(television: _tv),
                          if (_session.sessionOpen &&
                              _session.previewEnabled &&
                              _session.lanLiveBusy)
                            _LanLiveBusyState(television: _tv),
                          if (!_session.sessionOpen)
                            _EmptyState(error: _error, television: _tv),
                          if (_session.previewActive &&
                              !_session.signal.hasSignal &&
                              _session.signal.width > 0)
                            const _NoSignal(),
                          if (_session.previewActive)
                            Positioned(
                              top: _session.immersive ? 72 : 16,
                              right: 16,
                              child: _Hud(
                                signal: _session.signal,
                                television: _tv,
                              ),
                            ),
                          if (_session.immersive)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: _SnapshotChip(
                                television: _tv,
                                onPressed: _snapshot,
                              ),
                            ),
                          if (_session.previewActive && _session.audioAvailable)
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: _PeakMeter(
                                peak: _session.audioPeak,
                                television: _tv,
                              ),
                            ),
                          if (_session.isRecording)
                            Positioned(
                              top: 16,
                              left: 16,
                              child: _RecordingBadge(
                                elapsed: _session.elapsed,
                                segmentIndex: _session.segmentIndex,
                                segmented: SegmentPolicy.isSegmented(
                                  _session.segmentMinutes,
                                ),
                                bytesWritten: _session.signal.bytesWritten,
                                television: _tv,
                              ),
                            ),
                          if (_session.isStreaming)
                            Positioned(
                              top: _session.isRecording ? 64 : 16,
                              left: 16,
                              child: _LiveBadge(television: _tv),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!_session.immersive) ...[
                  const SizedBox(height: 12),
                  _CaptureBar(
                    television: _tv,
                    recording: _session.isRecording,
                    streaming: _session.isStreaming,
                    streamSupported: widget.profile.rtmpStreamSupported,
                    muted: _session.previewMuted,
                    onRecord: _toggleRecord,
                    onStream: _toggleStream,
                    onMute: _toggleMute,
                    onImmersive: _toggleImmersive,
                    buttonStyle: buttonStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.status,
    required this.deviceName,
    required this.error,
    required this.television,
    required this.devices,
    required this.onSelect,
    required this.onSettings,
    required this.onLibrary,
    required this.onSnapshot,
  });

  final String status;
  final String? deviceName;
  final CaptureError? error;
  final bool television;
  final List<CaptureDevice> devices;
  final ValueChanged<CaptureDevice> onSelect;
  final VoidCallback onSettings;
  final VoidCallback onLibrary;
  final VoidCallback onSnapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final iconSize = television ? 32.0 : 22.0;
    final IconData statusIcon;
    final Color statusColor;
    if (error != null) {
      statusIcon = Icons.error_outline;
      statusColor = Colors.orangeAccent;
    } else if (deviceName == null) {
      statusIcon = Icons.usb_off;
      statusColor = Colors.white70;
    } else {
      statusIcon = Icons.videocam;
      statusColor = Colors.lightGreenAccent;
    }
    return Row(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: television ? 36 : 24,
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(
            headerTitle(status: status, deviceName: deviceName),
            style: TextStyle(fontSize: television ? 22 : 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (devices.length > 1)
          DropdownButton<String>(
            value: deviceName == null
                ? devices.first.id
                : devices
                      .firstWhere(
                        (item) => item.name == deviceName,
                        orElse: () => devices.first,
                      )
                      .id,
            items: [
              for (final device in devices)
                DropdownMenuItem(value: device.id, child: Text(device.name)),
            ],
            onChanged: (id) {
              final device = devices.firstWhere((item) => item.id == id);
              onSelect(device);
            },
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.snapshot,
                onPressed: onSnapshot,
                icon: Icon(Icons.camera_alt, size: iconSize),
              ),
              IconButton(
                tooltip: l10n.library,
                onPressed: onLibrary,
                icon: Icon(Icons.video_library, size: iconSize),
              ),
              IconButton(
                tooltip: l10n.settings,
                onPressed: onSettings,
                icon: Icon(Icons.tune, size: iconSize),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.error, required this.television});

  final CaptureError? error;
  final bool television;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error == null
              ? AppLocalizations.of(context).insertCaptureCard
              : localizeCaptureError(AppLocalizations.of(context), error!),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: television ? 28 : 18,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _PreviewOffState extends StatelessWidget {
  const _PreviewOffState({required this.television});

  final bool television;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppLocalizations.of(context).previewOffCanRecord,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: television ? 28 : 18,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _LanLiveBusyState extends StatelessWidget {
  const _LanLiveBusyState({required this.television});

  final bool television;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppLocalizations.of(context).previewLanLiveBusy,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: television ? 28 : 18,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _NoSignal extends StatelessWidget {
  const _NoSignal();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Text(
          AppLocalizations.of(context).noSignal,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SnapshotChip extends StatelessWidget {
  const _SnapshotChip({required this.television, required this.onPressed});

  final bool television;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: AppLocalizations.of(context).snapshot,
        onPressed: onPressed,
        iconSize: television ? 32 : 22,
        color: Colors.white,
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.signal, required this.television});

  final SignalStatus signal;
  final bool television;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: television ? 14 : 10,
          vertical: 6,
        ),
        child: Text(
          signalHudLabel(AppLocalizations.of(context), signal),
          style: TextStyle(fontSize: television ? 18 : 13, color: Colors.white),
        ),
      ),
    );
  }
}

class _PeakMeter extends StatelessWidget {
  const _PeakMeter({required this.peak, required this.television});

  final double peak;
  final bool television;

  @override
  Widget build(BuildContext context) {
    final height = television ? 160.0 : 110.0;
    return SizedBox(
      width: television ? 18 : 12,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: peak.clamp(0, 1),
            widthFactor: 1,
            child: ColoredBox(
              color: peak > 0.9 ? Colors.redAccent : Colors.lightGreenAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.television});

  final bool television;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCCB71C1C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: television ? 14 : 10,
          vertical: 6,
        ),
        child: Text(
          'LIVE',
          style: TextStyle(
            fontSize: television ? 18 : 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge({
    required this.elapsed,
    required this.segmentIndex,
    required this.segmented,
    required this.bytesWritten,
    required this.television,
  });

  final Duration elapsed;
  final int segmentIndex;
  final bool segmented;
  final int bytesWritten;
  final bool television;

  @override
  Widget build(BuildContext context) {
    final size = bytesWritten <= 0
        ? ''
        : bytesWritten < 1024 * 1024
        ? '  ${(bytesWritten / 1024).toStringAsFixed(0)} KB'
        : '  ${(bytesWritten / 1024 / 1024).toStringAsFixed(1)} MB';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: television ? 16 : 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${recHudLabel(AppLocalizations.of(context), elapsed: elapsed, segmentIndex: segmentIndex, segmented: segmented)}$size',
        style: TextStyle(
          fontSize: television ? 20 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({
    required this.television,
    required this.session,
    required this.prefs,
    required this.customFolderSupported,
    required this.onFormat,
    required this.onQuality,
    required this.onVolume,
    required this.onDelay,
    required this.onPicture,
    required this.onResetPicture,
    required this.onSegment,
    required this.onAutoRecord,
    required this.onPreviewSound,
    required this.onPreviewEnabled,
    required this.onSaveKind,
    required this.onPickFolder,
    required this.onRtmpServer,
    required this.onRtmpKey,
    required this.onStreamBitrate,
    required this.onHttpLan,
    required this.onLocaleMode,
    required this.rtmpStreamSupported,
    required this.httpLanSupported,
    required this.onAbout,
    this.httpUrl,
    this.httpError,
  });

  final bool television;
  final SessionState session;
  final OperatorPrefs prefs;
  final bool customFolderSupported;
  final ValueChanged<String> onFormat;
  final ValueChanged<QualityPreset> onQuality;
  final ValueChanged<double> onVolume;
  final ValueChanged<int> onDelay;
  final void Function(PictureControl, int) onPicture;
  final VoidCallback onResetPicture;
  final ValueChanged<int> onSegment;
  final ValueChanged<bool> onAutoRecord;
  final ValueChanged<bool> onPreviewSound;
  final ValueChanged<bool> onPreviewEnabled;
  final ValueChanged<String> onSaveKind;
  final VoidCallback onPickFolder;
  final ValueChanged<String> onRtmpServer;
  final ValueChanged<String> onRtmpKey;
  final ValueChanged<StreamBitrate> onStreamBitrate;
  final ValueChanged<bool> onHttpLan;
  final ValueChanged<LocaleMode> onLocaleMode;
  final bool rtmpStreamSupported;
  final bool httpLanSupported;
  final VoidCallback onAbout;
  final String? httpUrl;
  final String? httpError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saveKind = SaveLocation.normalize(prefs.saveKind);
    final saveValue = saveKind == SaveLocation.custom && !customFolderSupported
        ? SaveLocation.gallery
        : saveKind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingsSection(
          title: l10n.language,
          television: television,
          children: [
            _SettingsDropdown<LocaleMode>(
              television: television,
              value: prefs.localeMode,
              items: [
                DropdownMenuItem(
                  value: LocaleMode.system,
                  child: Text(l10n.languageSystem),
                ),
                DropdownMenuItem(
                  value: LocaleMode.zhHans,
                  child: Text(l10n.languageZhHans),
                ),
                DropdownMenuItem(
                  value: LocaleMode.zhHant,
                  child: Text(l10n.languageZhHant),
                ),
                DropdownMenuItem(
                  value: LocaleMode.ja,
                  child: Text(l10n.languageJa),
                ),
                DropdownMenuItem(
                  value: LocaleMode.ko,
                  child: Text(l10n.languageKo),
                ),
                DropdownMenuItem(
                  value: LocaleMode.en,
                  child: Text(l10n.languageEn),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) onLocaleMode(mode);
              },
            ),
          ],
        ),
        _SettingsSection(
          title: l10n.sectionRecord,
          television: television,
          children: [
            Text(l10n.recordSegment),
            _SettingsDropdown<int>(
              television: television,
              value: SegmentPolicy.normalizeMinutes(session.segmentMinutes),
              items: [
                for (final minutes in SegmentPolicy.allowedMinutes)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(segmentOptionLabel(l10n, minutes)),
                  ),
              ],
              onChanged: session.isRecording
                  ? null
                  : (minutes) {
                      if (minutes != null) onSegment(minutes);
                    },
            ),
            Text(l10n.recordQuality),
            _SettingsDropdown<QualityPreset>(
              television: television,
              value: session.quality,
              items: [
                for (final preset in QualityPreset.values)
                  DropdownMenuItem(
                    value: preset,
                    child: Text(qualityLabel(l10n, preset)),
                  ),
              ],
              onChanged: (session.isRecording || session.isStreaming)
                  ? null
                  : (preset) {
                      if (preset != null) onQuality(preset);
                    },
            ),
            if (customFolderSupported) ...[
              Text(l10n.saveLocation),
              _SettingsDropdown<String>(
                television: television,
                value: saveValue,
                items: [
                  DropdownMenuItem(
                    value: SaveLocation.gallery,
                    child: Text(saveLocationLabel(l10n, SaveLocation.gallery)),
                  ),
                  DropdownMenuItem(
                    value: SaveLocation.movies,
                    child: Text(saveLocationLabel(l10n, SaveLocation.movies)),
                  ),
                  DropdownMenuItem(
                    value: SaveLocation.downloads,
                    child: Text(
                      saveLocationLabel(l10n, SaveLocation.downloads),
                    ),
                  ),
                  DropdownMenuItem(
                    value: SaveLocation.custom,
                    child: Text(
                      saveLocationLabel(
                        l10n,
                        SaveLocation.custom,
                        folderName: prefs.saveFolderName,
                      ),
                    ),
                  ),
                ],
                onChanged: (kind) {
                  if (kind == null) return;
                  if (kind == SaveLocation.custom) {
                    onPickFolder();
                  } else {
                    onSaveKind(kind);
                  }
                },
              ),
              if (saveKind == SaveLocation.custom)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onPickFolder,
                    child: Text(l10n.changeFolder),
                  ),
                ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.autoRecord,
                style: TextStyle(fontSize: television ? 20 : 16),
              ),
              value: session.autoRecord,
              onChanged: onAutoRecord,
            ),
          ],
        ),
        _SettingsSection(
          title: l10n.sectionPreview,
          television: television,
          trailing: Switch(
            value: session.previewEnabled,
            onChanged: onPreviewEnabled,
          ),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.previewSound,
                style: TextStyle(fontSize: television ? 20 : 16),
              ),
              value: !session.previewMuted,
              onChanged: onPreviewSound,
            ),
            Text(l10n.monitorVolume((session.monitorVolume * 100).round())),
            Slider(value: session.monitorVolume, onChanged: onVolume),
            Text(l10n.monitorDelay),
            _SettingsChoiceRow(
              television: television,
              value: session.monitorDelayMs,
              options: const [0, 50, 100, 200],
              labelOf: (delay) => '${delay}ms',
              onSelected: onDelay,
            ),
          ],
        ),
        if (session.formats.isNotEmpty || session.pictureControls.isNotEmpty)
          _SettingsSection(
            title: l10n.sectionPicture,
            television: television,
            children: [
              if (session.formats.isNotEmpty) ...[
                Text(l10n.videoFormat),
                _SettingsDropdown<String>(
                  television: television,
                  value:
                      session.formats.any(
                        (item) => item.id == session.selectedFormatId,
                      )
                      ? session.selectedFormatId
                      : session.formats.first.id,
                  items: [
                    for (final format in session.formats)
                      DropdownMenuItem(
                        value: format.id,
                        child: Text(format.label),
                      ),
                  ],
                  onChanged: (session.isRecording || session.isStreaming)
                      ? null
                      : (id) {
                          if (id != null) onFormat(id);
                        },
                ),
              ],
              if (session.pictureControls.isNotEmpty) ...[
                for (final control in session.pictureControls) ...[
                  Text(
                    '${pictureControlLabel(l10n, control.id)}  ${control.value}',
                  ),
                  Slider(
                    min: control.min.toDouble(),
                    max: control.max.toDouble(),
                    value: control.value.toDouble().clamp(
                      control.min.toDouble(),
                      control.max.toDouble(),
                    ),
                    onChanged: (value) => onPicture(control, value.round()),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onResetPicture,
                    child: Text(l10n.resetPicture),
                  ),
                ),
              ],
            ],
          ),
        if (rtmpStreamSupported)
          _SettingsSection(
            title: l10n.sectionStream,
            television: television,
            children: [
              _RtmpUrlFields(
                television: television,
                prefs: prefs,
                onRtmpServer: onRtmpServer,
                onRtmpKey: onRtmpKey,
              ),
              Text(l10n.streamBitrate),
              _SettingsDropdown<StreamBitrate>(
                key: const Key('stream-bitrate'),
                television: television,
                value: prefs.streamBitrate,
                items: [
                  for (final bitrate in StreamBitrate.values)
                    DropdownMenuItem(
                      value: bitrate,
                      child: Text(streamBitrateLabel(l10n, bitrate)),
                    ),
                ],
                onChanged: session.isStreaming
                    ? null
                    : (bitrate) {
                        if (bitrate != null) onStreamBitrate(bitrate);
                      },
              ),
            ],
          ),
        if (httpLanSupported)
          _SettingsSection(
            title: l10n.sectionLan,
            television: television,
            trailing: Switch(
              key: const Key('lan-playback'),
              value: prefs.httpLanEnabled,
              onChanged: onHttpLan,
            ),
            children: [
              if (prefs.httpLanEnabled) ...[
                if (httpUrl != null)
                  TextFormField(
                    readOnly: true,
                    initialValue: httpUrl,
                    style: TextStyle(fontSize: television ? 18 : 14),
                    decoration: _settingsFieldDecoration().copyWith(
                      suffixIcon: IconButton(
                        tooltip: l10n.copyUrl,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: httpUrl!));
                        },
                        icon: Icon(Icons.copy, size: television ? 28 : 20),
                      ),
                    ),
                  )
                else
                  Text(
                    httpError ?? l10n.connectWifi,
                    style: TextStyle(
                      fontSize: television ? 18 : 14,
                      color: Colors.orangeAccent,
                    ),
                  ),
                Text(
                  l10n.lanDisclosure,
                  style: TextStyle(
                    fontSize: television ? 16 : 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ListTile(
          key: const Key('about-open'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.sectionAbout,
            style: TextStyle(fontSize: television ? 20 : 16),
          ),
          onTap: onAbout,
        ),
      ],
    );
  }
}

InputDecoration _settingsFieldDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFF2A2A2A),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}

class _RtmpUrlFields extends StatefulWidget {
  const _RtmpUrlFields({
    required this.television,
    required this.prefs,
    required this.onRtmpServer,
    required this.onRtmpKey,
  });

  final bool television;
  final OperatorPrefs prefs;
  final ValueChanged<String> onRtmpServer;
  final ValueChanged<String> onRtmpKey;

  @override
  State<_RtmpUrlFields> createState() => _RtmpUrlFieldsState();
}

class _RtmpUrlFieldsState extends State<_RtmpUrlFields> {
  late final TextEditingController _server;
  late final TextEditingController _key;

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.prefs.rtmpServer);
    _key = TextEditingController(text: widget.prefs.rtmpKey);
  }

  @override
  void dispose() {
    widget.onRtmpServer(_server.text);
    widget.onRtmpKey(_key.text);
    _server.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fontSize = widget.television ? 20.0 : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.streamUrl),
        TextFormField(
          key: const Key('rtmp-server'),
          controller: _server,
          style: TextStyle(fontSize: fontSize),
          decoration: _settingsFieldDecoration(
            hint: 'rtmp://live.example/live',
          ),
          onChanged: widget.onRtmpServer,
        ),
        Text(l10n.streamKey),
        TextFormField(
          key: const Key('rtmp-key'),
          controller: _key,
          obscureText: true,
          style: TextStyle(fontSize: fontSize),
          decoration: _settingsFieldDecoration(hint: l10n.streamKeyHint),
          onChanged: widget.onRtmpKey,
        ),
      ],
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    super.key,
    required this.television,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final bool television;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: television ? 20 : 16, color: Colors.white),
      dropdownColor: const Color(0xFF2A2A2A),
      decoration: _settingsFieldDecoration(),
    );
  }
}

class _SettingsChoiceRow<T> extends StatelessWidget {
  const _SettingsChoiceRow({
    required this.television,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onSelected,
  });

  final bool television;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onSelected(options[i]),
              style: OutlinedButton.styleFrom(
                backgroundColor: value == options[i]
                    ? const Color(0xFF2A3A55)
                    : const Color(0xFF2A2A2A),
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: value == options[i]
                      ? Colors.lightBlueAccent
                      : Colors.white24,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: television ? 16 : 10,
                  horizontal: 4,
                ),
                minimumSize: Size(0, television ? 56 : 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labelOf(options[i]),
                  maxLines: 1,
                  style: TextStyle(fontSize: television ? 18 : 13),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.television,
    required this.children,
    this.trailing,
  });

  final String title;
  final bool television;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: television ? 20 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          if (title.isNotEmpty) const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.television,
    required this.recording,
    required this.streaming,
    required this.streamSupported,
    required this.muted,
    required this.onRecord,
    required this.onStream,
    required this.onMute,
    required this.onImmersive,
    required this.buttonStyle,
  });

  final bool television;
  final bool recording;
  final bool streaming;
  final bool streamSupported;
  final bool muted;
  final VoidCallback onRecord;
  final VoidCallback onStream;
  final VoidCallback onMute;
  final VoidCallback onImmersive;
  final TextStyle buttonStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gap = television ? 12.0 : 8.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(television ? 12 : 8),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            children: [
              if (streamSupported) ...[
                Expanded(
                  child: _ControlButton(
                    order: 5,
                    television: television,
                    label: streaming ? l10n.stopStream : l10n.startStream,
                    icon: streaming ? Icons.stop_circle : Icons.wifi_tethering,
                    onPressed: onStream,
                    textStyle: buttonStyle,
                  ),
                ),
                SizedBox(width: gap),
              ],
              Expanded(
                child: _ControlButton(
                  autofocus: television,
                  order: 1,
                  television: television,
                  label: recording ? l10n.stopRecord : l10n.startRecord,
                  icon: recording ? Icons.stop : Icons.fiber_manual_record,
                  onPressed: onRecord,
                  textStyle: buttonStyle,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _ControlButton(
                  order: 3,
                  television: television,
                  label: muted ? l10n.unmutePreview : l10n.mutePreview,
                  icon: muted ? Icons.volume_off : Icons.volume_up,
                  onPressed: onMute,
                  textStyle: buttonStyle,
                ),
              ),
              if (television) ...[
                SizedBox(width: gap),
                Expanded(
                  child: _ControlButton(
                    order: 4,
                    television: television,
                    label: l10n.fullscreen,
                    icon: Icons.fullscreen,
                    onPressed: onImmersive,
                    textStyle: buttonStyle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.television,
    required this.order,
    required this.textStyle,
    this.autofocus = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool television;
  final double order;
  final TextStyle textStyle;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          autofocus: autofocus,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(television ? 72 : 48),
            padding: EdgeInsets.symmetric(
              horizontal: television ? 16 : 4,
              vertical: 12,
            ),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: television ? 32 : 20),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
