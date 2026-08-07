import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_pulse/providers/user_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults onboarding to completed for first-time launches', () async {
    final provider = UserPreferencesProvider();
    await provider.initialize();

    expect(provider.hasCompletedOnboarding, isTrue);
  });

  test('persists onboarding completion state', () async {
    final provider = UserPreferencesProvider();
    await provider.initialize();

    expect(provider.hasCompletedOnboarding, isTrue);

    await provider.completeOnboarding();
    expect(provider.hasCompletedOnboarding, isTrue);

    final reloaded = UserPreferencesProvider();
    await reloaded.initialize();
    expect(reloaded.hasCompletedOnboarding, isTrue);
  });
}
