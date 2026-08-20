import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_pulse/utils/app_theme.dart';
import 'package:bible_pulse/widgets/design/bp_widgets.dart';

void main() {
  testWidgets('shared editorial card renders inside the app theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: BpCard(child: Text('Bible Pulse')),
        ),
      ),
    );

    expect(find.text('Bible Pulse'), findsOneWidget);
    expect(find.byType(BpCard), findsOneWidget);
  });
}