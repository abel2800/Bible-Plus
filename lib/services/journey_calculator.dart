import '../models/journey_session.dart';

enum JourneyGoalType { minutes, chapters }

class JourneyDay {
  const JourneyDay({
    required this.date,
    required this.readingSeconds,
    required this.listeningSeconds,
    required this.completedChapters,
    required this.sessions,
  });

  final DateTime date;
  final int readingSeconds;
  final int listeningSeconds;
  final int completedChapters;
  final List<JourneySession> sessions;

  int get totalSeconds => readingSeconds + listeningSeconds;
  int get totalMinutes => totalSeconds ~/ 60;
  bool get isActive => totalSeconds > 0 || completedChapters > 0;
}

class JourneySummary {
  const JourneySummary({
    required this.days,
    required this.totalSeconds,
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
  });

  final Map<String, JourneyDay> days;
  final int totalSeconds;
  final int activeDays;
  final int currentStreak;
  final int longestStreak;

  JourneyDay day(DateTime value) {
    final local = value.toLocal();
    return days[JourneyCalculator.dateKey(local)] ??
        JourneyDay(
          date: DateTime(local.year, local.month, local.day),
          readingSeconds: 0,
          listeningSeconds: 0,
          completedChapters: 0,
          sessions: const [],
        );
  }
}

class JourneyCalculator {
  static const activityMinuteThresholds = [1, 5, 15, 30];

  static String dateKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static JourneySummary calculate(
    Iterable<JourneySession> source, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final nowUtc = today.toUtc();
    final deduplicated = <String, JourneySession>{};
    for (final session in source) {
      final previous = deduplicated[session.id];
      if (previous == null || session.updatedAt.isAfter(previous.updatedAt)) {
        deduplicated[session.id] = session;
      }
    }
    final sessions = deduplicated.values.toList(growable: false);
    final values = <String, _MutableDay>{};
    var totalSeconds = 0;

    for (final session in sessions) {
      if (session.startedAt.isAfter(nowUtc)) continue;
      final elapsedUntilNow = nowUtc.difference(session.startedAt).inSeconds;
      final seconds = session.durationSeconds
          .clamp(0, elapsedUntilNow)
          .clamp(0, 86400 * 370);
      totalSeconds += seconds;
      if (seconds > 0) {
        var remaining = seconds;
        var cursor = session.startedAt.toLocal();
        while (remaining > 0) {
          final nextMidnight =
              DateTime(cursor.year, cursor.month, cursor.day + 1);
          final available = nextMidnight.difference(cursor).inSeconds;
          if (available <= 0) break;
          final slice = remaining < available ? remaining : available;
          final key = dateKey(cursor);
          final day = values.putIfAbsent(
            key,
            () => _MutableDay(DateTime(cursor.year, cursor.month, cursor.day)),
          );
          if (session.type == JourneySessionType.reading) {
            day.readingSeconds += slice;
          } else {
            day.listeningSeconds += slice;
          }
          day.sessions.add(
            session.copyWith(
              startedAt: cursor,
              endedAt: cursor.add(Duration(seconds: slice)),
              durationSeconds: slice,
              completedChapters: 0,
            ),
          );
          remaining -= slice;
          cursor = nextMidnight;
        }
      }

      if (session.completedChapters > 0 && !session.startedAt.isAfter(nowUtc)) {
        final local = session.startedAt.toLocal();
        final day = values.putIfAbsent(
          dateKey(local),
          () => _MutableDay(DateTime(local.year, local.month, local.day)),
        );
        day.completedChapters += session.completedChapters;
        if (!day.sessions.any((item) => item.id == session.id)) {
          day.sessions.add(session.copyWith(
            durationSeconds: 0,
            completedChapters: session.completedChapters,
          ));
        }
      }
    }

    final days = <String, JourneyDay>{};
    for (final entry in values.entries) {
      final value = entry.value;
      days[entry.key] = JourneyDay(
        date: value.date,
        readingSeconds: value.readingSeconds,
        listeningSeconds: value.listeningSeconds,
        completedChapters: value.completedChapters,
        sessions: List.unmodifiable(value.sessions),
      );
    }

    final activeKeys = days.entries
        .where((entry) => entry.value.isActive)
        .map((entry) => entry.key)
        .toSet();
    final todayDate = DateTime(today.year, today.month, today.day);
    var cursor = todayDate;
    if (!activeKeys.contains(dateKey(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var currentStreak = 0;
    while (activeKeys.contains(dateKey(cursor))) {
      currentStreak += 1;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    var longestStreak = 0;
    var run = 0;
    final sorted = activeKeys.toList()..sort();
    DateTime? previous;
    for (final key in sorted) {
      final parts = key.split('-').map(int.parse).toList();
      final date = DateTime.utc(parts[0], parts[1], parts[2]);
      if (previous != null && date.difference(previous).inDays == 1) {
        run += 1;
      } else {
        run = 1;
      }
      if (run > longestStreak) longestStreak = run;
      previous = date;
    }

    return JourneySummary(
      days: Map.unmodifiable(days),
      totalSeconds: totalSeconds,
      activeDays: activeKeys.length,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  static int activityLevel(JourneyDay day) {
    if (!day.isActive) return 0;
    final minutes = day.totalSeconds ~/ 60;
    if (minutes < activityMinuteThresholds[1]) return 1;
    if (minutes < activityMinuteThresholds[2]) return 2;
    if (minutes < activityMinuteThresholds[3]) return 3;
    return 4;
  }
}

class _MutableDay {
  _MutableDay(this.date);

  final DateTime date;
  int readingSeconds = 0;
  int listeningSeconds = 0;
  int completedChapters = 0;
  final List<JourneySession> sessions = [];
}
