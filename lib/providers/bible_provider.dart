import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_verse.dart';
import '../models/bible_book.dart';
import '../services/bible_service.dart';
import '../services/bible_search_service.dart';
import '../services/daily_verse_service.dart';

class BibleProvider with ChangeNotifier {
  BibleProvider({BibleService? bibleService})
      : _bibleService = bibleService ?? BibleService() {
    _searchService = BibleSearchService(bibleService: _bibleService);
    _dailyVerseService = DailyVerseService(bibleService: _bibleService);
    ready = _initialize();
  }

  final BibleService _bibleService;
  List<String> get availableVersions => _bibleService.availableVersions;
  late final BibleSearchService _searchService;
  late final DailyVerseService _dailyVerseService;
  late final Future<void> ready;
  int _searchRequest = 0;
  int _chapterRequest = 0;
  int _bookRequest = 0;
  String? _verseOfTheDayDateKey;

  String _currentVersion = 'WEB';
  List<BibleBook> _books = [];
  List<BibleVerse> _currentChapter = [];
  List<BibleVerse> _searchResults = [];
  bool _isSearching = false;
  int? _pendingScrollVerse;
  int? _pendingScrollBookId;
  int? _pendingScrollChapter;
  BibleBook? _selectedBook;
  int _selectedChapter = 1;
  bool _isLoading = false;
  String? _chapterError;

  String get currentVersion => _currentVersion;
  List<BibleBook> get books => _books;
  List<BibleVerse> get currentChapter => _currentChapter;
  BibleBook? get selectedBook => _selectedBook;
  int get selectedChapter => _selectedChapter;
  bool get isLoading => _isLoading;
  String? get chapterError => _chapterError;
  List<BibleVerse> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  int? get pendingScrollVerse => _pendingScrollVerse;
  int? get pendingScrollBookId => _pendingScrollBookId;
  int? get pendingScrollChapter => _pendingScrollChapter;

  BibleVerse? get verseOfTheDay => _verseOfTheDay;

  BibleVerse? get lastReadVerse => _lastReadVerse;

  BibleVerse? _lastReadVerse;
  BibleVerse? _verseOfTheDay;

  static String _localDateKey([DateTime? now]) {
    final local = now ?? DateTime.now();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentVersion = prefs.getString('preferred_bible_version') ??
        prefs.getString('last_read_version') ??
        'WEB';

    await loadBooks();
    if (_books.isEmpty && _currentVersion != 'WEB') {
      _currentVersion = 'WEB';
      await prefs.setString('preferred_bible_version', 'WEB');
      await loadBooks();
    }
    if (_books.isNotEmpty) {
      await refreshVerseOfTheDay();

      final savedBookId = prefs.getInt('last_read_book') ?? 1;
      final savedBook = _books.where((book) => book.id == savedBookId);
      final book = savedBook.isNotEmpty ? savedBook.first : _books.first;
      final bookId = book.id;
      final chapter =
          (prefs.getInt('last_read_chapter') ?? 1).clamp(1, book.chapters);
      final verse = prefs.getInt('last_read_verse') ?? 1;
      await loadChapter(bookId, chapter, saveProgress: false);
      final verseIndex =
          _currentChapter.indexWhere((item) => item.verse == verse);
      _lastReadVerse = verseIndex == -1
          ? (_currentChapter.isEmpty ? null : _currentChapter.first)
          : _currentChapter[verseIndex];
    }
  }

  Future<void> refreshVerseOfTheDay({bool force = false}) async {
    final key = _localDateKey();
    if (!force && _verseOfTheDay != null && _verseOfTheDayDateKey == key) {
      return;
    }
    try {
      _verseOfTheDay = await _dailyVerseService.verseForToday(
        versionId: _currentVersion,
      );

      if (_verseOfTheDay == null && _currentVersion != 'WEB') {
        _verseOfTheDay = await _dailyVerseService.verseForToday(
          versionId: 'WEB',
        );
      }
      _verseOfTheDayDateKey = key;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading verse of the day: $e');
    }
  }

