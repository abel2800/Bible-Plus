import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/bible_verse.dart';
import '../models/bible_book.dart';
import 'bible_brain_text_service.dart';
import 'bible_brain_version_registry.dart';
import 'bible_package_io.dart' if (dart.library.html) 'bible_package_web.dart'
    as fs;
import 'bible_package_service.dart';

class BibleService {
  BibleService({
    BiblePackageService? packageService,
    BibleBrainTextGateway? brainText,
    BibleBrainVersionRegistry? brainVersions,
  })  : _packageService = packageService,
        _brainText = brainText,
        _brainVersions = brainVersions;

  final BiblePackageService? _packageService;
  final BibleBrainTextGateway? _brainText;
  final BibleBrainVersionRegistry? _brainVersions;
  final Map<String, Map<String, dynamic>> _bibleCache = {};
  final Map<String, Future<Map<String, dynamic>?>> _bibleLoads = {};
  final Map<String, List<BibleVerse>> _chapterCache = {};
  final Map<String, Future<List<BibleVerse>>> _chapterLoads = {};
  final Map<String, Map<String, List<BibleVerse>>> _searchIndexes = {};
  final Map<String, List<BibleBook>> _remoteBooksCache = {};
  static const _maxCachedVersions = 2;
  static const _maxCachedChapters = 24;

  final Map<String, String> _bundledAssets = {
    'WEB': 'assets/bible/web.json',
  };

  List<String> get availableVersions {
    final fromPackages = _packageService?.installedVersionIds ?? const [];
    final fromBrain = _brainVersions?.all.keys ?? const <String>[];
    final set = {..._bundledAssets.keys, ...fromPackages, ...fromBrain};
    return set.toList()..sort();
  }

  Future<List<BibleBook>> getBooks(String version) async {
    try {
      final remoteBooks = await _remoteBooks(version);
      if (remoteBooks != null) return remoteBooks;

      final bible = await _loadBible(version);

      if (bible == null || !bible.containsKey('books')) {
        return [];
      }

      List<BibleBook> books = [];
      final booksRaw = bible['books'];

      List<dynamic> booksJson;
      if (booksRaw is List) {
        booksJson = booksRaw;
      } else if (booksRaw is Map) {
        booksJson = booksRaw.values.toList();
      } else {
        return [];
      }

      for (int i = 0; i < booksJson.length; i++) {
        final bookJson = booksJson[i] as Map<String, dynamic>;
        final bookId =
            int.tryParse((bookJson['id'] ?? (i + 1)).toString()) ?? (i + 1);
        final bookName =
            (bookJson['name'] ?? bookJson['title'] ?? 'Book $bookId')
                .toString();

        final rawChapters = bookJson['chapters'];
        int chapterCount = 0;
        if (rawChapters is List) {
          chapterCount = rawChapters.length;
        } else if (rawChapters is Map) {
          chapterCount = rawChapters.length;
        }

        final testament =
            (bookJson['testament'] ?? (bookId <= 39 ? 'OT' : 'NT'))
                .toString()
                .toUpperCase();

        books.add(BibleBook(
          id: bookId,
          name: bookName,
          chapters: chapterCount,
          testament: testament,
        ));
      }

      return books;
    } catch (e) {
      debugPrint('Error loading books: $e');
      return [];
    }
  }

  Future<List<BibleVerse>> getChapter(
      String version, int bookId, int chapter) async {
    final cacheKey = '$version-$bookId-$chapter';

    if (_chapterCache.containsKey(cacheKey)) {
      final cached = _chapterCache.remove(cacheKey)!;
      _chapterCache[cacheKey] = cached;
      return cached;
    }

    final pending = _chapterLoads[cacheKey];
    if (pending != null) return pending;

    final load = _loadChapter(version, bookId, chapter, cacheKey);
    _chapterLoads[cacheKey] = load;
    try {
      return await load;
    } finally {
      if (identical(_chapterLoads[cacheKey], load)) {
        _chapterLoads.remove(cacheKey);
      }
    }
  }

