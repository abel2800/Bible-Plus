import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../config/youversion_config.dart';
import 'bible_books.dart';
import 'youversion_api_client.dart';

class DownloadProgress {
  const DownloadProgress({
    required this.chaptersDone,
    required this.chaptersTotal,
    required this.currentBook,
    required this.currentChapter,
  });

  final int chaptersDone;
  final int chaptersTotal;
  final String currentBook;
  final int currentChapter;

  double get fraction => chaptersTotal == 0 ? 0 : chaptersDone / chaptersTotal;
}

class BibleDownloadCancelledException implements Exception {}

class YouVersionBibleDownloadService {
  YouVersionBibleDownloadService({YouVersionApiClient? client})
      : _client = client ?? YouVersionApiClient();

  final YouVersionApiClient _client;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<Directory> _versionDir(int versionId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/youversion_bibles/$versionId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _progressFile(int versionId) async {
    final dir = await _versionDir(versionId);
    return File('${dir.path}/_progress.json');
  }

  Future<Set<String>> _loadCompletedChapters(int versionId) async {
    final file = await _progressFile(versionId);
    if (!await file.exists()) return <String>{};

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is List) {
        return raw.cast<String>().toSet();
      }
    } catch (_) {
      return <String>{};
    }
    return <String>{};
  }

  Future<void> _saveCompletedChapters(int versionId, Set<String> done) async {
    final file = await _progressFile(versionId);
    await file.writeAsString(jsonEncode(done.toList()));
  }

  Map<String, dynamic> _normalizeChapterJson(Map<String, dynamic> raw) {
    if (raw['verses'] is List) {
      return {'verses': raw['verses'], 'raw': null};
    }
    if (raw['data'] is Map && (raw['data'] as Map)['verses'] is List) {
      final data = raw['data'] as Map<String, dynamic>;
      return {'verses': data['verses'], 'raw': null};
    }
    if (raw['content'] is String) {
      return {'verses': null, 'content': raw['content'], 'raw': null};
    }

    return {'verses': null, 'content': null, 'raw': raw};
  }

  Future<void> downloadFullBible({
    required int versionId,
    void Function(DownloadProgress progress)? onProgress,
    void Function(String bookUsfm)? onBookComplete,
    void Function(String usfmRef, Object error)? onChapterError,
  }) async {
    if (!YouVersionConfig.licenseConfirmedForBulkDownload) {
      throw StateError(
        'YOUVERSION_BULK_DOWNLOAD_LICENSED is not set. Confirm the license '
        'for this Bible version at platform.youversion.com/bibles permits '
        'full offline bulk download before enabling this.',
      );
    }
    if (versionId <= 0) {
      throw ArgumentError('Invalid versionId: $versionId');
    }

    final completed = await _loadCompletedChapters(versionId);
    final dir = await _versionDir(versionId);
    final total = kTotalChapterCount;
    var done = completed.length;

    for (final book in kProtestantCanon) {
      final bookFile = File('${dir.path}/${book.usfm}.json');
      Map<String, dynamic> bookData = {};
      if (await bookFile.exists()) {
        try {
          bookData =
              jsonDecode(await bookFile.readAsString()) as Map<String, dynamic>;
        } catch (_) {
          bookData = <String, dynamic>{};
        }
      }

      bookData.putIfAbsent('book', () => book.usfm);
      bookData.putIfAbsent('chapters', () => <String, dynamic>{});
      final chapters =
          bookData['chapters'] as Map<String, dynamic>? ?? <String, dynamic>{};
      bookData['chapters'] = chapters;

      var bookHadNewWork = false;

      for (var chapterNumber = 1;
          chapterNumber <= book.chapterCount;
          chapterNumber++) {
        if (_cancelled) {
          await _saveCompletedChapters(versionId, completed);
          throw BibleDownloadCancelledException();
        }

        final reference = '${book.usfm}.$chapterNumber';
        if (completed.contains(reference)) {
          continue;
        }

        try {
          final raw = await _client.getPassage(
            versionId: versionId,
            usfmReference: reference,
          );
          chapters['$chapterNumber'] = _normalizeChapterJson(raw);
          completed.add(reference);
          done++;
          bookHadNewWork = true;

          await bookFile.writeAsString(jsonEncode(bookData));
          await _saveCompletedChapters(versionId, completed);

          onProgress?.call(
            DownloadProgress(
              chaptersDone: done,
              chaptersTotal: total,
              currentBook: book.usfm,
              currentChapter: chapterNumber,
            ),
          );
        } catch (error) {
          onChapterError?.call(reference, error);
        }
      }

      final bookExists = await bookFile.exists();
      if (bookHadNewWork || (bookExists && (await bookFile.length()) > 0)) {
        onBookComplete?.call(book.usfm);
      }
    }
  }

  void dispose() => _client.close();
}