  Future<void> loadBooks() async {
    final request = ++_bookRequest;
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    List<BibleBook> books = [];
    try {
      books = await _bibleService.getBooks(_currentVersion);
    } catch (e) {
      debugPrint('Error loading books: $e');
    }

    if (request != _bookRequest) return;
    _books = books;
    if (_books.isNotEmpty &&
        !_books.any((book) => book.id == _selectedBook?.id)) {
      _selectedBook = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loadChapter(
    int bookId,
    int chapter, {
    bool saveProgress = true,
  }) async {
    final bookIndex = _books.indexWhere((book) => book.id == bookId);
    if (bookIndex == -1) return false;
    final book = _books[bookIndex];
    if (chapter < 1 || chapter > book.chapters) return false;
    if (_selectedBook?.id == bookId &&
        _selectedChapter == chapter &&
        _currentChapter.isNotEmpty) {
      return true;
    }

    final request = ++_chapterRequest;
    final version = _currentVersion;
    _chapterError = null;
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final verses = await _bibleService.getChapter(
        version,
        bookId,
        chapter,
      );
      if (request != _chapterRequest || version != _currentVersion) {
        return false;
      }
      if (verses.isEmpty) {
        _chapterError = 'This chapter is currently unavailable.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _currentChapter = verses;
      _selectedChapter = chapter;
      _selectedBook = book;
      if (saveProgress && _currentChapter.isNotEmpty) {
        _lastReadVerse = _currentChapter.first;
        await _saveLastRead(_lastReadVerse!);
      }
    } catch (e) {
      debugPrint('Error loading chapter: $e');
      _chapterError = 'This chapter could not be loaded.';
    }

    if (request != _chapterRequest || version != _currentVersion) return false;
    _isLoading = false;
    notifyListeners();
    return _currentChapter.isNotEmpty &&
        _selectedBook?.id == bookId &&
        _selectedChapter == chapter;
  }

  Future<void> changeVersion(String version) async {
    if (version == _currentVersion) return;
    ++_chapterRequest;
    final previousBookId = _selectedBook?.id;
    final previousChapter = _selectedChapter;
    _currentVersion = version;
    _currentChapter = [];
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_version', version);
    await prefs.setString('preferred_bible_version', version);
    _bibleService.invalidateCache(version);
    await loadBooks();

    if (_books.isNotEmpty) {
      final matchingBook = _books.where((book) => book.id == previousBookId);
      final book = matchingBook.isNotEmpty ? matchingBook.first : _books.first;
      final targetChapter = previousChapter.clamp(1, book.chapters);
      await loadChapter(book.id, targetChapter);
    }
    await refreshVerseOfTheDay(force: true);
  }

  Future<void> nextChapter() async {
    if (_selectedBook == null) return;

    if (_selectedChapter < _selectedBook!.chapters) {
      await loadChapter(_selectedBook!.id, _selectedChapter + 1);
    } else {
      final currentIndex = _books.indexOf(_selectedBook!);
      if (currentIndex < _books.length - 1) {
        await loadChapter(_books[currentIndex + 1].id, 1);
      }
    }
  }

  Future<void> searchVerses(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      clearSearch();
      return;
    }
    final request = ++_searchRequest;
    _isSearching = true;
    _searchResults = [];
    notifyListeners();

    try {
      final results = await _searchService.search(
        _currentVersion,
        normalizedQuery,
        limit: 200,
      );
      if (request == _searchRequest) {
        _searchResults = results;
      }
    } catch (e) {
      debugPrint('Error during search: $e');
    }

    if (request == _searchRequest) {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchRequest++;
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  Future<void> goToVerse(int bookId, int chapter, int verse) async {
    _pendingScrollBookId = bookId;
    _pendingScrollChapter = chapter;
    _pendingScrollVerse = verse;
    notifyListeners();

    await loadChapter(bookId, chapter, saveProgress: false);
    final index = _currentChapter.indexWhere((item) => item.verse == verse);
    if (index != -1) {
      _lastReadVerse = _currentChapter[index];
      await _saveLastRead(_lastReadVerse!);
    }
  }

  Future<void> _saveLastRead(BibleVerse verse) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('last_read_book', verse.book),
      prefs.setInt('last_read_chapter', verse.chapter),
      prefs.setInt('last_read_verse', verse.verse),
      prefs.setString('last_read_version', _currentVersion),
    ]);
  }

  void clearPendingScroll() {
    _pendingScrollVerse = null;
    _pendingScrollBookId = null;
    _pendingScrollChapter = null;
    notifyListeners();
  }

  Future<void> previousChapter() async {
    if (_selectedBook == null) return;

    if (_selectedChapter > 1) {
      await loadChapter(_selectedBook!.id, _selectedChapter - 1);
    } else {
      final currentIndex = _books.indexOf(_selectedBook!);
      if (currentIndex > 0) {
        final prevBook = _books[currentIndex - 1];
        await loadChapter(prevBook.id, prevBook.chapters);
      }
    }
  }

  String getVerseReference(BibleVerse verse) {
    final index = _books.indexWhere((book) => book.id == verse.book);
    if (index == -1) return '${verse.book} ${verse.chapter}:${verse.verse}';
    return '${_books[index].name} ${verse.chapter}:${verse.verse}';
  }
}
