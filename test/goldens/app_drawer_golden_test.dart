@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bible_pulse/config/app_capabilities.dart';
import 'package:bible_pulse/l10n/app_localizations.dart';
import 'package:bible_pulse/utils/app_theme.dart';
import 'package:bible_pulse/widgets/app_drawer.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('app drawer ${brightness.name} golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        Provider.value(
          value: const AppCapabilities(
            cloud: false,
            localDatabase: false,
            notifications: false,
            audio: false,
            wallpaperExport: false,
            devotionals: false,
            readingPlans: false,
            hymns: false,
          ),
          child: MaterialApp(
            theme: brightness == Brightness.dark
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const RepaintBoundary(child: AppDrawer()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppDrawer),
        matchesGoldenFile('app_drawer_${brightness.name}.png'),
      );
    });
  }
}
