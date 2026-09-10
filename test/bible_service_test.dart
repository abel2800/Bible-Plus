import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_pulse/services/bible_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => null,
    );
  });

  test('loads WEB Genesis chapter 1 from bundled assets', () async {
    final service = BibleService();
    final books = await service.getBooks('WEB');
    expect(books, isNotEmpty);
    expect(books.first.name.toLowerCase(), contains('genesis'));

    final chapter = await service.getChapter('WEB', 1, 1);
    expect(chapter, isNotEmpty);
    expect(chapter.first.text.trim(), isNotEmpty);
    expect(chapter.first.text.toLowerCase(), contains('beginning'));
  });
}
