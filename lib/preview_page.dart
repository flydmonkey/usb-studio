import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_camera_capture/library_page.dart';
import 'package:usb_camera_capture/operator_prefs.dart';
import 'package:usb_capture/usb_capture.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.plugin,
    required this.profile,
    required this.television,
    this.initialPrefs,
  });

  final UsbCapture plugin;
  final PlatformProfile profile;
  final bool television;
  final OperatorPrefs? initialPrefs;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> with WidgetsBindingObserver {
  SessionState _session = const SessionState();
  List<CaptureDevice> _devices = const [];
  CaptureDevice? _active;
  CaptureError? _error;
  String? _status;
  StreamSubscription<CaptureEvent>? _events;
  Timer? _ticker;
  DateTime? _recordStartedAt;
  OperatorPrefs _prefs = const OperatorPrefs();
  bool _deferAutoRecord = false;
  String? _httpUrl;
  String? _httpError;

  bool get _tv => widget.television;

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

  Future<void> _loadPrefs() async {
    final prefs = await OperatorPrefs.load();
    if (!mounted) return;
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
  }

  Future<void> _persist(OperatorPrefs next) async {
    final saved = await next.save();
    if (!mounted) return;
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
        _httpError = error.message;
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
      await widget.plugin.requestPermissions();
      final restored = await _restoreNativeSession();
      if (!restored) {
        await _refreshDevices(autoConnect: true);
      }
    } on CaptureError catch (error) {
      setState(() => _error = error);
    }
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
          _status = '请插入 USB 采集卡';
        } else {
          _error = null;
          _status = devices.length == 1
              ? devices.first.name
              : '发现 ${devices.length} 台采集设备';
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
        );
        _error = null;
        _status = device.name;
      });
      await widget.plugin.setPreviewMuted(_prefs.previewMuted);
      await widget.plugin.setMonitorVolume(_prefs.monitorVolume);
      await widget.plugin.setMonitorDelay(_prefs.monitorDelayMs);
      try {
        await widget.plugin.setRecordingQuality(_prefs.quality.name);
      } on CaptureError {
        // Quality applies on the next successful set from settings.
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
          _status = SaveLocation.savedStatus(result.saveKind);
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
        _status = error.message;
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
            _status = error.message;
          });
          return;
        }
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
        _status = error.message;
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
      setState(() => _status = '已保存截图');
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
      _status = SaveLocation.savedStatus(_prefs.saveKind);
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
      _status = '第${_session.segmentIndex}段';
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
              BatteryOptCopy.title,
              style: TextStyle(fontSize: _tv ? 24 : 18),
            ),
            content: Text(
              BatteryOptCopy.body,
              style: TextStyle(fontSize: _tv ? 20 : 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  BatteryOptCopy.later,
                  style: TextStyle(fontSize: _tv ? 20 : 16),
                ),
              ),
              TextButton(
                autofocus: _tv,
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  BatteryOptCopy.openSettings,
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
      _status = CaptureSessionRules.interruptStatus(
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
        _status = event.error?.message;
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
        _status = CaptureSessionRules.interruptStatus(
          disconnected: true,
          saved: saved,
          television: _tv,
        );
      } else if (saved) {
        _status = CaptureSessionRules.interruptStatus(
          disconnected: false,
          saved: true,
          television: _tv,
        );
      }
    });
    _syncWakelock();
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
                            '采集设置',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _tv ? 22 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '关闭',
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
                        onRtmpServer: (value) async {
                          await _persist(_prefs.copyWith(rtmpServer: value));
                          setModal(() {});
                        },
                        onRtmpKey: (value) async {
                          await _persist(_prefs.copyWith(rtmpKey: value));
                          setModal(() {});
                        },
                        onHttpLan: (enabled) async {
                          await _setHttpLan(enabled);
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
                    status: _status ?? (_error?.message ?? 'USB 采集'),
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
                                child: const UsbCapturePreview(),
                              ),
                            ),
                          if (_session.sessionOpen && !_session.previewEnabled)
                            _PreviewOffState(television: _tv),
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
    final iconSize = television ? 32.0 : 22.0;
    return Row(
      children: [
        Icon(
          error == null ? Icons.videocam : Icons.error_outline,
          color: error == null ? Colors.lightGreenAccent : Colors.orangeAccent,
          size: television ? 36 : 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            deviceName == null ? status : '$deviceName  ·  $status',
            style: TextStyle(fontSize: television ? 22 : 16),
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
                tooltip: '截图',
                onPressed: onSnapshot,
                icon: Icon(Icons.camera_alt, size: iconSize),
              ),
              IconButton(
                tooltip: LibraryCopy.title,
                onPressed: onLibrary,
                icon: Icon(Icons.video_library, size: iconSize),
              ),
              IconButton(
                tooltip: '设置',
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
          error?.message ?? '请插入 USB 采集卡',
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
          '预览已关闭，仍可录制',
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
    return const ColoredBox(
      color: Color(0x99000000),
      child: Center(
        child: Text(
          '无信号',
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
        tooltip: '截图',
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
          signal.hudLabel,
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
        '${SegmentPolicy.recLabel(elapsed: elapsed, segmentIndex: segmentIndex, segmented: segmented)}$size',
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
    required this.onHttpLan,
    required this.rtmpStreamSupported,
    required this.httpLanSupported,
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
  final ValueChanged<bool> onHttpLan;
  final bool rtmpStreamSupported;
  final bool httpLanSupported;
  final String? httpUrl;
  final String? httpError;

  @override
  Widget build(BuildContext context) {
    final saveKind = SaveLocation.normalize(prefs.saveKind);
    final saveValue = saveKind == SaveLocation.custom && !customFolderSupported
        ? SaveLocation.gallery
        : saveKind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingsSection(
          title: '录制',
          television: television,
          children: [
            const Text('录制分段'),
            DropdownButton<int>(
              isExpanded: true,
              value: SegmentPolicy.normalizeMinutes(session.segmentMinutes),
              items: [
                for (final minutes in SegmentPolicy.allowedMinutes)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(SegmentPolicy.segmentOptionLabel(minutes)),
                  ),
              ],
              onChanged: session.isRecording
                  ? null
                  : (minutes) {
                      if (minutes != null) onSegment(minutes);
                    },
            ),
            const Text('录制画质'),
            DropdownButton<QualityPreset>(
              isExpanded: true,
              value: session.quality,
              items: [
                for (final preset in QualityPreset.values)
                  DropdownMenuItem(
                    value: preset,
                    child: Text(preset.optionLabel),
                  ),
              ],
              onChanged: (session.isRecording || session.isStreaming)
                  ? null
                  : (preset) {
                      if (preset != null) onQuality(preset);
                    },
            ),
            if (customFolderSupported) ...[
              const Text('保存位置'),
              DropdownButton<String>(
                isExpanded: true,
                value: saveValue,
                items: [
                  DropdownMenuItem(
                    value: SaveLocation.gallery,
                    child: Text(SaveLocation.optionLabel(SaveLocation.gallery)),
                  ),
                  DropdownMenuItem(
                    value: SaveLocation.movies,
                    child: Text(SaveLocation.optionLabel(SaveLocation.movies)),
                  ),
                  DropdownMenuItem(
                    value: SaveLocation.downloads,
                    child: Text(
                      SaveLocation.optionLabel(SaveLocation.downloads),
                    ),
                  ),
                  DropdownMenuItem(
                    value: SaveLocation.custom,
                    child: Text(
                      SaveLocation.optionLabel(
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
                    child: const Text('更改目录'),
                  ),
                ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '连接后自动开录',
                style: TextStyle(fontSize: television ? 20 : 16),
              ),
              value: session.autoRecord,
              onChanged: onAutoRecord,
            ),
          ],
        ),
        _SettingsSection(
          title: '预览',
          television: television,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '开启预览',
                style: TextStyle(fontSize: television ? 20 : 16),
              ),
              value: session.previewEnabled,
              onChanged: onPreviewEnabled,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '预览声音',
                style: TextStyle(fontSize: television ? 20 : 16),
              ),
              value: !session.previewMuted,
              onChanged: onPreviewSound,
            ),
            Text('监听音量  ${(session.monitorVolume * 100).round()}%'),
            Slider(value: session.monitorVolume, onChanged: onVolume),
            const Text('监听延迟'),
            Wrap(
              spacing: 8,
              children: [
                for (final delay in const [0, 50, 100, 200])
                  ChoiceChip(
                    label: Text('${delay}ms'),
                    selected: session.monitorDelayMs == delay,
                    onSelected: (_) => onDelay(delay),
                  ),
              ],
            ),
          ],
        ),
        if (session.formats.isNotEmpty || session.pictureControls.isNotEmpty)
          _SettingsSection(
            title: '画面',
            television: television,
            children: [
              if (session.formats.isNotEmpty) ...[
                const Text('视频格式'),
                DropdownButton<String>(
                  isExpanded: true,
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
                  Text('${control.displayLabel}  ${control.value}'),
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
                    child: const Text('恢复默认'),
                  ),
                ),
              ],
            ],
          ),
        if (rtmpStreamSupported)
          _SettingsSection(
            title: '推流',
            television: television,
            children: [
              const Text('推流地址'),
              TextFormField(
                initialValue: prefs.rtmpServer,
                style: TextStyle(fontSize: television ? 20 : 16),
                decoration: const InputDecoration(
                  hintText: 'rtmp://live.example/live',
                  filled: true,
                  fillColor: Color(0xFF2A2A2A),
                ),
                onChanged: onRtmpServer,
              ),
              const Text('推流密钥（选填）'),
              TextFormField(
                initialValue: prefs.rtmpKey,
                obscureText: true,
                style: TextStyle(fontSize: television ? 20 : 16),
                decoration: const InputDecoration(
                  hintText: '也可把完整地址填在上面',
                  filled: true,
                  fillColor: Color(0xFF2A2A2A),
                ),
                onChanged: onRtmpKey,
              ),
            ],
          ),
        if (httpLanSupported)
          _SettingsSection(
            title: '局域网播放',
            television: television,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '局域网播放',
                  style: TextStyle(fontSize: television ? 20 : 16),
                ),
                value: prefs.httpLanEnabled,
                onChanged: onHttpLan,
              ),
              if (prefs.httpLanEnabled) ...[
                if (httpUrl != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SelectableText(
                          httpUrl!,
                          style: TextStyle(fontSize: television ? 18 : 14),
                        ),
                      ),
                      IconButton(
                        tooltip: '复制地址',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: httpUrl!));
                        },
                        icon: Icon(Icons.copy, size: television ? 28 : 22),
                      ),
                    ],
                  )
                else
                  Text(
                    httpError ?? '请先连接 Wi-Fi',
                    style: TextStyle(
                      fontSize: television ? 18 : 14,
                      color: Colors.orangeAccent,
                    ),
                  ),
                Text(
                  '同一 Wi-Fi 下打开此地址即可播放；未加密',
                  style: TextStyle(
                    fontSize: television ? 16 : 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.television,
    required this.children,
  });

  final String title;
  final bool television;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: television ? 20 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
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
                    label: streaming ? '停止推流' : '推流',
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
                  label: recording ? '停止录制' : '开始录制',
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
                  label: muted ? '取消静音' : '预览静音',
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
                    label: '全屏',
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
          label: Text(
            label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
