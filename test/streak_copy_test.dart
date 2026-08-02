import 'package:flutter_test/flutter_test.dart';

import 'package:bible_pulse/utils/streak_copy.dart';

void main() {
  test('milestones and titles', () {
    expect(StreakCopy.isMilestone(7), isTrue);
    expect(StreakCopy.nextMilestone(5), 7);
    expect(StreakCopy.titleFor(7), 'Week warrior');
    expect(
      StreakCopy.encouragement(streak: 6, readToday: false),
      contains('6-day'),
    );
  });
}
