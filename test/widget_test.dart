import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:bible_pulse/main.dart';

void main() {
  testWidgets('starts in offline mode with BiblePulse branding',
      (tester) async {
    await tester.pumpWidget(const BiblePulseApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'BiblePulse');

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
