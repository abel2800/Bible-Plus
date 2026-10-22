import 'package:bible_pulse/providers/journey_provider.dart';
import 'package:bible_pulse/providers/study_provider.dart';
import 'package:bible_pulse/screens/bible_journey_screen.dart';
import 'package:bible_pulse/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('journey screen exposes goal progress and empty day history',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final audio = AudioService(enabled: false);
    final journey = JourneyProvider(audioService: audio, useSqlite: false);
    await journey.ready;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: journey),
          ChangeNotifierProvider(create: (_) => StudyProvider()),
        ],
        child: MaterialApp(
          home: const BibleJourneyScreen(),
          theme: ThemeData(colorSchemeSeed: const Color(0xFFBD9A4C)),
          darkTheme: ThemeData.dark(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bible Journey'), findsOneWidget);
    expect(find.text('Today’s goal'), findsOneWidget);
    expect(find.byTooltip('Change daily goal'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LinearProgressIndicator)).label,
      contains('Daily minutes goal: 0 of 20 min'),
    );
    final emptyDay =
        find.text('No reading or listening recorded for this day.');
    await tester.scrollUntilVisible(
      emptyDay,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('No reading or listening recorded for this day.'),
        findsOneWidget);

    await journey.recordChapterCompleted(
      bookId: 1,
      bookName: 'Genesis',
      chapter: 1,
    );
    await tester.pump();
    expect(find.text('0 minutes • 1 completed chapters'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    journey.dispose();
    audio.dispose();
  });
}