  Future<List<BibleVerse>> _loadChapter(
    String version,
    int bookId,
    int chapter,
    String cacheKey,
  ) async {
    try {
      final remote = await _remoteChapter(version, bookId, chapter);
      if (remote != null && remote.isNotEmpty) {
        _chapterCache[cacheKey] = remote;
        _trimChapterCache();
        return remote;
      }

      final bible = await _loadBible(version);
      if (bible == null || !bible.containsKey('books')) {
        return [];
      }

      final booksRaw = bible['books'];
      List<dynamic> booksJson;
      if (booksRaw is List) {
        booksJson = booksRaw;
      } else if (booksRaw is Map) {
        booksJson = booksRaw.values.toList();
      } else {
        return [];
      }

      final bookIndex = booksJson.indexWhere((value) {
        if (value is! Map) return false;
        return int.tryParse((value['id'] ?? '').toString()) == bookId;
      });
      final resolvedBookIndex = bookIndex == -1 ? bookId - 1 : bookIndex;
      if (resolvedBookIndex < 0 || resolvedBookIndex >= booksJson.length) {
        debugPrint('Book ID $bookId out of range (1-${booksJson.length})');
        return [];
      }

      final bookJson = booksJson[resolvedBookIndex] as Map<String, dynamic>;

      final rawChapters = bookJson['chapters'];
      List<dynamic> chaptersJson = [];
      if (rawChapters is List) {
        chaptersJson = rawChapters;
      } else if (rawChapters is Map) {
        try {
          final keys = rawChapters.keys.toList();
          keys.sort((a, b) {
            final ai = int.tryParse(a.toString()) ?? 0;
            final bi = int.tryParse(b.toString()) ?? 0;
            return ai.compareTo(bi);
          });
          for (var k in keys) {
            chaptersJson.add(rawChapters[k]);
          }
        } catch (_) {
          chaptersJson = rawChapters.values.toList();
        }
      }

      if (chapter < 1 || chapter > chaptersJson.length) {
        debugPrint(
            'Chapter $chapter out of range (1-${chaptersJson.length}) for book $bookId');
        return [];
      }

      final chapterIndex = chaptersJson.indexWhere((value) {
        if (value is! Map || value['number'] == null) return false;
        return int.tryParse(value['number'].toString()) == chapter;
      });
      final resolvedChapterIndex =
          chapterIndex == -1 ? chapter - 1 : chapterIndex;
      if (resolvedChapterIndex < 0 ||
          resolvedChapterIndex >= chaptersJson.length) {
        return [];
      }
      final chapterJson = chaptersJson[resolvedChapterIndex];

      List<BibleVerse> verses = [];
      if (chapterJson == null) {
        return [];
      }

      dynamic versesRaw;
      if (chapterJson is Map && chapterJson.containsKey('verses')) {
        versesRaw = chapterJson['verses'];
      } else {
        versesRaw = chapterJson;
      }

      if (versesRaw is List) {
        for (int i = 0; i < versesRaw.length; i++) {
          final v = versesRaw[i];
          if (v is Map) {
            final intVerse = (v['verse'] ?? v['id'] ?? (i + 1)) as dynamic;
            final intVerseNum = int.tryParse(intVerse.toString()) ?? (i + 1);
            verses.add(BibleVerse(
              id: intVerseNum,
              book: bookId,
              chapter: chapter,
              verse: intVerseNum,
              text:
                  (v['text'] ?? v['verse_text'] ?? v['content'] ?? v.toString())
                      .toString(),
            ));
          } else {
            verses.add(BibleVerse(
              id: i + 1,
              book: bookId,
              chapter: chapter,
              verse: i + 1,
              text: v.toString(),
            ));
          }
        }
      } else if (versesRaw is Map) {
        final keys = versesRaw.keys.toList();
        keys.sort((a, b) {
          final ai = int.tryParse(a.toString()) ?? 0;
          final bi = int.tryParse(b.toString()) ?? 0;
          return ai.compareTo(bi);
        });
        for (var k in keys) {
          final text = versesRaw[k];
          final vnum = int.tryParse(k.toString()) ?? 0;
          verses.add(BibleVerse(
            id: vnum,
            book: bookId,
            chapter: chapter,
            verse: vnum,
            text: text.toString(),
          ));
        }
      } else {
        return [];
      }

      _chapterCache[cacheKey] = verses;
      _trimChapterCache();
      return verses;
    } catch (e) {
      debugPrint('Error loading chapter: $e');
      return [];
    }
  }

  Future<List<BibleVerse>> getAllVerses(String version) async {
    final books = await getBooks(version);
    final verses = <BibleVerse>[];
    for (final book in books) {
      for (var chapter = 1; chapter <= book.chapters; chapter++) {
        verses.addAll(await getChapter(version, book.id, chapter));
      }
    }
    return verses;
  }

  Future<List<BibleVerse>> searchIndexed(
    String version,
    String query, {
    int limit = 100,
  }) async {
    final queryTokens = _tokens(query);
    if (queryTokens.isEmpty) return [];

    if (_brainVersions?.bibleIdFor(version) != null &&
        !_bibleCache.containsKey(version) &&
        _packageService?.sourceForVersion(version) == null &&
        !_bundledAssets.containsKey(version)) {
      return [];
    }

    var index = _searchIndexes[version];
    if (index == null) {
      index = <String, List<BibleVerse>>{};
      for (final verse in await getAllVerses(version)) {
        for (final token in _tokens(verse.text).toSet()) {
          index.putIfAbsent(token, () => []).add(verse);
        }
      }
      _searchIndexes[version] = index;
    }

    Set<String>? matchingKeys;
    final byKey = <String, BibleVerse>{};
    for (final token in queryTokens) {
      final tokenMatches = index.entries
          .where((entry) => entry.key.startsWith(token))
          .expand((entry) => entry.value)
          .toList();
      final keys = <String>{};
      for (final verse in tokenMatches) {
        final key = '${verse.book}:${verse.chapter}:${verse.verse}';
        keys.add(key);
        byKey[key] = verse;
      }
      matchingKeys =
          matchingKeys == null ? keys : matchingKeys.intersection(keys);
      if (matchingKeys.isEmpty) return [];
    }

    final results = matchingKeys!.map((key) => byKey[key]!).toList()
      ..sort((a, b) {
        final bookComparison = a.book.compareTo(b.book);
        if (bookComparison != 0) return bookComparison;
        final chapterComparison = a.chapter.compareTo(b.chapter);
        if (chapterComparison != 0) return chapterComparison;
        return a.verse.compareTo(b.verse);
      });
    if (results.length <= limit) return results;
    return results.take(limit).toList();
  }

