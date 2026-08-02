import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_contracts.dart';

class AudioDownloadProvider extends ChangeNotifier {
  AudioDownloadProvider({
    required this.resolver,
    required this.cache,
    this.maxCacheBytes = 1024 * 1024 * 1024,
  });

  final AudioChapterResolver resolver;
  final AudioChapterCache cache;
  final int maxCacheBytes;

  bool _wifiOnly = true;
  bool _downloading = false;
  bool _pauseRequested = false;
  int _completedChapters = 0;
  int _totalChapters = 0;
  int _receivedBytes = 0;
  int? _currentTotalBytes;
  int _cacheSizeBytes = 0;
  String? _error;

  bool get wifiOnly => _wifiOnly;
  bool get downloading => _downloading;
  bool get pauseRequested => _pauseRequested;
  int get completedChapters => _completedChapters;
  int get totalChapters => _totalChapters;
  int get receivedBytes => _receivedBytes;
  int? get currentTotalBytes => _currentTotalBytes;
  int get cacheSizeBytes => _cacheSizeBytes;
  String? get error => _error;
  double get progress {
    if (_totalChapters == 0) return 0;
    final chapterProgress =
        _currentTotalBytes == null || _currentTotalBytes == 0
            ? 0.0
            : (_receivedBytes / _currentTotalBytes!).clamp(0.0, 1.0);
    return (_completedChapters + chapterProgress) / _totalChapters;
  }

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _wifiOnly = preferences.getBool('audio_wifi_only') ?? true;
    await refreshCacheSize();
  }

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('audio_wifi_only', value);
    notifyListeners();
  }

  Future<void> downloadBook({
    required String versionId,
    required int bookId,
    required int chapterCount,
  }) {
    return downloadChapters(
      versionId: versionId,
      chapters: [
        for (var chapter = 1; chapter <= chapterCount; chapter++)
          (bookId: bookId, chapter: chapter),
      ],
    );
  }

  Future<void> downloadFullBible({
    required String versionId,
    required List<({int bookId, int chapterCount})> books,
  }) {
    return downloadChapters(
      versionId: versionId,
      chapters: [
        for (final book in books)
          for (var chapter = 1; chapter <= book.chapterCount; chapter++)
            (bookId: book.bookId, chapter: chapter),
      ],
    );
  }

  Future<void> downloadChapters({
    required String versionId,
    required List<({int bookId, int chapter})> chapters,
  }) async {
    if (_downloading || chapters.isEmpty) return;
    if (_wifiOnly && !await _isUnmetered()) {
      _error = 'Connect to Wi-Fi before downloading audio.';
      notifyListeners();
      return;
    }
    _downloading = true;
    _pauseRequested = false;
    _error = null;
    _completedChapters = 0;
    _totalChapters = chapters.length;
    notifyListeners();
    try {
      for (final item in chapters) {
        if (_pauseRequested) break;
        final source = await resolver.resolve(
          versionId: versionId,
          bookId: item.bookId,
          chapter: item.chapter,
        );
        if (source == null) {
          throw StateError('Audio is unavailable for a requested chapter.');
        }
        if (!source.downloadPermitted) {
          throw StateError(
            'This Bible Brain fileset is licensed for streaming only.',
          );
        }
        await cache.prepare(
          '$versionId/${item.bookId}/${item.chapter}',
          source,
          maxBytes: maxCacheBytes,
          onProgress: (received, total) {
            if (_pauseRequested) throw const _DownloadPaused();
            _receivedBytes = received;
            _currentTotalBytes = total;
            notifyListeners();
          },
        );
        _completedChapters++;
        _receivedBytes = 0;
        _currentTotalBytes = null;
        notifyListeners();
      }
    } catch (error) {
      if (error is! _DownloadPaused) {
        _error = error.toString().replaceFirst('Bad state: ', '');
      }
    } finally {
      _downloading = false;
      await refreshCacheSize();
      notifyListeners();
    }
  }

  void pause() {
    _pauseRequested = true;
    notifyListeners();
  }

  Future<void> refreshCacheSize() async {
    _cacheSizeBytes = await cache.sizeBytes();
    notifyListeners();
  }

  Future<void> clearCache() async {
    if (_downloading) return;
    await cache.clear();
    await refreshCacheSize();
  }

  Future<bool> _isUnmetered() async {
    if (kIsWeb) return true;
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }
}

class _DownloadPaused implements Exception {
  const _DownloadPaused();
}
