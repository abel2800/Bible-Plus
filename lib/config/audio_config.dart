import 'dart:convert';

abstract final class AudioConfig {
  static const apiKey = String.fromEnvironment('BIBLE_BRAIN_API_KEY');
  static const _bibleIdsJson =
      String.fromEnvironment('BIBLE_BRAIN_BIBLE_IDS_JSON');
  static const _mediaHostsCsv =
      String.fromEnvironment('BIBLE_BRAIN_MEDIA_HOSTS');

  static Map<String, String> get bibleIds {
    if (_bibleIdsJson.isEmpty) return const {};
    final value = jsonDecode(_bibleIdsJson) as Map<String, dynamic>;
    return value.map(
      (key, item) => MapEntry(key.toString().toUpperCase(), item as String),
    );
  }

  static Set<String> get mediaHosts => _mediaHostsCsv
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();

  static bool get hasApiKey => apiKey.isNotEmpty;

  static bool get isTextConfigured => hasApiKey;

  static bool get isConfigured =>
      apiKey.isNotEmpty && bibleIds.isNotEmpty && mediaHosts.isNotEmpty;
}
