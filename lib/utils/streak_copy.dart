class StreakCopy {
  StreakCopy._();

  static const milestones = [
    3,
    7,
    14,
    21,
    30,
    40,
    50,
    60,
    75,
    100,
    150,
    200,
    365
  ];

  static int? nextMilestone(int streak) {
    for (final m in milestones) {
      if (streak < m) return m;
    }
    return null;
  }

  static bool isMilestone(int streak) => milestones.contains(streak);

  static String titleFor(int streak) {
    if (streak <= 0) return 'Light your flame';
    if (streak == 1) return 'First spark';
    if (streak < 3) return 'Flame lit';
    if (streak < 7) return 'Warming up';
    if (streak < 14) return 'Week warrior';
    if (streak < 21) return 'Fortnight faithful';
    if (streak < 30) return 'Habit builder';
    if (streak < 50) return 'Month of devotion';
    if (streak < 75) return 'Steadfast reader';
    if (streak < 100) return 'Scripture athlete';
    if (streak < 150) return 'Century seeker';
    if (streak < 200) return 'Deep roots';
    if (streak < 365) return 'Unshakable';
    return 'Year of the Word';
  }

  static String encouragement({
    required int streak,
    required bool readToday,
  }) {
    if (streak <= 0) {
      return 'Open any chapter today to start your reading streak.';
    }
    if (!readToday) {
      if (streak == 1) {
        return 'Yesterday’s spark is glowing — read a little to keep day 2 alive.';
      }
      return 'You’re on a $streak-day run. One chapter today keeps the flame going.';
    }
    if (isMilestone(streak)) {
      return 'Milestone unlocked: ${titleFor(streak)}! You’re doing beautifully.';
    }
    final next = nextMilestone(streak);
    if (next != null) {
      final left = next - streak;
      return 'Today’s sealed. $left more day${left == 1 ? '' : 's'} to ${titleFor(next)} ($next).';
    }
    return 'Your $streak-day flame is shining. Come back tomorrow.';
  }

  static String celebrationSnack(int streak) {
    if (isMilestone(streak)) {
      return '🔥 $streak-day streak! ${titleFor(streak)}';
    }
    if (streak == 1) {
      return '🔥 Streak started — come back tomorrow!';
    }
    return '🔥 Day $streak sealed. ${titleFor(streak)}';
  }

  static String morningNotificationTitle(int streak) {
    if (streak <= 0) return 'Verse of the Day · start your flame';
    return 'Verse of the Day · day ${streak + 1} awaits';
  }

  static String eveningNotificationTitle(int streak) {
    if (streak <= 0) return 'Your Scripture flame is waiting';
    return 'Keep your $streak-day flame alive';
  }

  static String eveningNotificationBody({
    required int streak,
    required bool readToday,
  }) {
    if (readToday) {
      return streak <= 0
          ? 'Beautiful start. Tomorrow another verse is waiting for you.'
          : 'Today’s reading is done. Rest well — day ${streak + 1} starts tomorrow.';
    }
    if (streak <= 0) {
      return 'A few minutes in the Word lights your first spark. Open BiblePulse.';
    }
    return 'Don’t let day ${streak + 1} slip away. Open Scripture and keep the streak.';
  }
}
