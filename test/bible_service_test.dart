import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_pulse/models/bible_book.dart';
import 'package:bible_pulse/models/bible_verse.dart';
import 'package:bible_pulse/providers/bible_provider.dart';
import 'package:bible_pulse/providers/color_theme_provider.dart';
import 'package:bible_pulse/services/bible_service.dart';
import 'package:bible_pulse/widgets/book_selector_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads WEB Genesis chapter 1 from bundled assets', () async {
    SharedPreferences.setMockInitialValues({});
    final service = BibleService();
    final books = await service.getBooks('WEB');
    expect(books, isNotEmpty);
    expect(books.first.name.toLowerCase(), contains('genesis'));
    expect(books.first.testament, 'OT');
    expect(books.first.chapters, 50);
    expect(books.last.testament, 'NT');
    expect(books.last.chapters, 22);

    final results = await Future.wait([
      service.getChapter('WEB', 1, 1),
      service.getChapter('WEB', 1, 1),
    ]);
    final chapter = results.first;
    expect(chapter, isNotEmpty);
    expect(chapter.first.text.trim(), isNotEmpty);
    expect(chapter.first.text.toLowerCase(), contains('beginning'));
    expect(identical(results[0], results[1]), isTrue);
    expect(identical(chapter, await service.getChapter('WEB', 1, 1)), isTrue);
  });

  testWidgets('inline book accordion opens the tapped chapter', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final bible = BibleProvider(bibleService: _SelectorBibleService());
    await bible.ready;
    final colors = ColorThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bible),
          ChangeNotifierProvider.value(value: colors),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BookSelectorBottomSheet()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Old Testament'), findsOneWidget);
    expect(find.text('New Testament'), findsOneWidget);
    expect(find.text('Genesis chapters'), findsNothing);
    await tester.ensureVisible(find.text('Joshua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joshua'));
    await tester.pump();
    final joshuaChapters = find.text('Joshua chapters');
    expect(joshuaChapters, findsOneWidget);
    expect(
      tester.getTopLeft(joshuaChapters).dy,
      lessThan(tester.getTopLeft(find.text('Amos')).dy),
    );
    await tester.ensureVisible(find.text('Genesis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genesis'));
    await tester.pump();

    await tester.ensureVisible(find.text('New Testament'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Testament'));
    await tester.pump();
    expect(find.text('Matthew'), findsOneWidget);
    await tester.ensureVisible(find.text('Old Testament'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Old Testament'));
    await tester.pump();

    await tester.ensureVisible(find.text('Genesis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genesis'));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    final chapterTwo = find.text('2').last;
    expect(chapterTwo, findsOneWidget);
    await tester.tap(chapterTwo);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(bible.selectedBook?.name, 'Genesis');
    expect(bible.selectedChapter, 2);
    expect(bible.currentChapter.first.verse, 1);
    expect(bible.currentChapter.first.text, 'Genesis chapter 2 verse 1');
  });
}

class _SelectorBibleService extends BibleService {
  static final _books = [
    BibleBook(id: 1, name: 'Genesis', chapters: 3, testament: 'OT'),
    BibleBook(id: 2, name: 'Exodus', chapters: 2, testament: 'OT'),
    BibleBook(id: 3, name: 'Leviticus', chapters: 27, testament: 'OT'),
    BibleBook(id: 4, name: 'Numbers', chapters: 36, testament: 'OT'),
    BibleBook(id: 5, name: 'Deuteronomy', chapters: 34, testament: 'OT'),
    BibleBook(id: 6, name: 'Joshua', chapters: 24, testament: 'OT'),
    BibleBook(id: 7, name: 'Judges', chapters: 21, testament: 'OT'),
    BibleBook(id: 8, name: 'Ruth', chapters: 4, testament: 'OT'),
    BibleBook(id: 9, name: 'Amos', chapters: 9, testament: 'OT'),
    BibleBook(id: 40, name: 'Matthew', chapters: 2, testament: 'NT'),
  ];

  @override
  List<String> get availableVersions => const ['WEB'];

  @override
  Future<List<BibleBook>> getBooks(String version) async => _books;

  @override
  Future<List<BibleVerse>> getChapter(
    String version,
    int bookId,
    int chapter,
  ) async =>
      [
        BibleVerse(
          id: 1,
          book: bookId,
          chapter: chapter,
          verse: 1,
          text: '${_books.firstWhere((book) => book.id == bookId).name} '
              'chapter $chapter verse 1',
        ),
      ];
}
