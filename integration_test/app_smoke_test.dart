import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bible_pulse/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts offline and reaches the adaptive shell', (tester) async {
    await tester.pumpWidget(const BiblePulseApp());
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Home').evaluate().isNotEmpty) break;
    }
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Home'), findsWidgets);

    await tester.tap(find.text('You').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('APPEARANCE'), findsOneWidget);
  });
}
