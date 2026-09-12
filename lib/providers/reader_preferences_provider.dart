import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reader display toggles from the HTML reading settings mock.
class ReaderPreferencesProvider with ChangeNotifier {
  bool _showVerseNumbers = true;
  bool _redLetterWords = false;
  bool _focusOnOpen = false;
  bool _ready = false;

  bool get ready => _ready;
  bool get showVerseNumbers => _showVerseNumbers;
  bool get redLetterWords => _redLetterWords;
  bool get focusOnOpen => _focusOnOpen;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _showVerseNumbers = prefs.getBool('reader_show_verse_numbers') ?? true;
    _redLetterWords = prefs.getBool('reader_red_letter') ?? false;
    _focusOnOpen = prefs.getBool('reader_focus_on_open') ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> setShowVerseNumbers(bool value) async {
    _showVerseNumbers = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_show_verse_numbers', value);
  }

  Future<void> setRedLetterWords(bool value) async {
    _redLetterWords = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_red_letter', value);
  }

  Future<void> setFocusOnOpen(bool value) async {
    _focusOnOpen = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_focus_on_open', value);
  }
}
