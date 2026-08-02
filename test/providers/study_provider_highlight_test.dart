import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_pulse/providers/study_provider.dart';

void main() {
  test('highlight remains single-color and persists until removed', () async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final provider = StudyProvider();
    await provider.loadAll();

    await provider.addHighlight('John 3:16', 'For God so loved', Colors.yellow);
    await provider.addHighlight('John 3:16', 'For God so loved', Colors.green);

    expect(provider.highlights, hasLength(1));
    expect(
      provider.getHighlightColor('John 3:16')?.toARGB32(),
      Colors.green.toARGB32(),
    );

    final restored = StudyProvider();
    await restored.loadAll();
    expect(
      restored.getHighlightColor('John 3:16')?.toARGB32(),
      Colors.green.toARGB32(),
    );

    await restored.removeHighlight('John 3:16');
    expect(restored.isHighlighted('John 3:16'), isFalse);
  });
}
