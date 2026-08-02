import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/font_settings.dart';

class FontSettingsProvider with ChangeNotifier {
  FontSettings _fontSettings = const FontSettings(
    fontSize: 18.0,
    fontFamily: 'Merriweather',
    lineHeight: 1.6,
  );

  FontSettings get fontSettings => _fontSettings;
  double get fontSize => _fontSettings.fontSize;
  String get fontFamily => _fontSettings.fontFamily;
  double get lineHeight => _fontSettings.lineHeight;

  Future<void> loadFontSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString('reader_font_settings');
      if (encoded != null) {
        _fontSettings = FontSettings.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading font settings: $e');
    }
  }

  Future<void> setFontSize(double size) async {
    _fontSettings = _fontSettings.copyWith(fontSize: size);
    notifyListeners();
    await _saveFontSettings();
  }

  Future<void> setFontFamily(String family,
      {bool useSystemFont = false}) async {
    _fontSettings = _fontSettings.copyWith(
      fontFamily: family,
      useSystemFont: useSystemFont,
    );
    notifyListeners();
    await _saveFontSettings();
  }

  Future<void> setAvailableFont(AvailableFont font) async {
    await setFontFamily(
      font.fontFamily,
      useSystemFont: font.id == 'system',
    );
  }

  Future<void> setLineHeight(double height) async {
    _fontSettings = _fontSettings.copyWith(lineHeight: height);
    notifyListeners();
    await _saveFontSettings();
  }

  Future<void> resetToDefaults() async {
    _fontSettings = const FontSettings(
      fontSize: 18.0,
      fontFamily: 'Merriweather',
      lineHeight: 1.6,
    );
    notifyListeners();
    await _saveFontSettings();
  }

  Future<void> _saveFontSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'reader_font_settings',
        jsonEncode(_fontSettings.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving font settings: $e');
    }
  }
}
