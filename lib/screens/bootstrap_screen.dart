import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../providers/color_theme_provider.dart';
import '../providers/font_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';
import 'splash_screen.dart';

enum BootstrapStatus { loading, ready, failed }

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  BootstrapStatus _status = BootstrapStatus.loading;
  Object? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initialize();
      });
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _status = BootstrapStatus.loading;
      _error = null;
    });

    try {
      await Future.wait([
        context.read<ThemeProvider>().ready,
        context.read<BibleProvider>().ready,
        context.read<ColorThemeProvider>().loadTheme(),
        context.read<FontSettingsProvider>().loadFontSettings(),
        context.read<UserPreferencesProvider>().initialize(),
      ]);

      if (!mounted) return;

      await context.read<ColorThemeProvider>().syncWithAppBrightness(
            context.read<ThemeProvider>().isDarkMode,
          );

      if (!mounted) return;
      setState(() => _status = BootstrapStatus.ready);
      final prefs = context.read<UserPreferencesProvider>();
      if (prefs.hasCompletedOnboarding) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = BootstrapStatus.failed;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status != BootstrapStatus.failed) {
      return const SplashScreen();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBg = isDark ? AppTheme.appBgDark : AppTheme.appBgLight;
    final surface2 = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.7),
            radius: 1.1,
            colors: [surface2, appBg],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: surface2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.sync_problem_rounded,
                        size: 40,
                        color: AppTheme.vermilion,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'BiblePulse could not finish starting.',
                      textAlign: TextAlign.center,
                      style: AppTheme.brandTitle(fontSize: 22, color: ink),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your local data is safe. Check the app resources and try again.',
                      textAlign: TextAlign.center,
                      style: AppTheme.scripture(
                        fontSize: 15,
                        height: 1.55,
                        color: soft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_error',
                      textAlign: TextAlign.center,
                      style: AppTheme.ui(
                        fontSize: 12,
                        color:
                            isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: BpPrimaryButton(
                        label: 'Try again',
                        onPressed: _initialize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
