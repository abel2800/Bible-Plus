import 'package:flutter_test/flutter_test.dart';

import 'package:bible_pulse/services/daily_verse_service.dart';
import 'package:bible_pulse/utils/time_of_day_greeting.dart';
import 'package:bible_pulse/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('greeting follows local hour bands', () {
    expect(
      TimeOfDayGreeting.forTime(DateTime(2026, 7, 24, 1), l10n),
      l10n.goodNight,
    );
    expect(
      TimeOfDayGreeting.forTime(DateTime(2026, 7, 24, 8), l10n),
      l10n.goodMorning,
    );
    expect(
      TimeOfDayGreeting.forTime(DateTime(2026, 7, 24, 14), l10n),
      l10n.goodAfternoon,
    );
    expect(
      TimeOfDayGreeting.forTime(DateTime(2026, 7, 24, 19), l10n),
      l10n.goodEvening,
    );
    expect(
      TimeOfDayGreeting.forTime(DateTime(2026, 7, 24, 22), l10n),
      l10n.goodNight,
    );
  });

  test('daily verse index is stable for a local calendar day', () {
    final a = DailyVerseService.refForDate(DateTime(2026, 7, 24, 1));
    final b = DailyVerseService.refForDate(DateTime(2026, 7, 24, 23));
    final c = DailyVerseService.refForDate(DateTime(2026, 7, 25, 0));
    expect(a, b);
    expect(a, isNot(c));
  });
}
