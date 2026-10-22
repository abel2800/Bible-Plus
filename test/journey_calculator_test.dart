import 'package:flutter_test/flutter_test.dart';
import 'package:bible_pulse/models/journey_session.dart';
import 'package:bible_pulse/services/journey_calculator.dart';

JourneySession session({
  required String id,
  required DateTime startedAt,
  required int seconds,
  JourneySessionType type = JourneySessionType.reading,
  int chapters = 0,
  DateTime? updatedAt,
}) {
  final stamp = updatedAt ?? startedAt.toUtc();
  return JourneySession(
    id: id,
    ownerId: 'guest',
    type: type,
    startedAt: startedAt.toUtc(),
    endedAt: startedAt.toUtc().add(Duration(seconds: seconds)),
    durationSeconds: seconds,
    createdAt: stamp,
    updatedAt: stamp,
    bookId: 1,
    bookName: 'Genesis',
    chapter: 1,
    completedChapters: chapters,
  );
}

void main() {
  group('JourneyCalculator', () {
    test('empty history has no activity or streak', () {
      final result = JourneyCalculator.calculate(
        const [],
        now: DateTime(2026, 10, 22),
      );

      expect(result.activeDays, 0);
      expect(result.totalSeconds, 0);
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(
          JourneyCalculator.activityLevel(result.day(DateTime(2026, 1, 1))), 0);
    });

    test('multiple reading and listening sessions aggregate on one day', () {
      final date = DateTime(2026, 3, 8, 9);
      final result = JourneyCalculator.calculate([
        session(id: 'read', startedAt: date, seconds: 180),
        session(
          id: 'listen',
          startedAt: date.add(const Duration(hours: 2)),
          seconds: 420,
          type: JourneySessionType.listening,
          chapters: 1,
        ),
      ], now: date.add(const Duration(hours: 3)));

      final day = result.day(date);
      expect(day.readingSeconds, 180);
      expect(day.listeningSeconds, 420);
      expect(day.completedChapters, 1);
      expect(day.totalMinutes, 10);
      expect(result.activeDays, 1);
      expect(result.totalSeconds, 600);
    });

    test('session duration is split across local calendar midnight', () {
      final start = DateTime(2026, 1, 2, 23, 59, 30);
      final result = JourneyCalculator.calculate([
        session(id: 'midnight', startedAt: start, seconds: 90),
      ], now: start.add(const Duration(days: 1)));

      expect(result.day(start).readingSeconds, 30);
      expect(result.day(DateTime(2026, 1, 3)).readingSeconds, 60);
      expect(result.activeDays, 2);
      expect(result.currentStreak, 2);
    });

    test('duplicate IDs keep the latest updated session', () {
      final start = DateTime(2026, 4, 1, 10);
      final result = JourneyCalculator.calculate([
        session(id: 'same', startedAt: start, seconds: 120),
        session(
          id: 'same',
          startedAt: start,
          seconds: 300,
          updatedAt: start.add(const Duration(minutes: 2)),
        ),
      ], now: start.add(const Duration(minutes: 10)));

      expect(result.totalSeconds, 300);
      expect(result.day(start).readingSeconds, 300);
    });

    test('activity levels use documented minute thresholds', () {
      final start = DateTime(2026, 5, 1, 12);
      final levels = [59, 60, 300, 900, 1800].map((seconds) {
        final result = JourneyCalculator.calculate([
          session(
            id: '$seconds',
            startedAt: start,
            seconds: seconds,
          ),
        ]);
        return JourneyCalculator.activityLevel(result.day(start));
      }).toList();

      expect(levels, [1, 1, 2, 3, 4]);
    });

    test('current streak includes today or yesterday, longest breaks on gaps',
        () {
      final today = DateTime(2026, 6, 10, 12);
      final result = JourneyCalculator.calculate([
        session(id: 'd1', startedAt: DateTime(2026, 6, 1), seconds: 60),
        session(id: 'd2', startedAt: DateTime(2026, 6, 2), seconds: 60),
        session(id: 'd3', startedAt: DateTime(2026, 6, 3), seconds: 60),
        session(id: 'd5', startedAt: DateTime(2026, 6, 5), seconds: 60),
        session(id: 'd9', startedAt: DateTime(2026, 6, 9), seconds: 60),
      ], now: today);

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 3);
    });

    test('future-only activity does not create a current streak', () {
      final today = DateTime(2026, 7, 1, 12);
      final result = JourneyCalculator.calculate([
        session(
          id: 'future',
          startedAt: DateTime(2026, 7, 2),
          seconds: 120,
        ),
      ], now: today);

      expect(result.currentStreak, 0);
    });

    test('leap year has 366 days and date keys preserve year boundary', () {
      expect(DateTime(2024, 1, 1).difference(DateTime(2023, 1, 1)).inDays, 365);
      expect(DateTime(2025, 1, 1).difference(DateTime(2024, 1, 1)).inDays, 366);
      expect(JourneyCalculator.dateKey(DateTime(2024, 12, 31)), '2024-12-31');
      expect(JourneyCalculator.dateKey(DateTime(2025, 1, 1)), '2025-01-01');
    });
  });
}
