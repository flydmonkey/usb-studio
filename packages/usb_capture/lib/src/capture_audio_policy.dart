class CaptureAudioPolicy {
  static const allowBuiltinMicFallback = false;

  static bool canRecordAudio({required bool hasUsbAudioDevice}) {
    if (allowBuiltinMicFallback) return true;
    return hasUsbAudioDevice;
  }
}
