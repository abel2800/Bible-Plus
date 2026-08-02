import 'package:bible_pulse/services/bible_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BibleService WEB asset', () {
    final service = BibleService();

    test('loads the complete canonical book list', () async {
      final books = await service.getBooks('WEB');

      expect(books, hasLength(66));
      expect(books.first.name, 'Genesis');
      expect(books.last.name, 'Revelation');
    });

    test('loads verified Scripture without placeholder text', () async {
      final verses = await service.getChapter('WEB', 1, 1);

      expect(verses, hasLength(31));
      expect(verses.first.text, startsWith('In the beginning'));
      expect(
        verses.any((verse) => verse.text.contains('being loaded')),
        isFalse,
      );
    });

    test('builds and queries the in-memory web search index', () async {
      final results = await service.searchIndexed(
        'WEB',
        'In the beginning',
        limit: 10,
      );

      expect(results, isNotEmpty);
      expect(results.first.book, 1);
      expect(results.first.chapter, 1);
      expect(results.first.verse, 1);
    });
  });
}
