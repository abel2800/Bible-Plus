// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'audio_contracts.dart';

/// Browser offline cache backed by IndexedDB.
class PersistentAudioChapterCache implements AudioChapterCache {
  PersistentAudioChapterCache();

  static const _dbName = 'biblepulse-audio-v1';
  static const _storeName = 'chapters';

  Future<dynamic> _openDb() {
    final factory = html.window.indexedDB;
    if (factory == null) {
      return Future.error(StateError('IndexedDB unavailable'));
    }
    return factory.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (event) {
        final db = event.target.result;
        final names = (db.objectStoreNames as List?) ?? const [];
        if (!names.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      },
    );
  }

  @override
  Future<Uri?> lookup(String cacheKey, AudioChapterSource source) async {
    final bytes = await _read(cacheKey);
    if (bytes == null || bytes.isEmpty) return null;
    final blob = html.Blob([bytes], 'audio/mpeg');
    return Uri.parse(html.Url.createObjectUrlFromBlob(blob));
  }

  @override
  Future<bool> has(String cacheKey) async {
    final bytes = await _read(cacheKey);
    return bytes != null && bytes.isNotEmpty;
  }

  Future<Uint8List?> _read(String cacheKey) async {
    try {
      final db = await _openDb();
      final tx = db.transaction(_storeName, 'readonly');
      final store = tx.objectStore(_storeName);
      final value = await store.getObject(cacheKey);
      await tx.completed;
      return _asBytes(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String cacheKey, Uint8List bytes) async {
    final db = await _openDb();
    final tx = db.transaction(_storeName, 'readwrite');
    tx.objectStore(_storeName).put(bytes.buffer, cacheKey);
    await tx.completed;
  }

  @override
  Future<Uri> prepare(
    String cacheKey,
    AudioChapterSource source, {
    required int maxBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    if (!source.downloadPermitted) return source.uri;

    final existing = await lookup(cacheKey, source);
    if (existing != null) return existing;

    try {
      final bytes = await _downloadBytes(source.uri, onProgress: onProgress);
      try {
        await _write(cacheKey, bytes);
        await _evictIfNeeded(maxBytes, keep: cacheKey);
      } catch (_) {
        // If writing to IndexedDB fails, continue and return a blob URL so playback still works.
      }
      final blob = html.Blob([bytes], 'audio/mpeg');
      return Uri.parse(html.Url.createObjectUrlFromBlob(blob));
    } catch (error) {
      // Network/CORS/IndexedDB issues should not crash the app on web.
      // Fall back to streaming the original source URI and log the issue.
      // Caller may still encounter CORS restrictions in the browser console.
      // Return the original URI so audio playback can attempt to stream.
      // ignore: avoid_print
      print(
          'Audio offline cache unavailable, falling back to remote URI: $error');
      return source.uri;
    }
  }

  Future<Uint8List> _downloadBytes(
    Uri uri, {
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final completer = Completer<Uint8List>();
    final request = html.HttpRequest();
    request.open('GET', uri.toString());
    request.responseType = 'arraybuffer';
    request.onProgress.listen((event) {
      if (event.lengthComputable) {
        onProgress?.call(event.loaded!, event.total);
      }
    });
    request.onLoad.listen((_) {
      if (request.status == 200 || request.status == 206) {
        final buffer = request.response as ByteBuffer?;
        if (buffer == null || buffer.lengthInBytes <= 0) {
          completer.completeError(StateError('Empty audio download.'));
          return;
        }
        final bytes = Uint8List.view(buffer);
        onProgress?.call(bytes.length, bytes.length);
        completer.complete(bytes);
      } else {
        completer.completeError(
          StateError('Audio download failed (${request.status}).'),
        );
      }
    });
    request.onError.listen((_) {
      completer.completeError(
        StateError(
          'Could not download audio for offline use. Check your connection.',
        ),
      );
    });
    request.send();
    return completer.future;
  }

  Future<Map<String, int>> _allSizes(dynamic store) async {
    final sizes = <String, int>{};
    final completer = Completer<Map<String, int>>();
    final stream = store.openCursor(autoAdvance: true) as Stream;
    stream.listen(
      (cursor) {
        final key = cursor.key?.toString();
        if (key != null) {
          sizes[key] = _byteLength(cursor.value);
        }
      },
      onDone: () => completer.complete(sizes),
      onError: completer.completeError,
      cancelOnError: true,
    );
    return completer.future;
  }

  Future<void> _evictIfNeeded(int maxBytes, {required String keep}) async {
    try {
      final db = await _openDb();
      final tx = db.transaction(_storeName, 'readwrite');
      final store = tx.objectStore(_storeName);
      final sizes = await _allSizes(store);
      var total = sizes.values.fold<int>(0, (sum, size) => sum + size);
      if (total <= maxBytes) {
        await tx.completed;
        return;
      }
      for (final entry in sizes.entries) {
        if (total <= maxBytes) break;
        if (entry.key == keep) continue;
        store.delete(entry.key);
        total -= entry.value;
      }
      await tx.completed;
    } catch (_) {}
  }

  Uint8List? _asBytes(Object? value) {
    if (value == null) return null;
    if (value is ByteBuffer) return Uint8List.view(value);
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  int _byteLength(Object? value) => _asBytes(value)?.length ?? 0;

  @override
  Future<int> sizeBytes() async {
    try {
      final db = await _openDb();
      final tx = db.transaction(_storeName, 'readonly');
      final store = tx.objectStore(_storeName);
      final sizes = await _allSizes(store);
      await tx.completed;
      return sizes.values.fold<int>(0, (sum, size) => sum + size);
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final factory = html.window.indexedDB;
      if (factory == null) return;
      await factory.deleteDatabase(_dbName);
    } catch (_) {}
  }
}
