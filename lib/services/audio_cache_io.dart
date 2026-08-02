import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_contracts.dart';
import 'database_service.dart';
import '../models/audio_download.dart';

class PersistentAudioChapterCache implements AudioChapterCache {
  PersistentAudioChapterCache({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;

  List<String> _segments(String cacheKey) => cacheKey
      .split('/')
      .map((part) => part.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_'))
      .where((part) => part.isNotEmpty)
      .toList();

  Future<File> _target(String cacheKey) async {
    final root = Directory(
      '${(await getApplicationSupportDirectory()).path}/audio',
    );
    final target = File(
      '${root.path}/${_segments(cacheKey).join(Platform.pathSeparator)}.audio',
    );
    await target.parent.create(recursive: true);
    return target;
  }

  @override
  Future<Uri?> lookup(String cacheKey, AudioChapterSource source) async {
    final target = await _target(cacheKey);
    if (await _isValid(target, source.sha256)) {
      await target.setLastModified(DateTime.now());
      return target.uri;
    }
    return null;
  }

  @override
  Future<bool> has(String cacheKey) async {
    final target = await _target(cacheKey);
    return _isValid(target, null);
  }

  @override
  Future<Uri> prepare(
    String cacheKey,
    AudioChapterSource source, {
    required int maxBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    if (!source.downloadPermitted) return source.uri;
    final root = Directory(
      '${(await getApplicationSupportDirectory()).path}/audio',
    );
    await root.create(recursive: true);
    final segments = _segments(cacheKey);
    final target = await _target(cacheKey);
    final metadata = File('${target.path}.json');
    if (await target.exists() && await _isValid(target, source.sha256)) {
      await target.setLastModified(DateTime.now());
      return target.uri;
    }

    final temporary = File('${target.path}.part');
    final existingBytes =
        await temporary.exists() ? await temporary.length() : 0;
    final request = await _client.getUrl(source.uri);
    if (existingBytes > 0) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
    }
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Audio download failed with ${response.statusCode}',
        uri: source.uri,
      );
    }
    var received = existingBytes;
    var append =
        existingBytes > 0 && response.statusCode == HttpStatus.partialContent;
    if (!append && await temporary.exists()) {
      await temporary.delete();
      received = 0;
    }
    final total =
        response.contentLength < 0 ? null : received + response.contentLength;
    final sink =
        temporary.openWrite(mode: append ? FileMode.append : FileMode.write);
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
      if (!await _isValid(temporary, source.sha256)) {
        await temporary.delete();
        throw const FormatException('Audio checksum mismatch');
      }
      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);
      await metadata.writeAsString(jsonEncode({
        'filesetId': source.filesetId,
        'attribution': source.attribution,
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'sha256': source.sha256,
      }));
      await _recordDownload(segments, source, target);
      await _evict(root, maxBytes, keep: target.path);
      return target.uri;
    } catch (_) {
      await sink.close();
      rethrow;
    }
  }

  Future<void> _recordDownload(
    List<String> segments,
    AudioChapterSource source,
    File target,
  ) async {
    if (segments.length != 3) return;
    final bookId = int.tryParse(segments[1]);
    final chapter = int.tryParse(segments[2]);
    if (bookId == null || chapter == null) return;
    try {
      await DatabaseService().saveAudioDownload(
        AudioDownload(
          versionId: segments[0],
          filesetId: source.filesetId,
          bookId: bookId,
          chapter: chapter,
          localPath: target.path,
          downloadedAt: DateTime.now().toUtc(),
          fileSize: await target.length(),
          sha256: source.sha256,
        ),
      );
    } catch (_) {}
  }

  @override
  Future<int> sizeBytes() async {
    final root = Directory(
      '${(await getApplicationSupportDirectory()).path}/audio',
    );
    if (!await root.exists()) return 0;
    var total = 0;
    await for (final entry in root.list(recursive: true)) {
      if (entry is File && entry.path.endsWith('.audio')) {
        total += await entry.length();
      }
    }
    return total;
  }

  @override
  Future<void> clear() async {
    final root = Directory(
      '${(await getApplicationSupportDirectory()).path}/audio',
    );
    if (await root.exists()) await root.delete(recursive: true);
    try {
      await DatabaseService().clearAudioDownloads();
    } catch (_) {}
  }

  Future<bool> _isValid(File file, String? expectedHash) async {
    if (!await file.exists() || await file.length() == 0) return false;
    if (expectedHash == null || expectedHash.isEmpty) return true;
    final actual = await sha256.bind(file.openRead()).first;
    return actual.toString().toLowerCase() == expectedHash.toLowerCase();
  }

  Future<void> _evict(
    Directory root,
    int maxBytes, {
    required String keep,
  }) async {
    final files = await root
        .list(recursive: true)
        .where((entry) => entry is File && entry.path.endsWith('.audio'))
        .cast<File>()
        .toList();
    var total = 0;
    final entries = <(File, DateTime, int)>[];
    for (final file in files) {
      final stat = await file.stat();
      total += stat.size;
      entries.add((file, stat.modified, stat.size));
    }
    entries.sort((a, b) => a.$2.compareTo(b.$2));
    for (final entry in entries) {
      if (total <= maxBytes) break;
      if (entry.$1.path == keep) continue;
      await entry.$1.delete();
      final metadata = File('${entry.$1.path}.json');
      if (await metadata.exists()) await metadata.delete();
      total -= entry.$3;
    }
  }
}
