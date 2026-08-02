import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_verse.dart';
import '../services/bible_service.dart';

class ParallelReadingProvider extends ChangeNotifier {
  ParallelReadingProvider({BibleService? bibleService})
      : _bibleService = bibleService ?? BibleService();

  final BibleService _bibleService;
  bool _available = false;
  bool _enabled = false;
  bool _loading = false;
  List<BibleVerse> _secondaryChapter = const [];

  bool get available => _available;
  bool get enabled => _enabled && _available;
  bool get loading => _loading;
  List<BibleVerse> get secondaryChapter => _secondaryChapter;

  Future<void> initialize() async {
    try {
      _available = _bibleService.availableVersions.contains('AMH');
    } catch (_) {
      _available = false;
    }
    final preferences = await SharedPreferences.getInstance();
    _enabled = _available &&
        (preferences.getBool('parallel_reading_enabled') ?? false);
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value && _available;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('parallel_reading_enabled', _enabled);
    notifyListeners();
  }

  Future<void> loadChapter(int bookId, int chapter) async {
    if (!enabled) {
      _secondaryChapter = const [];
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _secondaryChapter = await _bibleService.getChapter(
        'AMH',
        bookId,
        chapter,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  BibleVerse? verse(int verseNumber) {
    final index = _secondaryChapter.indexWhere(
      (item) => item.verse == verseNumber,
    );
    return index == -1 ? null : _secondaryChapter[index];
  }
}
