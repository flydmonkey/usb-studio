import 'package:flutter/material.dart';
import 'package:usb_capture/usb_capture.dart';
import 'package:usb_studio/l10n/app_localizations.dart';
import 'package:usb_studio/locale_mode.dart';
import 'package:usb_studio/operator_prefs.dart';

import 'preview_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UsbCaptureApp());
}

class UsbCaptureApp extends StatefulWidget {
  const UsbCaptureApp({super.key});

  @override
  State<UsbCaptureApp> createState() => _UsbCaptureAppState();
}

class _UsbCaptureAppState extends State<UsbCaptureApp> {
  LocaleMode _localeMode = LocaleMode.system;
  OperatorPrefs? _prefs;
  final UsbCapture _plugin = UsbCapture();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await OperatorPrefs.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _localeMode = prefs.localeMode;
    });
    await _syncNativeLocale(prefs.localeMode);
  }

  Future<void> _syncNativeLocale(LocaleMode mode) async {
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    try {
      await _plugin.setUiLocale(mode.toBcp47(device));
    } catch (_) {
      // Tests and platforms without the method still run the UI.
    }
  }

  void _onLocaleMode(LocaleMode mode) {
    setState(() => _localeMode = mode);
    _syncNativeLocale(mode);
  }

  @override
  Widget build(BuildContext context) {
    final device = View.maybeOf(context)?.platformDispatcher.locale ??
        WidgetsBinding.instance.platformDispatcher.locale;
    final locale = _localeMode.resolve(device);
    return MaterialApp(
      title: 'USB Studio',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localeResolutionCallback: (_, _) => locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: CaptureBootstrap(
        plugin: _plugin,
        initialPrefs: _prefs,
        onLocaleMode: _onLocaleMode,
      ),
    );
  }
}

class CaptureBootstrap extends StatefulWidget {
  const CaptureBootstrap({
    super.key,
    required this.plugin,
    this.initialPrefs,
    this.onLocaleMode,
  });

  final UsbCapture plugin;
  final OperatorPrefs? initialPrefs;
  final ValueChanged<LocaleMode>? onLocaleMode;

  @override
  State<CaptureBootstrap> createState() => _CaptureBootstrapState();
}

class _CaptureBootstrapState extends State<CaptureBootstrap> {
  late final Future<PlatformProfile> _profile = widget.plugin
      .getPlatformProfile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data!;
        final size = MediaQuery.sizeOf(context);
        final television = useTelevisionLayout(
          nativeTelevision: profile.televisionUiMode,
          hasTouch: profile.hasTouchscreen,
          shortestSide: size.shortestSide,
        );
        return PreviewPage(
          plugin: widget.plugin,
          profile: profile,
          television: television,
          initialPrefs: widget.initialPrefs,
          onLocaleMode: widget.onLocaleMode,
        );
      },
    );
  }
}
