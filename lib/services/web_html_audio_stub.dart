abstract final class WebHtmlAudio {
  static bool get isSupported => false;

  static Future<void> play(Uri uri) async {
    throw UnsupportedError('HTML audio is only available on web');
  }

  static Future<void> pause() async {}
  static Future<void> stop() async {}
  static Future<void> seek(Duration position) async {}
  static Future<void> setSpeed(double speed) async {}

  static void setMediaSession({
    required String title,
    String? artist,
  }) {}

  static Future<void> resume() async {
    throw UnsupportedError('HTML audio is only available on web');
  }

  static Stream<Duration> get positionStream => const Stream.empty();
  static Stream<Duration?> get durationStream => const Stream.empty();
  static Stream<bool> get playingStream => const Stream.empty();
}
