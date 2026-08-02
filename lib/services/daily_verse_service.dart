import '../models/bible_verse.dart';
import 'bible_service.dart';

typedef DailyVerseRef = ({int bookId, int chapter, int verse});

class DailyVerseService {
  DailyVerseService({BibleService? bibleService})
      : _bibleService = bibleService ?? BibleService();

  final BibleService _bibleService;

  static int indexForDate(DateTime local) {
    final day = DateTime(local.year, local.month, local.day);
    return day.difference(DateTime(local.year)).inDays;
  }

  static DailyVerseRef refForDate(DateTime local) {
    final refs = catalog;
    return refs[indexForDate(local) % refs.length];
  }

  Future<BibleVerse?> verseForToday({
    String versionId = 'WEB',
    DateTime? now,
  }) {
    return verseForDate(now ?? DateTime.now(), versionId: versionId);
  }

  Future<BibleVerse?> verseForDate(
    DateTime local, {
    String versionId = 'WEB',
  }) async {
    final ref = refForDate(local);
    final chapter = await _bibleService.getChapter(
      versionId,
      ref.bookId,
      ref.chapter,
    );
    if (chapter.isEmpty) return null;
    final match = chapter.where((v) => v.verse == ref.verse);
    return match.isEmpty ? chapter.first : match.first;
  }

