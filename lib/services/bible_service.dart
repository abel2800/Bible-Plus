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
  final Map<String, List<BibleVerse>> _chapterCache = {};
  final Map<String, Map<String, List<BibleVerse>>> _searchIndexes = {};
  final Map<String, List<BibleBook>> _remoteBooksCache = {};

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

      if (!_bibleCache.containsKey(version)) {
        await _loadBibleFromAssets(version);
      }

      final bible = _bibleCache[version];
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
        final bookId = i + 1;
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

        final testament = bookId <= 39 ? 'OT' : 'NT';

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
      return _chapterCache[cacheKey]!;
    }

    try {
      final remote = await _remoteChapter(version, bookId, chapter);
      if (remote != null) {
        _chapterCache[cacheKey] = remote;
        return remote;
      }

      if (!_bibleCache.containsKey(version)) {
        await _loadBibleFromAssets(version);
      }

      final bible = _bibleCache[version];
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

      if (bookId < 1 || bookId > booksJson.length) {
        debugPrint('Book ID $bookId out of range (1-${booksJson.length})');
        return [];
      }

      final bookJson = booksJson[bookId - 1] as Map<String, dynamic>;

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

      final chapterJson = chaptersJson[chapter - 1];

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

  Future<void> _loadBibleFromAssets(String version) async {
    final packagePath = _packageService?.sourceForVersion(version);
    if (packagePath != null) {
      if (packagePath.startsWith('asset:')) {
        final assetPath = packagePath.substring('asset:'.length);
        final jsonString = await rootBundle.loadString(assetPath);
        _bibleCache[version] = json.decode(jsonString) as Map<String, dynamic>;
        return;
      }
      final disk = await fs.readStringIfExists(packagePath);
      if (disk != null) {
        _bibleCache[version] = json.decode(disk) as Map<String, dynamic>;
        return;
      }
    }

    final assetPath = _bundledAssets[version];
    if (assetPath == null) {
      debugPrint('Bible version not installed: $version');
      return;
    }
    final jsonString = await rootBundle.loadString(assetPath);
    _bibleCache[version] = json.decode(jsonString) as Map<String, dynamic>;
  }

  void invalidateCache([String? version]) {
    if (version == null) {
      _bibleCache.clear();
      _chapterCache.clear();
      _searchIndexes.clear();
      _remoteBooksCache.clear();
      return;
    }
    _bibleCache.remove(version);
    _chapterCache.removeWhere((key, _) => key.startsWith('$version-'));
    _searchIndexes.remove(version);
    _remoteBooksCache.remove(version);
  }
}
