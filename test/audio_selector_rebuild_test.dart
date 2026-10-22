import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _PlaybackState extends ChangeNotifier {
  bool playing = false;
  int position = 0;

  void advancePosition() {
    position += 1;
    notifyListeners();
  }

  void togglePlayback() {
    playing = !playing;
    notifyListeners();
  }
}

void main() {
  testWidgets('selective audio state consumer ignores position-only updates',
      (tester) async {
    final state = _PlaybackState();
    var builds = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final playing = context.select<_PlaybackState, bool>(
                (value) => value.playing,
              );
              builds += 1;
              return Scaffold(body: Text(playing ? 'Playing' : 'Paused'));
            },
          ),
        ),
      ),
    );
    final initialBuilds = builds;

    state.advancePosition();
    await tester.pump();
    expect(builds, initialBuilds);

    state.togglePlayback();
    await tester.pump();
    expect(builds, initialBuilds + 1);
    expect(find.text('Playing'), findsOneWidget);
  });
}
