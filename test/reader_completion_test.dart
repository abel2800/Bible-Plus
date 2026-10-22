import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('completion requires a user drag to chapter end', (tester) async {
    var completions = 0;
    var dragged = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification &&
                  notification.dragDetails != null) {
                dragged = true;
              }
              if (notification is ScrollEndNotification &&
                  dragged &&
                  notification.metrics.extentAfter <= 32) {
                completions += 1;
                dragged = false;
              }
              return false;
            },
            child: ListView(
              children: [
                for (var index = 0; index < 40; index++)
                  SizedBox(height: 64, child: Text('Verse $index')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(completions, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(completions, 1);
  });
}