  static const List<DailyVerseRef> catalog = [
    (bookId: 1, chapter: 1, verse: 1),
    (bookId: 1, chapter: 1, verse: 27),
    (bookId: 1, chapter: 12, verse: 2),
    (bookId: 1, chapter: 28, verse: 15),
    (bookId: 2, chapter: 14, verse: 14),
    (bookId: 2, chapter: 15, verse: 2),
    (bookId: 2, chapter: 33, verse: 14),
    (bookId: 3, chapter: 19, verse: 18),
    (bookId: 4, chapter: 6, verse: 24),
    (bookId: 5, chapter: 6, verse: 5),
    (bookId: 5, chapter: 31, verse: 6),
    (bookId: 5, chapter: 31, verse: 8),
    (bookId: 6, chapter: 1, verse: 9),
    (bookId: 6, chapter: 24, verse: 15),
    (bookId: 8, chapter: 1, verse: 16),
    (bookId: 9, chapter: 16, verse: 7),
    (bookId: 10, chapter: 22, verse: 31),
    (bookId: 11, chapter: 8, verse: 57),
    (bookId: 13, chapter: 16, verse: 11),
    (bookId: 14, chapter: 7, verse: 14),
    (bookId: 16, chapter: 8, verse: 10),
    (bookId: 18, chapter: 19, verse: 25),
    (bookId: 19, chapter: 1, verse: 1),
    (bookId: 19, chapter: 3, verse: 3),
    (bookId: 19, chapter: 4, verse: 8),
    (bookId: 19, chapter: 16, verse: 11),
    (bookId: 19, chapter: 19, verse: 14),
    (bookId: 19, chapter: 23, verse: 1),
    (bookId: 19, chapter: 23, verse: 4),
    (bookId: 19, chapter: 27, verse: 1),
    (bookId: 19, chapter: 34, verse: 8),
    (bookId: 19, chapter: 37, verse: 4),
    (bookId: 19, chapter: 46, verse: 1),
    (bookId: 19, chapter: 46, verse: 10),
    (bookId: 19, chapter: 51, verse: 10),
    (bookId: 19, chapter: 55, verse: 22),
    (bookId: 19, chapter: 91, verse: 1),
    (bookId: 19, chapter: 91, verse: 11),
    (bookId: 19, chapter: 100, verse: 4),
    (bookId: 19, chapter: 103, verse: 1),
    (bookId: 19, chapter: 118, verse: 24),
    (bookId: 19, chapter: 119, verse: 105),
    (bookId: 19, chapter: 121, verse: 1),
    (bookId: 19, chapter: 121, verse: 7),
    (bookId: 19, chapter: 139, verse: 14),
    (bookId: 19, chapter: 145, verse: 9),
    (bookId: 19, chapter: 150, verse: 6),
    (bookId: 20, chapter: 3, verse: 5),
    (bookId: 20, chapter: 3, verse: 6),
    (bookId: 20, chapter: 4, verse: 23),
    (bookId: 20, chapter: 16, verse: 3),
    (bookId: 20, chapter: 16, verse: 9),
    (bookId: 20, chapter: 18, verse: 10),
    (bookId: 20, chapter: 22, verse: 6),
    (bookId: 21, chapter: 3, verse: 1),
    (bookId: 21, chapter: 3, verse: 11),
    (bookId: 23, chapter: 9, verse: 6),
    (bookId: 23, chapter: 26, verse: 3),
    (bookId: 23, chapter: 40, verse: 8),
    (bookId: 23, chapter: 40, verse: 31),
    (bookId: 23, chapter: 41, verse: 10),
    (bookId: 23, chapter: 43, verse: 2),
    (bookId: 23, chapter: 53, verse: 5),
    (bookId: 23, chapter: 55, verse: 8),
    (bookId: 23, chapter: 55, verse: 9),
    (bookId: 24, chapter: 29, verse: 11),
    (bookId: 25, chapter: 3, verse: 22),
    (bookId: 25, chapter: 3, verse: 23),
    (bookId: 27, chapter: 9, verse: 9),
    (bookId: 29, chapter: 2, verse: 28),
    (bookId: 33, chapter: 6, verse: 8),
    (bookId: 35, chapter: 3, verse: 19),
    (bookId: 36, chapter: 3, verse: 17),
    (bookId: 40, chapter: 5, verse: 9),
    (bookId: 40, chapter: 5, verse: 14),
    (bookId: 40, chapter: 5, verse: 16),
    (bookId: 40, chapter: 6, verse: 9),
    (bookId: 40, chapter: 6, verse: 33),
    (bookId: 40, chapter: 7, verse: 7),
    (bookId: 40, chapter: 11, verse: 28),
    (bookId: 40, chapter: 22, verse: 37),
    (bookId: 40, chapter: 28, verse: 19),
    (bookId: 40, chapter: 28, verse: 20),
    (bookId: 41, chapter: 10, verse: 27),
    (bookId: 41, chapter: 11, verse: 24),
    (bookId: 42, chapter: 1, verse: 37),
    (bookId: 42, chapter: 6, verse: 31),
    (bookId: 42, chapter: 6, verse: 38),
    (bookId: 42, chapter: 12, verse: 31),
    (bookId: 43, chapter: 1, verse: 1),
    (bookId: 43, chapter: 1, verse: 12),
    (bookId: 43, chapter: 3, verse: 16),
    (bookId: 43, chapter: 3, verse: 17),
    (bookId: 43, chapter: 8, verse: 12),
    (bookId: 43, chapter: 8, verse: 32),
    (bookId: 43, chapter: 10, verse: 10),
    (bookId: 43, chapter: 11, verse: 25),
    (bookId: 43, chapter: 14, verse: 1),
    (bookId: 43, chapter: 14, verse: 6),
    (bookId: 43, chapter: 14, verse: 27),
    (bookId: 43, chapter: 15, verse: 5),
    (bookId: 43, chapter: 16, verse: 33),
    (bookId: 44, chapter: 1, verse: 8),
    (bookId: 44, chapter: 16, verse: 31),
    (bookId: 45, chapter: 5, verse: 8),
    (bookId: 45, chapter: 8, verse: 1),
    (bookId: 45, chapter: 8, verse: 28),
    (bookId: 45, chapter: 8, verse: 31),
    (bookId: 45, chapter: 8, verse: 38),
    (bookId: 45, chapter: 8, verse: 39),
    (bookId: 45, chapter: 12, verse: 2),
    (bookId: 45, chapter: 15, verse: 13),
    (bookId: 46, chapter: 10, verse: 13),
    (bookId: 46, chapter: 13, verse: 4),
    (bookId: 46, chapter: 13, verse: 13),
    (bookId: 46, chapter: 15, verse: 58),
    (bookId: 47, chapter: 5, verse: 17),
    (bookId: 47, chapter: 12, verse: 9),
    (bookId: 48, chapter: 2, verse: 20),
    (bookId: 48, chapter: 5, verse: 22),
    (bookId: 48, chapter: 5, verse: 23),
    (bookId: 49, chapter: 2, verse: 8),
    (bookId: 49, chapter: 2, verse: 10),
    (bookId: 49, chapter: 3, verse: 20),
    (bookId: 49, chapter: 4, verse: 32),
    (bookId: 49, chapter: 6, verse: 10),
    (bookId: 50, chapter: 1, verse: 6),
    (bookId: 50, chapter: 4, verse: 6),
    (bookId: 50, chapter: 4, verse: 7),
    (bookId: 50, chapter: 4, verse: 13),
    (bookId: 51, chapter: 3, verse: 12),
    (bookId: 51, chapter: 3, verse: 23),
    (bookId: 52, chapter: 5, verse: 16),
    (bookId: 52, chapter: 5, verse: 17),
    (bookId: 52, chapter: 5, verse: 18),
    (bookId: 55, chapter: 1, verse: 7),
    (bookId: 55, chapter: 3, verse: 16),
    (bookId: 58, chapter: 4, verse: 16),
    (bookId: 58, chapter: 11, verse: 1),
    (bookId: 58, chapter: 12, verse: 1),
    (bookId: 58, chapter: 12, verse: 2),
    (bookId: 58, chapter: 13, verse: 5),
    (bookId: 59, chapter: 1, verse: 2),
    (bookId: 59, chapter: 1, verse: 5),
    (bookId: 59, chapter: 1, verse: 17),
    (bookId: 59, chapter: 4, verse: 7),
    (bookId: 59, chapter: 4, verse: 8),
    (bookId: 60, chapter: 5, verse: 7),
    (bookId: 62, chapter: 1, verse: 9),
    (bookId: 62, chapter: 3, verse: 1),
    (bookId: 62, chapter: 4, verse: 8),
    (bookId: 62, chapter: 4, verse: 19),
    (bookId: 66, chapter: 3, verse: 20),
    (bookId: 66, chapter: 21, verse: 4),
    (bookId: 66, chapter: 21, verse: 5),
  ];
}
