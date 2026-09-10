import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/color_theme.dart';

class ColorThemeProvider extends ChangeNotifier {
  ReaderColorTheme _currentTheme =
      ReaderColorTheme.getById('dark') ?? ReaderColorTheme.presets.first;

  ReaderColorTheme get currentTheme => _currentTheme;
  List<ReaderColorTheme> get availableThemes => ReaderColorTheme.presets;

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeId = prefs.getString('reader_theme') ?? 'dark';

      final theme = ReaderColorTheme.getById(themeId);
      if (theme != null) {
        _currentTheme = theme;

        if (theme.id != themeId) {
          await prefs.setString('reader_theme', theme.id);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(String themeId) async {
    try {
      final theme = ReaderColorTheme.getById(themeId);
      if (theme == null) return;

      _currentTheme = theme;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reader_theme', theme.id);

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
    }
  }

  Future<void> syncWithAppBrightness(bool isDark) async {
    final targetId = isDark ? 'dark' : 'light';
    if (_currentTheme.id == targetId) return;

    if (_currentTheme.id == 'sepia' ||
        _currentTheme.id == 'glass' ||
        _currentTheme.id == 'void') {
      return;
    }
    await setTheme(targetId);
  }
}
