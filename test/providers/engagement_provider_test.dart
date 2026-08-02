import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_pulse/providers/engagement_provider.dart';

void main() {
  test('reading streak allows one grace day per seven-day window', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = EngagementProvider();
    await provider.initialize();
    final today = DateTime(2026, 7, 17);
    for (var offset = 0; offset < 7; offset++) {
      if (offset == 3) continue;
      await provider.recordReading(today.subtract(Duration(days: offset)));
    }

    expect(provider.streakWithGrace(today), 6);
  });

  test('prayers persist and can be marked answered', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = EngagementProvider();
    await provider.initialize();
    await provider.addPrayer('Help me', verseReference: 'John 3:16');
    await provider.toggleAnswered(provider.prayers.single.id);

    final restored = EngagementProvider();
    await restored.initialize();
    expect(restored.prayers.single.isAnswered, isTrue);
    expect(restored.prayers.single.verseReference, 'John 3:16');
  });
}
