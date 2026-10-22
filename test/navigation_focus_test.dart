import 'package:bible_pulse/providers/navigation_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('focus mode locks to reader and restores selected navigation tab', () {
    final navigation = NavigationProvider();
    navigation.setIndex(3);

    navigation.setFocusMode(true);
    expect(navigation.focusMode, isTrue);
    expect(navigation.selectedIndex, 1);

    navigation.setIndex(0);
    expect(navigation.selectedIndex, 1);

    navigation.setFocusMode(false);
    expect(navigation.focusMode, isFalse);
    expect(navigation.selectedIndex, 3);
  });
}
