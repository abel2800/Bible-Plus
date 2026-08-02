import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/audio_config.dart';

class BibleBrainVersionRegistry {
  BibleBrainVersionRegistry({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _prefsKey = 'bible_brain_version_ids_v1';

  final SharedPreferences? _preferences;
  Map<String, String> _runtime = {};

  Map<String, String> get all {
    return {
      ...AudioConfig.bibleIds,
      ..._runtime,
    };
  }

  Future<void> load() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final raw = preferences.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _runtime = {};
      return;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _runtime = decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> enable({
    required String versionId,
    required String bibleId,
  }) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _runtime = {..._runtime, versionId: bibleId};
    await preferences.setString(_prefsKey, jsonEncode(_runtime));
  }

  Future<void> disable(String versionId) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _runtime = Map<String, String>.from(_runtime)..remove(versionId);
    await preferences.setString(_prefsKey, jsonEncode(_runtime));
  }

  String? bibleIdFor(String versionId) => all[versionId];

  bool isEnabled(String versionId) => all.containsKey(versionId);
}
