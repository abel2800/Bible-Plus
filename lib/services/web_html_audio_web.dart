// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

abstract final class WebHtmlAudio {
  static bool get isSupported => true;

  static html.AudioElement? _audio;
  static Timer? _tick;
  static int _playGeneration = 0;
  static final _positionController = StreamController<Duration>.broadcast();
  static final _durationController = StreamController<Duration?>.broadcast();
  static final _playingController = StreamController<bool>.broadcast();

  static html.AudioElement get _element {
    return _audio ??= html.AudioElement()..preload = 'auto';
  }

  static String _normalizedSrc(html.AudioElement audio) {
    final current = audio.currentSrc;
    if (current.isNotEmpty) return current;
    return audio.src;
  }

  static bool _isSameUri(html.AudioElement audio, Uri uri) {
    final current = _normalizedSrc(audio);
    if (current.isEmpty) return false;
    try {
      return Uri.parse(current) == uri || current == uri.toString();
    } catch (_) {
      return current == uri.toString();
    }
  }

  static Future<void> play(Uri uri) async {
    final generation = ++_playGeneration;
    final candidates = <Uri>[uri];
    if (uri.host.toLowerCase() == 'ebible.org') {
      candidates.add(uri.replace(host: 'www.ebible.org'));
    }

    Object? lastError;
    for (final candidate in candidates) {
      if (generation != _playGeneration) return;
      try {
        await _playUri(candidate, generation);
        return;
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('Unable to play audio.');
  }

  static Future<void> _playUri(Uri uri, int generation) async {
    final audio = _element;
    _tick?.cancel();

    if (_isSameUri(audio, uri) && audio.readyState >= 2) {
      if (audio.paused) {
        await audio.play();
      }
      if (generation != _playGeneration) return;
      _playingController.add(true);
      _startTicker();
      return;
    }

    final ready = Completer<void>();
    late StreamSubscription<html.Event> canPlaySub;
    late StreamSubscription<html.Event> errorSub;

    void cleanup() {
      canPlaySub.cancel();
      errorSub.cancel();
    }

    canPlaySub = audio.onCanPlay.listen((_) {
      if (!ready.isCompleted) ready.complete();
    });
    errorSub = audio.onError.listen((_) {
      if (!ready.isCompleted) {
        ready.completeError(
          StateError('Failed to load audio from ${uri.host}.'),
        );
      }
    });

    // Avoid pause()->play() races when swapping sources: stop then assign.
    audio.removeAttribute('src');
    audio.load();
    audio.src = uri.toString();
    audio.load();

    try {
      await ready.future.timeout(const Duration(seconds: 20));
    } finally {
      cleanup();
    }

    if (generation != _playGeneration) return;

    await audio.play();
    if (generation != _playGeneration) {
      audio.pause();
      return;
    }
    _playingController.add(true);
    _startTicker();
  }

  static Future<void> resume() async {
    final audio = _element;
    if (audio.src.isEmpty && audio.currentSrc.isEmpty) {
      throw StateError('No audio loaded to resume.');
    }
    await audio.play();
    _playingController.add(true);
    _startTicker();
  }

  static void _startTicker() {
    _tick?.cancel();
    final audio = _element;
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _positionController.add(
        Duration(milliseconds: (audio.currentTime * 1000).round()),
      );
      final dur = audio.duration;
      if (dur.isFinite) {
        _durationController.add(
          Duration(milliseconds: (dur * 1000).round()),
        );
      }
      _playingController.add(!audio.paused);
    });
  }

  static Future<void> pause() async {
    _element.pause();
    _playingController.add(false);
  }

  static Future<void> stop() async {
    _playGeneration += 1;
    _tick?.cancel();
    _element.pause();
    _element.removeAttribute('src');
    _element.load();
    _playingController.add(false);
  }

  static Future<void> seek(Duration position) async {
    final seconds = position.inMilliseconds / 1000.0;
    final audio = _element;
    final dur = audio.duration;
    final clamped = dur.isFinite
        ? seconds.clamp(0.0, dur)
        : seconds.clamp(0.0, double.infinity);
    audio.currentTime = clamped.toDouble();
    _positionController.add(
      Duration(milliseconds: (audio.currentTime * 1000).round()),
    );
  }

  static Future<void> setSpeed(double speed) async {
    _element.playbackRate = speed;
  }

  static void setMediaSession({
    required String title,
    String? artist,
  }) {
    try {
      final mediaSession = html.window.navigator.mediaSession;
      if (mediaSession == null) return;
      mediaSession.metadata = html.MediaMetadata()
        ..title = title
        ..artist = artist ?? 'BiblePulse'
        ..album = 'Bible audio';
      mediaSession.playbackState = 'playing';
    } catch (_) {
      // Media Session is best-effort on web.
    }
  }

  static Stream<Duration> get positionStream => _positionController.stream;
  static Stream<Duration?> get durationStream => _durationController.stream;
  static Stream<bool> get playingStream => _playingController.stream;
}
