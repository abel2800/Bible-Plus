import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedVersion = 'WEB';
  bool _wantReminders = true;
  bool _wantDailyVerse = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = context.read<UserPreferencesProvider>();
      _selectedVersion = prefs.preferredBibleVersionId;
      if (_selectedVersion.isEmpty) _selectedVersion = 'WEB';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final prefs = context.watch<UserPreferencesProvider>();
    final bible = context.watch<BibleProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BpBrandMark(size: 72),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to BiblePulse',
                    style: AppTheme.brandTitle(fontSize: 28, color: ink),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A calmer way to read Scripture, track your habits, and stay encouraged every day.',
                    style:
                        AppTheme.ui(fontSize: 14.5, color: soft, height: 1.55),
                  ),
                  const SizedBox(height: 24),
                  BpCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your starting Bible',
                          style: AppTheme.brandTitle(
                            fontSize: 16,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedVersion,
                          decoration:
                              const InputDecoration(labelText: 'Version'),
                          items: [
                            const DropdownMenuItem(
                              value: 'WEB',
                              child: Text('World English Bible'),
                            ),
                            ...bible.books.isEmpty
                                ? []
                                : bible.books
                                    .where((book) => book.id != 0)
                                    .map((book) => DropdownMenuItem<String>(
                                          value: book.id.toString(),
                                          child: Text(book.name),
                                        ))
                                    .toList(),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedVersion = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  BpCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What would you like to enable?',
                          style: AppTheme.brandTitle(
                            fontSize: 16,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          value: _wantReminders,
                          onChanged: (value) =>
                              setState(() => _wantReminders = value),
                          title: const Text('Daily reminders'),
                          subtitle: const Text(
                              'Get gentle nudges for reading and prayer.'),
                        ),
                        SwitchListTile.adaptive(
                          value: _wantDailyVerse,
                          onChanged: (value) =>
                              setState(() => _wantDailyVerse = value),
                          title: const Text('Verse of the day'),
                          subtitle: const Text(
                              'Start with a short daily encouragement.'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: BpPrimaryButton(
                      label: 'Start reading',
                      onPressed: () async {
                        await prefs.setPreferredBible(_selectedVersion);
                        await prefs.completeOnboarding();
                        if (!mounted) return;
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                    ),
                  ),
                  if (prefs.ready)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'You can change these later in Settings.',
                        style: AppTheme.ui(fontSize: 12.5, color: soft),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
