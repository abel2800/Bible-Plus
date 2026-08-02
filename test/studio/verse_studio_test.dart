import 'package:bible_pulse/studio/mood_engine.dart';
import 'package:bible_pulse/studio/studio_fonts.dart';
import 'package:bible_pulse/studio/verse_design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoodEngine', () {
    test('detects love mood for John 3:16', () {
      final mood = MoodEngine.detect(
        'For God so loved the world, that he gave his one and only Son.',
        reference: 'John 3:16',
      );
      expect(mood, VerseMood.love);
    });

    test('detects peace mood for shepherd language', () {
      final mood = MoodEngine.detect(
        'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures.',
        reference: 'Psalm 23:1',
      );
      expect(mood, VerseMood.peace);
    });

    test('applies mood pack fields', () {
      final design = VerseDesign(verseText: 'Be strong and of good courage.');
      design.detectedMood = VerseMood.strength;
      MoodEngine.applyMood(design, VerseMood.strength);
      expect(design.fontId, StudioFontId.bebasNeue);
      expect(design.layout, StudioLayoutPreset.magazine);
    });
  });

  group('SmartVerseFormatter', () {
    test('breaks long verses into lines', () {
      const text =
          'Trust in the Lord with all your heart and lean not on your own understanding';
      final formatted = SmartVerseFormatter.format(text);
      expect(formatted.contains('\n'), isTrue);
      expect(formatted.replaceAll('\n', ' '), text);
    });

    test('leaves short verses intact', () {
      expect(SmartVerseFormatter.format('Jesus wept.'), 'Jesus wept.');
    });
  });
}
