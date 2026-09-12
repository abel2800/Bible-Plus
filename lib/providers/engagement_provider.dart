import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/engagement.dart';
import '../services/home_widget_service.dart';
import '../utils/streak_copy.dart';

class EngagementProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final Set<String> _readingDays = {};
  final Map<String, int> _readingCounts = {};
  List<PrayerEntry> _prayers = [];
  final Set<String> _likedVerses = {};
  bool _ready = false;
  int _longestStreak = 0;
  int _dailyReadingGoal = 1;

  bool get ready => _ready;
  int get dailyReadingGoal => _dailyReadingGoal;
  List<PrayerEntry> get prayers => List.unmodifiable(_prayers);
  int get longestStreak => _longestStreak;

  bool isVerseLiked(String reference, {String versionId = 'WEB'}) =>
      _likedVerses.contains(_verseKey(reference, versionId));

  Set<String> get readingDays => Set.unmodifiable(_readingDays);
  Map<String, int> get readingCounts => Map.unmodifiable(_readingCounts);

  bool wasRead(DateTime value) => _readingDays.contains(_day(value));

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _readingDays.addAll(
      preferences.getStringList('engagement_reading_days') ?? const [],
    );
    _readingCounts.addAll(_loadReadingCounts(preferences));
    _longestStreak = preferences.getInt('engagement_longest_streak') ?? 0;
    _dailyReadingGoal =
        (preferences.getInt('engagement_daily_reading_goal') ?? 1).clamp(1, 10);
    final prayerJson = preferences.getString('engagement_prayers');
    if (prayerJson != null) {
      try {
        _prayers = (jsonDecode(prayerJson) as List<dynamic>)
            .map((item) => PrayerEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _prayers = [];
      }
    }
    _likedVerses.addAll(
      preferences.getStringList('engagement_liked_verses') ?? const [],
    );
    final current = streakWithGrace();
    if (current > _longestStreak) {
      _longestStreak = current;
      await preferences.setInt('engagement_longest_streak', _longestStreak);
    }
    _ready = true;
    notifyListeners();
  }

  bool hasReadToday([DateTime? value]) =>
      _readingDays.contains(_day(value ?? DateTime.now()));

  int chaptersReadToday([DateTime? value]) =>
      _readingCounts[_day(value ?? DateTime.now())] ?? 0;

  double dailyGoalProgress([DateTime? value]) {
    if (_dailyReadingGoal <= 0) return 1;
    return (chaptersReadToday(value) / _dailyReadingGoal).clamp(0.0, 1.0);
  }

  bool hasMetDailyGoal([DateTime? value]) =>
      chaptersReadToday(value) >= _dailyReadingGoal;

  Future<void> setDailyReadingGoal(int chapters) async {
    _dailyReadingGoal = chapters.clamp(1, 10);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
        'engagement_daily_reading_goal', _dailyReadingGoal);
  }

  int streakWithGrace([DateTime? value]) {
    if (_readingDays.isEmpty) return 0;
    final today = _dateOnly(value ?? DateTime.now());
    var cursor = today;
    if (!_readingDays.contains(_day(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streakDays = 0;
    var windowDays = 0;
    while (windowDays < 3650) {
      final read = _readingDays.contains(_day(cursor));
      if (!read) break;
      streakDays++;
      windowDays++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streakDays;
  }

  String streakTitle([DateTime? value]) =>
      StreakCopy.titleFor(streakWithGrace(value));

  String streakEncouragement([DateTime? value]) {
    final now = value ?? DateTime.now();
    return StreakCopy.encouragement(
      streak: streakWithGrace(now),
      readToday: hasReadToday(now),
    );
  }

  int? get nextMilestone => StreakCopy.nextMilestone(streakWithGrace());

  double progressToNextMilestone() {
    final streak = streakWithGrace();
    final next = StreakCopy.nextMilestone(streak);
    if (next == null) return 1;
    final previous = StreakCopy.milestones
        .where((m) => m <= streak)
        .fold<int>(0, (a, b) => b > a ? b : a);
    final span = next - previous;
    if (span <= 0) return 1;
    return ((streak - previous) / span).clamp(0.0, 1.0);
  }

  Future<String?> recordReading([DateTime? value, int chapterCount = 1]) async {
    final now = value ?? DateTime.now();
    final day = _day(now);
    final isNewDay = _readingDays.add(day);
    final existingCount = _readingCounts[day] ?? 0;
    _readingCounts[day] = existingCount + chapterCount;

    await _saveReadingDays();
    await _saveReadingCounts();

    final streak = streakWithGrace(now);
    if (streak > _longestStreak) {
      _longestStreak = streak;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt('engagement_longest_streak', _longestStreak);
    }

    notifyListeners();
    unawaited(
      HomeWidgetService.syncStreak(
        streak: streak,
        readToday: true,
      ),
    );
    return isNewDay ? StreakCopy.celebrationSnack(streak) : null;
  }

  Future<void> addPrayer(String text, {String? verseReference}) async {
    final value = text.trim();
    if (value.isEmpty) return;
    _prayers = [
      PrayerEntry(
        id: _uuid.v4(),
        text: value,
        verseReference: verseReference,
        createdAt: DateTime.now().toUtc(),
      ),
      ..._prayers,
    ];
    await _savePrayers();
    notifyListeners();
  }

  Future<void> toggleAnswered(String id) async {
    final index = _prayers.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    final entry = _prayers[index];
    _prayers[index] = PrayerEntry(
      id: entry.id,
      text: entry.text,
      verseReference: entry.verseReference,
      createdAt: entry.createdAt,
      answeredAt: entry.isAnswered ? null : DateTime.now().toUtc(),
    );
    await _savePrayers();
    notifyListeners();
  }

  Future<void> deletePrayer(String id) async {
    _prayers.removeWhere((entry) => entry.id == id);
    await _savePrayers();
    notifyListeners();
  }

  Future<void> toggleVerseLike(
    String reference, {
    String versionId = 'WEB',
  }) async {
    final key = _verseKey(reference, versionId);
    if (!_likedVerses.add(key)) {
      _likedVerses.remove(key);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'engagement_liked_verses',
      _likedVerses.toList(),
    );
    notifyListeners();
  }

  Map<String, int> _loadReadingCounts(SharedPreferences preferences) {
    final raw = preferences.getString('engagement_reading_counts');
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, int>{};
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _saveReadingDays() async {
    final preferences = await SharedPreferences.getInstance();
    final values = _readingDays.toList()..sort();
    await preferences.setStringList('engagement_reading_days', values);
  }

  Future<void> _saveReadingCounts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'engagement_reading_counts',
      jsonEncode(_readingCounts),
    );
  }

  Future<void> _savePrayers() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'engagement_prayers',
      jsonEncode(_prayers.map((entry) => entry.toJson()).toList()),
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _day(DateTime value) {
    final day = _dateOnly(value);
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  String _verseKey(String reference, String versionId) =>
      '${versionId.toUpperCase()}:$reference';
}
