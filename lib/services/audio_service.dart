import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_artwork_theme.dart';
import '../models/audio_queue_item.dart';
import 'audio_cache.dart';
import 'audio_artwork_service.dart';
import 'audio_contracts.dart';
import 'web_html_audio_stub.dart'
    if (dart.library.html) 'web_html_audio_web.dart' as html_audio;

enum AudioSleepMode { off, duration, endOfChapter, endOfBook }

class AudioService with ChangeNotifier {
  AudioService({
    bool enabled = false,
    this.resolver,
    this.timingResolver,
    AudioChapterCache? cache,
    AudioArtworkService? artworkService,
    this.maxCacheBytes = 512 * 1024 * 1024,
  })  : cache = cache ?? PersistentAudioChapterCache(),
        _artworkService = artworkService ?? const AudioArtworkService(),
        enabled = enabled && resolver != null {
    if (this.enabled) {
      unawaited(_init());
    }
  }

  static const _speedPrefsKey = 'audio_playback_speed';
  static const _lastListenVersionKey = 'last_listen_version';
  static const _lastListenBookIdKey = 'last_listen_book';
  static const _lastListenChapterKey = 'last_listen_chapter';
  static const _lastListenBookNameKey = 'last_listen_book_name';
  static const preferredSpeeds = <double>[0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  final bool enabled;
  final AudioChapterResolver? resolver;
  final AudioTimingResolver? timingResolver;
  final AudioChapterCache cache;
  final AudioArtworkService _artworkService;
  final int maxCacheBytes;
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _useHtmlAudio = false;
  bool _isDisposed = false;
  bool _isAdvancingQueue = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  int _playRequestId = 0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _speed = 1.25;
  String? _lastError;
  String? _attribution;
  String? _filesetId;
  List<AudioVerseTiming> _verseTimings = const [];
  int? _currentVerse;
  List<AudioQueueItem> _queue = const [];
  int _queueIndex = -1;
  AudioSleepMode _sleepMode = AudioSleepMode.off;
  DateTime? _sleepUntil;
  Timer? _sleepTimer;
  AudioArtworkTheme? _artworkTheme;
  String? _voiceLabel;

  String? _activeVersion;
  int? _activeBookId;
  int? _activeChapter;
  String? _activeBookName;

  String? _lastListenVersion;
  int? _lastListenBookId;
  int? _lastListenChapter;
  String? _lastListenBookName;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get duration => _duration;
  Duration get position => _position;
  double get speed => _speed;
  String? get lastError => _lastError;
  String? get attribution => _attribution;
  String? get filesetId => _filesetId;
  int? get currentVerse => _currentVerse;
  bool get hasVerseTimings => _verseTimings.isNotEmpty;
  List<AudioVerseTiming> get verseTimings => List.unmodifiable(_verseTimings);
  List<AudioQueueItem> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  bool get hasQueue => _queue.isNotEmpty;
  AudioQueueItem? get currentQueueItem =>
      _queueIndex >= 0 && _queueIndex < _queue.length
          ? _queue[_queueIndex]
          : null;
  AudioSleepMode get sleepMode => _sleepMode;
  DateTime? get sleepUntil => _sleepUntil;
  bool get hasSleepTimer => _sleepMode != AudioSleepMode.off;
  AudioArtworkTheme? get artworkTheme => _artworkTheme;
  String? get voiceLabel => _voiceLabel;
  bool get showMiniPlayer => hasActiveSession;
  bool get hasNextQueueItem =>
      _queueIndex >= 0 && _queueIndex < _queue.length - 1;
  bool get hasPreviousQueueItem => _queueIndex > 0;
  Stream<Duration> get positionStream => _useHtmlAudio
      ? html_audio.WebHtmlAudio.positionStream
      : _player.positionStream;

  bool get hasActiveSession => _activeBookId != null && _activeChapter != null;
  String? get activeVersion => _activeVersion;
  int? get activeBookId => _activeBookId;
  int? get activeChapter => _activeChapter;
  String? get activeBookName => _activeBookName;
  String get activeTitle => _activeBookName == null || _activeChapter == null
      ? 'Audio'
      : '$_activeBookName $_activeChapter';
  String get activeSubtitle => [
        if (_activeVersion != null) _activeVersion,
        if (_voiceLabel != null) _voiceLabel,
      ].join(' • ');

  bool get hasLastListen =>
      _lastListenBookId != null && _lastListenChapter != null;
  String? get lastListenVersion => _lastListenVersion;
  int? get lastListenBookId => _lastListenBookId;
  int? get lastListenChapter => _lastListenChapter;
  String? get lastListenBookName => _lastListenBookName;
  String get lastListenLabel {
    if (!hasLastListen) return 'Bible audio';
    final name = _lastListenBookName ?? 'Book $_lastListenBookId';
    return '$name $_lastListenChapter';
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_speedPrefsKey);
      if (saved != null && saved >= 0.8 && saved <= 2.5) {
        _speed = saved;
      }
      _lastListenVersion = prefs.getString(_lastListenVersionKey);
      _lastListenBookId = prefs.getInt(_lastListenBookIdKey);
      _lastListenChapter = prefs.getInt(_lastListenChapterKey);
      _lastListenBookName = prefs.getString(_lastListenBookNameKey);
    } catch (error) {
      debugPrint('Audio prefs unavailable: $error');
    }

    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      } catch (error) {
        debugPrint('Audio session unavailable: $error');
      }
    }

    _subscriptions.add(_player.playerStateStream.listen((state) {
      if (_useHtmlAudio) return;
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        unawaited(_handleChapterCompleted());
      }
      _notify();
    }));

    _subscriptions.add(_player.durationStream.listen((d) {
      if (_useHtmlAudio) return;
      if (d != null) {
        _duration = d;
        _notify();
      }
    }));

    _subscriptions.add(_player.positionStream.listen((p) {
      if (_useHtmlAudio) return;
      _applyPosition(p);
    }));

    if (html_audio.WebHtmlAudio.isSupported) {
      _subscriptions
          .add(html_audio.WebHtmlAudio.playingStream.listen((playing) {
        if (!_useHtmlAudio) return;
        _isPlaying = playing;
        _isLoading = false;
        _notify();
      }));
      _subscriptions
          .add(html_audio.WebHtmlAudio.durationStream.listen((duration) {
        if (!_useHtmlAudio || duration == null) return;
        _duration = duration;
        _notify();
      }));
      _subscriptions
          .add(html_audio.WebHtmlAudio.positionStream.listen((position) {
        if (!_useHtmlAudio) return;
        _applyPosition(position);
      }));
    }

    try {
      await _player.setSpeed(_speed);
    } catch (_) {}
  }

  void _applyPosition(Duration position) {
    _position = position;
    _currentVerse = _verseAt(position);
    _checkHtmlCompletion();
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Optional catalog of books so the queue can continue across the full Bible.
  List<({int id, String name, int chapters})> _bookCatalog = const [];

  void setBookCatalog(List<({int id, String name, int chapters})> books) {
    _bookCatalog = List.unmodifiable(books);
  }

  Future<void> playChapter(
    String version,
    int bookId,
    int chapter, {
    String? bookName,
    int? bookChapterCount,
    List<({int id, String name, int chapters})>? bookCatalog,
  }) async {
    if (bookCatalog != null) {
      setBookCatalog(bookCatalog);
    }
    final item = AudioQueueItem(
      versionId: version,
      bookId: bookId,
      chapter: chapter,
      bookName: bookName ?? 'Chapter $chapter',
    );
    int? catalogChapters;
    for (final book in _bookCatalog) {
      if (book.id == bookId) {
        catalogChapters = book.chapters;
        break;
      }
    }
    final endChapter = bookChapterCount ?? catalogChapters ?? (chapter + 4);
    await setQueue(
      _seedQueue(item, endChapter: endChapter),
      startIndex: 0,
      autoPlay: false,
    );
    await _playQueueItem(item, queueIndex: 0);
  }

  List<AudioQueueItem> _seedQueue(
    AudioQueueItem current, {
    required int endChapter,
  }) {
    final items = <AudioQueueItem>[];
    final last = endChapter < current.chapter ? current.chapter : endChapter;
    for (var next = current.chapter; next <= last; next += 1) {
      items.add(
        AudioQueueItem(
          versionId: current.versionId,
          bookId: current.bookId,
          chapter: next,
          bookName: current.bookName,
        ),
      );
    }
    return items;
  }

  Future<bool> _appendNextBookToQueue() async {
    if (_activeVersion == null || _activeBookId == null) return false;
    if (_bookCatalog.isEmpty) return false;
    final index = _bookCatalog.indexWhere((b) => b.id == _activeBookId);
    if (index < 0 || index >= _bookCatalog.length - 1) return false;
    final next = _bookCatalog[index + 1];
    await appendFollowingChapters(
      versionId: _activeVersion!,
      bookId: next.id,
      startChapter: 1,
      endChapter: next.chapters,
      bookName: next.name,
    );
    return hasNextQueueItem;
  }

  Future<void> _playQueueItem(
    AudioQueueItem item, {
    int? queueIndex,
  }) async {
    if (!enabled) {
      _lastError =
          'Audio is unavailable until a licensed provider is configured.';
      _notify();
      return;
    }
    final requestId = ++_playRequestId;
    try {
      _isLoading = true;
      _lastError = null;
      _notify();

      final source = await resolver!.resolve(
        versionId: item.versionId,
        bookId: item.bookId,
        chapter: item.chapter,
      );
      if (requestId != _playRequestId) return;
      if (source == null) {
        _lastError =
            'No audio for this chapter. Try WEB/KJV/ASV text, or another chapter.';
        _isLoading = false;
        _notify();
        return;
      }

      if (source.uri.scheme != 'https') {
        throw StateError('Remote audio must use HTTPS.');
      }
      debugPrint('Playing audio: ${source.uri}');
      _attribution = source.attribution;
      _filesetId = source.filesetId;
      _verseTimings = const [];
      _currentVerse = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _artworkTheme = _artworkService.forBook(item.bookName);
      _voiceLabel = item.voiceLabel;

      final rate = _speed.clamp(0.8, 2.5);
      _speed = rate;

      if (kIsWeb && html_audio.WebHtmlAudio.isSupported) {
        _useHtmlAudio = true;
        final cacheKey = '${item.versionId}/${item.bookId}/${item.chapter}';
        Uri playbackUri = source.uri;
        final cached = await cache.lookup(cacheKey, source);
        if (requestId != _playRequestId) return;
        if (cached != null) {
          playbackUri = cached;
        }
        await html_audio.WebHtmlAudio.play(playbackUri);
        if (requestId != _playRequestId) return;
        await html_audio.WebHtmlAudio.setSpeed(rate);
        html_audio.WebHtmlAudio.setMediaSession(
          title: '${item.bookName} ${item.chapter}',
          artist: item.versionId,
        );
        if (source.downloadPermitted && cached == null) {
          unawaited(
            cache
                .prepare(cacheKey, source, maxBytes: maxCacheBytes)
                .catchError((_) => source.uri),
          );
        }
      } else {
        _useHtmlAudio = false;
        final cacheKey = '${item.versionId}/${item.bookId}/${item.chapter}';
        Uri playbackUri = source.uri;
        final cached = await cache.lookup(cacheKey, source);
        if (cached != null) playbackUri = cached;
        if (requestId != _playRequestId) return;
        await _player.stop();
        await _player.setAudioSource(
          AudioSource.uri(
            playbackUri,
            tag: MediaItem(
              id: cacheKey,
              title: '${item.bookName} ${item.chapter}',
              album: item.versionId,
              artist: 'BiblePulse',
            ),
          ),
        );
        await _player.setSpeed(rate);
        await _player.play();
        if (source.downloadPermitted) {
          unawaited(
            cache
                .prepare(cacheKey, source, maxBytes: maxCacheBytes)
                .catchError((_) => source.uri),
          );
        }
      }

      if (requestId != _playRequestId) return;

      _activeVersion = item.versionId;
      _activeBookId = item.bookId;
      _activeChapter = item.chapter;
      _activeBookName = item.bookName;
      if (queueIndex != null) {
        _queueIndex = queueIndex;
      }
      await _persistLastListen(item);
      await _loadVerseTimings();
      _isLoading = false;
      _isPlaying = true;
      _notify();
    } catch (e, st) {
      if (requestId != _playRequestId) return;
      debugPrint('Audio play failed: $e\n$st');
      final message = e.toString();
      if (message.contains('Failed to load') ||
          message.contains('NotSupportedError') ||
          message.contains('NAME_NOT_RESOLVED') ||
          message.contains('NetworkError')) {
        _lastError =
            'Could not reach the audio server. Check your internet connection and try again.';
      } else if (message.contains('AbortError')) {
        _lastError = 'Playback was interrupted. Tap play again.';
      } else {
        _lastError = 'Unable to play this chapter. ($e)';
      }
      _isLoading = false;
      _isPlaying = false;
      _notify();
    }
  }

  Future<void> play() async {
    try {
      if (_useHtmlAudio) {
        await html_audio.WebHtmlAudio.setSpeed(_speed.clamp(0.8, 2.5));
        await html_audio.WebHtmlAudio.resume();
        _isPlaying = true;
        _lastError = null;
        _notify();
        return;
      }
      await _player.setSpeed(_speed.clamp(0.8, 2.5));
      await _player.play();
    } catch (e) {
      // Web resume can fail if the element was cleared; reload the chapter.
      if (_useHtmlAudio &&
          _activeBookId != null &&
          _activeChapter != null &&
          _activeVersion != null) {
        final item = currentQueueItem ??
            AudioQueueItem(
              versionId: _activeVersion!,
              bookId: _activeBookId!,
              chapter: _activeChapter!,
              bookName: _activeBookName ?? 'Chapter ${_activeChapter!}',
            );
        await _playQueueItem(item, queueIndex: _queueIndex);
        return;
      }
      _lastError = 'Unable to resume audio. ($e)';
      _notify();
    }
  }

  Future<void> pause() async {
    if (_useHtmlAudio) {
      await html_audio.WebHtmlAudio.pause();
      _isPlaying = false;
      _notify();
      return;
    }
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    final target = position < Duration.zero ? Duration.zero : position;
    final capped =
        _duration > Duration.zero && target > _duration ? _duration : target;
    _position = capped;
    _currentVerse = _verseAt(capped);
    if (_useHtmlAudio) {
      await html_audio.WebHtmlAudio.seek(capped);
      _notify();
      return;
    }
    await _player.seek(capped);
    _notify();
  }

  Future<void> setSpeed(double speed) async {
    final rate = speed.clamp(0.75, 2.5);
    _speed = rate;
    if (_useHtmlAudio) {
      await html_audio.WebHtmlAudio.setSpeed(rate);
    } else {
      await _player.setSpeed(rate);
    }
    _notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speedPrefsKey, rate);
  }

  Future<void> cycleSpeed() async {
    final current =
        preferredSpeeds.indexWhere((s) => (s - _speed).abs() < 0.01);
    final next = preferredSpeeds[(current + 1) % preferredSpeeds.length];
    await setSpeed(next);
  }

  Future<int> cacheSizeBytes() => cache.sizeBytes();

  Future<void> clearCache() => cache.clear();

  Future<void> setQueue(
    List<AudioQueueItem> items, {
    int startIndex = 0,
    bool autoPlay = false,
  }) async {
    _queue = List<AudioQueueItem>.from(items);
    _queueIndex = _queue.isEmpty ? -1 : startIndex.clamp(0, _queue.length - 1);
    _notify();
    if (autoPlay && _queueIndex >= 0) {
      await playQueueItem(_queueIndex);
    }
  }

  Future<void> playQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _playQueueItem(_queue[index], queueIndex: index);
  }

  Future<void> playNextInQueue() async {
    if (!hasNextQueueItem) {
      final appended = await _appendNextBookToQueue();
      if (!appended) return;
    }
    await playQueueItem(_queueIndex + 1);
  }

  Future<void> playPreviousInQueue() async {
    if (position > const Duration(seconds: 5)) {
      await seek(Duration.zero);
      return;
    }
    if (!hasPreviousQueueItem) {
      await seek(Duration.zero);
      return;
    }
    await playQueueItem(_queueIndex - 1);
  }

  Future<void> appendFollowingChapters({
    required String versionId,
    required int bookId,
    required int startChapter,
    required int endChapter,
    required String bookName,
  }) async {
    final updated = List<AudioQueueItem>.from(_queue);
    for (var chapter = startChapter; chapter <= endChapter; chapter += 1) {
      final item = AudioQueueItem(
        versionId: versionId,
        bookId: bookId,
        chapter: chapter,
        bookName: bookName,
      );
      if (!updated.contains(item)) {
        updated.add(item);
      }
    }
    _queue = updated;
    _notify();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length) {
      return;
    }
    final updated = List<AudioQueueItem>.from(_queue);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    _queue = updated;
    if (_queueIndex == oldIndex) {
      _queueIndex = newIndex;
    } else if (oldIndex < _queueIndex && newIndex >= _queueIndex) {
      _queueIndex -= 1;
    } else if (oldIndex > _queueIndex && newIndex <= _queueIndex) {
      _queueIndex += 1;
    }
    _notify();
  }

  void removeQueueItem(int index) {
    if (index < 0 || index >= _queue.length) return;
    final updated = List<AudioQueueItem>.from(_queue)..removeAt(index);
    _queue = updated;
    if (_queue.isEmpty) {
      _queueIndex = -1;
    } else if (_queueIndex >= _queue.length) {
      _queueIndex = _queue.length - 1;
    } else if (index < _queueIndex) {
      _queueIndex -= 1;
    }
    _notify();
  }

  Future<void> startSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    _sleepMode = AudioSleepMode.duration;
    _sleepUntil = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      unawaited(stopPlayback(clearSession: false));
    });
    _notify();
  }

  void stopAtEndOfChapter() {
    _sleepTimer?.cancel();
    _sleepMode = AudioSleepMode.endOfChapter;
    _sleepUntil = null;
    _notify();
  }

  void stopAtEndOfBook() {
    _sleepTimer?.cancel();
    _sleepMode = AudioSleepMode.endOfBook;
    _sleepUntil = null;
    _notify();
  }

  void clearSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMode = AudioSleepMode.off;
    _sleepUntil = null;
    _notify();
  }

  Future<void> stopPlayback({bool clearSession = false}) async {
    if (_useHtmlAudio) {
      await html_audio.WebHtmlAudio.stop();
    } else {
      await _player.stop();
    }
    _isPlaying = false;
    _position = Duration.zero;
    _currentVerse = null;
    clearSleepTimer();
    if (clearSession) {
      _queue = const [];
      _queueIndex = -1;
      _activeVersion = null;
      _activeBookId = null;
      _activeChapter = null;
      _activeBookName = null;
      _filesetId = null;
      _verseTimings = const [];
      _artworkTheme = null;
      _voiceLabel = null;
    }
    _notify();
  }

  Future<void> _persistLastListen(AudioQueueItem item) async {
    _lastListenVersion = item.versionId;
    _lastListenBookId = item.bookId;
    _lastListenChapter = item.chapter;
    _lastListenBookName = item.bookName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_lastListenVersionKey, item.versionId),
        prefs.setInt(_lastListenBookIdKey, item.bookId),
        prefs.setInt(_lastListenChapterKey, item.chapter),
        prefs.setString(_lastListenBookNameKey, item.bookName),
      ]);
    } catch (error) {
      debugPrint('Unable to save last listen: $error');
    }
  }

  Future<void> _loadVerseTimings() async {
    _verseTimings = const [];
    _currentVerse = null;
    if (timingResolver == null ||
        _filesetId == null ||
        _activeBookId == null ||
        _activeChapter == null) {
      return;
    }
    try {
      final timings = await timingResolver!.resolveTimings(
        filesetId: _filesetId!,
        bookId: _activeBookId!,
        chapter: _activeChapter!,
      );
      _verseTimings = timings;
      _currentVerse = _verseAt(_position);
    } catch (error) {
      debugPrint('Audio timings unavailable: $error');
    }
  }

  void _checkHtmlCompletion() {
    if (!_useHtmlAudio || _duration == Duration.zero || _isAdvancingQueue) {
      return;
    }
    if (_position >= _duration - const Duration(milliseconds: 400)) {
      _isPlaying = false;
      unawaited(_handleChapterCompleted());
    }
  }

  Future<void> _handleChapterCompleted() async {
    if (_isAdvancingQueue) return;
    _isAdvancingQueue = true;
    try {
      if (_sleepMode == AudioSleepMode.endOfChapter) {
        await stopPlayback(clearSession: false);
        return;
      }
      if (_sleepMode == AudioSleepMode.endOfBook && !hasNextQueueItem) {
        await stopPlayback(clearSession: false);
        return;
      }
      if (!hasNextQueueItem) {
        await _appendNextBookToQueue();
      }
      if (hasNextQueueItem) {
        await playNextInQueue();
      } else {
        _isPlaying = false;
        _position = _duration;
        _notify();
      }
    } finally {
      _isAdvancingQueue = false;
    }
  }

  int? _verseAt(Duration position) {
    AudioVerseTiming? active;
    for (final timing in _verseTimings) {
      if (timing.start > position) break;
      if (timing.end == null || timing.end! > position) active = timing;
    }
    return active?.verse;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sleepTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    if (_useHtmlAudio) {
      unawaited(html_audio.WebHtmlAudio.stop());
    }
    _player.dispose();
    super.dispose();
  }
}
