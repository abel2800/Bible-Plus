import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bible_pulse/config/app_capabilities.dart';
import 'package:bible_pulse/l10n/app_localizations.dart';
import 'package:bible_pulse/utils/app_theme.dart';
import 'package:bible_pulse/widgets/app_drawer.dart';

void main() {
  testWidgets('drawer meets tap target, label, and contrast guidelines',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
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
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: AppDrawer()),
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
