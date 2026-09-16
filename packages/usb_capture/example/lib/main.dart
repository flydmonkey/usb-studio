import 'package:flutter/material.dart';
import 'package:usb_capture/usb_capture.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _profileText = 'Unknown';
  final _usbCapturePlugin = UsbCapture();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    final profile = await _usbCapturePlugin.getPlatformProfile();
    if (!mounted) return;
    setState(() {
      _profileText =
          'supported=${profile.usbCaptureSupported} tv=${profile.televisionUiMode}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('usb_capture example')),
        body: Center(child: Text(_profileText)),
      ),
    );
  }
}
