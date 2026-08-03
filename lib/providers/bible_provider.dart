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

  String get currentVersion => _currentVersion;
  List<BibleBook> get books => _books;
  List<BibleVerse> get currentChapter => _currentChapter;
  BibleBook? get selectedBook => _selectedBook;
  int get selectedChapter => _selectedChapter;
  bool get isLoading => _isLoading;
  List<BibleVerse> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  int? get pendingScrollVerse => _pendingScrollVerse;
  int? get pendingScrollBookId => _pendingScrollBookId;
  int? get pendingScrollChapter => _pendingScrollChapter;

  BibleVerse? get verseOfTheDay => _verseOfTheDay;

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

      final bookId = prefs.getInt('last_read_book') ?? 1;
      final chapter = prefs.getInt('last_read_chapter') ?? 1;
      final verse = prefs.getInt('last_read_verse') ?? 1;
      await loadChapter(bookId, chapter);
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
    _isLoading = true;
    notifyListeners();

    try {
      _books = await _bibleService.getBooks(_currentVersion);
    } catch (e) {
      debugPrint('Error loading books: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChapter(int bookId, int chapter) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentChapter = await _bibleService.getChapter(
        _currentVersion,
        bookId,
        chapter,
      );
      _selectedChapter = chapter;
      _selectedBook = _books.firstWhere((book) => book.id == bookId);
      if (_currentChapter.isNotEmpty) {
        _lastReadVerse = _currentChapter.first;
        await _saveLastRead(_lastReadVerse!);
      }
    } catch (e) {
      debugPrint('Error loading chapter: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> changeVersion(String version) async {
    _currentVersion = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_version', version);
    await prefs.setString('preferred_bible_version', version);
    _bibleService.invalidateCache(version);
    await loadBooks();

    if (_selectedBook != null) {
      await loadChapter(_selectedBook!.id, _selectedChapter);
    } else if (_books.isNotEmpty) {
      await loadChapter(_books.first.id, 1);
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

    await loadChapter(bookId, chapter);
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
