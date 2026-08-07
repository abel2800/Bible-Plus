import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesProvider with ChangeNotifier {
  static const supportedLanguageCodes = ['en', 'am', 'om', 'ti', 'so'];

  String _preferredBibleVersionId = 'WEB';
  String _preferredAudioPackageId = '';
  String _appLanguageCode = 'en';
  bool _hasCompletedOnboarding = false;
  bool _ready = false;

  bool get ready => _ready;
  String get preferredBibleVersionId => _preferredBibleVersionId;
  String get preferredAudioPackageId => _preferredAudioPackageId;
  String get appLanguageCode => _appLanguageCode;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Locale get appLocale => Locale(_appLanguageCode);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredBibleVersionId =
        prefs.getString('preferred_bible_version') ?? 'WEB';
    _preferredAudioPackageId =
        prefs.getString('preferred_audio_package') ?? 'web-henson-en';
    final lang = prefs.getString('languageCode') ?? 'en';
    _appLanguageCode = supportedLanguageCodes.contains(lang) ? lang : 'en';
    _hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? true;
    _ready = true;
    notifyListeners();
  }

  Future<void> setPreferredBible(String versionId) async {
    _preferredBibleVersionId = versionId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_bible_version', versionId);
  }

  Future<void> setPreferredAudio(String packageId) async {
    _preferredAudioPackageId = packageId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_audio_package', packageId);
  }

  Future<void> setAppLanguage(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode)) return;
    _appLanguageCode = languageCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  String languageLabel(String code) {
    switch (code) {
      case 'am':
        return 'Amharic';
      case 'om':
        return 'Afaan Oromo';
      case 'ti':
        return 'Tigrinya';
      case 'so':
        return 'Somali';
      default:
        return 'English';
    }
  }
}
