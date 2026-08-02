import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/audio_config.dart';
import '../models/audio_package.dart';

class AudioStoreProvider with ChangeNotifier {
  static const _catalogAsset = 'assets/catalog/audio_catalog.json';
  static const _registryKey = 'installed_audio_packages_v1';

  List<AudioPackageInfo> _catalog = [];
  final Map<String, InstalledAudioPackage> _installed = {};
  String _query = '';
  String _language = 'all';
  bool _ready = false;

  bool get ready => _ready;
  String get query => _query;
  String get languageFilter => _language;
  List<AudioPackageInfo> get catalog => List.unmodifiable(_catalog);
  Map<String, InstalledAudioPackage> get installed =>
      Map.unmodifiable(_installed);
  bool get audioConfigured => AudioConfig.isConfigured;

  Future<void> initialize() async {
    final raw = await rootBundle.loadString(_catalogAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _catalog = (json['packages'] as List<dynamic>? ?? const [])
        .map((e) =>
            AudioPackageInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_registryKey);
    _installed.clear();
    if (saved != null && saved.isNotEmpty) {
      for (final item in jsonDecode(saved) as List) {
        final pack = InstalledAudioPackage.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        _installed[pack.packageId] = pack;
      }
    }

    const bundledId = 'web-henson-en';
    if (!_installed.containsKey(bundledId)) {
      final bundled = _catalog.where((p) => p.id == bundledId);
      if (bundled.isNotEmpty && canActivate(bundled.first)) {
        _installed[bundledId] = InstalledAudioPackage(
          packageId: bundledId,
          bibleVersionId: bundled.first.bibleVersionId,
          installedAt: DateTime.now().toUtc().toIso8601String(),
          chaptersCached: 0,
          sizeBytes: 0,
        );
        await _save();
      }
    }
    _ready = true;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setLanguageFilter(String value) {
    _language = value;
    notifyListeners();
  }

  List<AudioPackageInfo> get visiblePackages {
    final q = _query.trim().toLowerCase();
    return catalog.where((pkg) {
      if (_language != 'all' && pkg.language != _language) return false;
      if (q.isEmpty) return true;
      return pkg.name.toLowerCase().contains(q) ||
          pkg.translation.toLowerCase().contains(q) ||
          pkg.narrator.toLowerCase().contains(q);
    }).toList();
  }

  bool isInstalled(String id) => _installed.containsKey(id);

  bool canActivate(AudioPackageInfo pkg) =>
      pkg.approved && (!pkg.requiresAudioConfig || audioConfigured);

  Future<void> markInstalled(AudioPackageInfo pkg,
      {int chapters = 0, int bytes = 0}) async {
    _installed[pkg.id] = InstalledAudioPackage(
      packageId: pkg.id,
      bibleVersionId: pkg.bibleVersionId,
      installedAt: DateTime.now().toUtc().toIso8601String(),
      chaptersCached: chapters,
      sizeBytes: bytes,
    );
    await _save();
    notifyListeners();
  }

  Future<void> uninstall(String packageId) async {
    _installed.remove(packageId);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _registryKey,
      jsonEncode(_installed.values.map((e) => e.toJson()).toList()),
    );
  }
}