  List<String> _tokens(String text) {
    return RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(text.toLowerCase())
        .map((match) => match.group(0)!)
        .where((token) => token.isNotEmpty)
        .toList();
  }

  Future<List<BibleBook>?> _remoteBooks(String version) async {
    final bibleId = _brainVersions?.bibleIdFor(version);
    final text = _brainText;
    if (bibleId == null || text == null) return null;
    if (_remoteBooksCache.containsKey(version)) {
      return _remoteBooksCache[version];
    }
    final books = await text.books(bibleId);
    if (books.isEmpty) return null;
    _remoteBooksCache[version] = books;
    return books;
  }

  Future<List<BibleVerse>?> _remoteChapter(
    String version,
    int bookId,
    int chapter,
  ) async {
    final bibleId = _brainVersions?.bibleIdFor(version);
    final text = _brainText;
    if (bibleId == null || text == null) return null;
    return text.chapter(
      bibleId: bibleId,
      bookId: bookId,
      chapter: chapter,
    );
  }

  Future<Map<String, dynamic>?> _loadBible(String version) async {
    final cached = _bibleCache[version];
    if (cached != null) {
      _bibleCache.remove(version);
      _bibleCache[version] = cached;
      return cached;
    }
    final pending = _bibleLoads[version];
    if (pending != null) return pending;

    final load = _loadBibleFromAssets(version);
    _bibleLoads[version] = load;
    try {
      return await load;
    } finally {
      if (identical(_bibleLoads[version], load)) _bibleLoads.remove(version);
    }
  }

  Future<Map<String, dynamic>?> _loadBibleFromAssets(String version) async {
    final packagePath = _packageService?.sourceForVersion(version);
    if (packagePath != null) {
      if (packagePath.startsWith('asset:')) {
        var assetPath = packagePath.substring('asset:'.length);
        // On web the asset loader will prefix with `assets/` automatically.
        // If the stored path already includes `assets/`, strip it to avoid
        // requesting `/assets/assets/...` which returns 404.
        assetPath = assetPath.replaceFirst(RegExp(r'^/'), '');
        if (assetPath.startsWith('assets/')) {
          assetPath = assetPath.substring('assets/'.length);
        }
        final jsonString = await rootBundle.loadString(assetPath);
        final decoded = await compute(_decodeBibleJson, jsonString);
        _bibleCache[version] = decoded;
        _trimVersionCache(version);
        return decoded;
      }
      final disk = await fs.readStringIfExists(packagePath);
      if (disk != null) {
        final decoded = await compute(_decodeBibleJson, disk);
        _bibleCache[version] = decoded;
        _trimVersionCache(version);
        return decoded;
      }
    }

    final assetPath = _bundledAssets[version];
    if (assetPath == null) {
      debugPrint('Bible version not installed: $version');
      return null;
    }
    final jsonString = await rootBundle.loadString(assetPath);
    final decoded = await compute(_decodeBibleJson, jsonString);
    _bibleCache[version] = decoded;
    _trimVersionCache(version);
    return decoded;
  }

  void _trimVersionCache(String keepVersion) {
    while (_bibleCache.length > _maxCachedVersions) {
      final oldest = _bibleCache.keys.firstWhere(
        (version) => version != keepVersion,
        orElse: () => _bibleCache.keys.first,
      );
      _bibleCache.remove(oldest);
      _chapterCache.removeWhere((key, _) => key.startsWith('$oldest-'));
      _searchIndexes.remove(oldest);
    }
  }

  void _trimChapterCache() {
    while (_chapterCache.length > _maxCachedChapters) {
      _chapterCache.remove(_chapterCache.keys.first);
    }
  }

  void invalidateCache([String? version]) {
    if (version == null) {
      _bibleCache.clear();
      _bibleLoads.clear();
      _chapterCache.clear();
      _chapterLoads.clear();
      _searchIndexes.clear();
      _remoteBooksCache.clear();
      return;
    }
    _bibleCache.remove(version);
    _bibleLoads.remove(version);
    _chapterCache.removeWhere((key, _) => key.startsWith('$version-'));
    _chapterLoads.removeWhere((key, _) => key.startsWith('$version-'));
    _searchIndexes.remove(version);
    _remoteBooksCache.remove(version);
  }
}

Map<String, dynamic> _decodeBibleJson(String source) =>
    json.decode(source) as Map<String, dynamic>;
