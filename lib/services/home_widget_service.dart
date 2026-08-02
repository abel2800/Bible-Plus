import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/bible_verse.dart';

/// Pushes Verse of the Day + streak to a native home-screen widget.
///
/// Supported:
/// - Android: [BiblePulseWidgetProvider] (fully wired in this repo)
/// - iOS: needs a Widget Extension in Xcode (see docs/HOME_WIDGET.md)
///
/// On web / Windows / Linux / macOS (without an extension), [sync] is a
/// no-op so the rest of the app keeps working on every platform.
class HomeWidgetService {
  HomeWidgetService._();

  static const _androidWidgetName = 'BiblePulseWidgetProvider';
  static const _iosWidgetName = 'BiblePulseWidget';
  static const _iosAppGroupId = 'group.app.biblepulse.reader';

  static const keyVerseText = 'verse_text';
  static const keyVerseReference = 'verse_reference';
  static const keyStreak = 'streak';
  static const keyReadToday = 'read_today';

  static bool get isNativeWidgetSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  static Future<void> configure() async {
    if (!isNativeWidgetSupported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(_iosAppGroupId);
      }
    } catch (error) {
      debugPrint('Home widget configure skipped: $error');
    }
  }

  static Future<void> sync({
    required BibleVerse? verseOfDay,
    required String verseReference,
    required int streak,
    required bool readToday,
  }) async {
    if (!isNativeWidgetSupported) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        keyVerseText,
        verseOfDay?.text ?? "Open BiblePulse to see today's verse.",
      );
      await HomeWidget.saveWidgetData<String>(
        keyVerseReference,
        verseOfDay == null ? '' : verseReference,
      );
      await HomeWidget.saveWidgetData<int>(keyStreak, streak);
      await HomeWidget.saveWidgetData<bool>(keyReadToday, readToday);
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (error) {
      debugPrint('Home widget sync skipped: $error');
    }
  }

  static Future<void> syncStreak({
    required int streak,
    required bool readToday,
  }) async {
    if (!isNativeWidgetSupported) return;
    try {
      await HomeWidget.saveWidgetData<int>(keyStreak, streak);
      await HomeWidget.saveWidgetData<bool>(keyReadToday, readToday);
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (error) {
      debugPrint('Home widget streak sync skipped: $error');
    }
  }

  static Future<void> registerLaunchHandler(
    Future<void> Function(Uri? uri) onLaunch,
  ) async {
    if (!isNativeWidgetSupported) return;
    try {
      HomeWidget.widgetClicked.listen(onLaunch);
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      await onLaunch(initial);
    } catch (error) {
      debugPrint('Home widget launch handler skipped: $error');
    }
  }
}
