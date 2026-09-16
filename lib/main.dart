import 'package:flutter/material.dart';
import 'package:usb_capture/usb_capture.dart';

import 'preview_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UsbCaptureApp());
}

class UsbCaptureApp extends StatelessWidget {
  const UsbCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USB采集',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CaptureBootstrap(),
    );
  }
}

class CaptureBootstrap extends StatefulWidget {
  const CaptureBootstrap({super.key});

  @override
  State<CaptureBootstrap> createState() => _CaptureBootstrapState();
}

class _CaptureBootstrapState extends State<CaptureBootstrap> {
  final UsbCapture _plugin = UsbCapture();
  late final Future<PlatformProfile> _profile = _plugin.getPlatformProfile();

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
          plugin: _plugin,
          profile: profile,
          television: television,
        );
      },
    );
  }
}
