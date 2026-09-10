import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/audio_config.dart';
import '../models/audio_package.dart';

class AudioStoreProvider with ChangeNotifier {
  static const _catalogAsset = 'assets/catalog/audio_catalog.json';
  static const _registryKey = 'installed_audio_packages_v1';
  static const _manifestAssets = [
    'assets/catalog/web_henson_audio_manifest.json',
    'assets/catalog/kjv_pdaudio_manifest.json',
    'assets/catalog/amh_sermononline_manifest.json',
    'assets/catalog/ti_sermononline_nt_manifest.json',
  ];

  List<AudioPackageInfo> _catalog = [];
  final Map<String, InstalledAudioPackage> _installed = {};
  final Map<String, List<String>> _textVersionToPackageIds = {};
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

  List<AudioPackageInfo> get downloadablePackages => catalog
      .where((pkg) => pkg.approved && pkg.offlineDownload && canActivate(pkg))
      .toList();

  Future<void> initialize() async {
    final raw = await rootBundle.loadString(_catalogAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _catalog = (json['packages'] as List<dynamic>? ?? const [])
        .map((e) =>
            AudioPackageInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    await _loadManifestAliases();
    _rebuildTextVersionIndex();

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

    const bundledAudioIds = [
      'web-henson-en',
      'kjv-pdaudio-en',
      'amh-sermononline',
      'ti-sermononline-nt',
    ];
    var changed = false;
    for (final id in bundledAudioIds) {
      if (_installed.containsKey(id)) continue;
      final match = _catalog.where((p) => p.id == id);
      if (match.isEmpty || !canActivate(match.first)) continue;
      _installed[id] = InstalledAudioPackage(
        packageId: id,
        bibleVersionId: match.first.bibleVersionId,
        installedAt: DateTime.now().toUtc().toIso8601String(),
        chaptersCached: 0,
        sizeBytes: 0,
      );
      changed = true;
    }
    if (changed) await _save();
    _ready = true;
    notifyListeners();
  }

  Future<void> _loadManifestAliases() async {
    for (final asset in _manifestAssets) {
      try {
        final raw = await rootBundle.loadString(asset);
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final versionId = (map['versionId'] as String?)?.toUpperCase();
        if (versionId == null) continue;
        _registerTextVersion(versionId, versionId);
        for (final alias
            in map['versionAliases'] as List<dynamic>? ?? const []) {
          _registerTextVersion(alias.toString().toUpperCase(), versionId);
        }
      } catch (error) {
        debugPrint('Audio manifest alias load failed for $asset: $error');
      }
    }
  }

  void _rebuildTextVersionIndex() {
    for (final pkg in _catalog) {
      if (!pkg.approved) continue;
      for (final textVersionId in pkg.allTextVersionIds) {
        _registerTextVersion(textVersionId, pkg.id);
      }
    }
  }

  void _registerTextVersion(String textVersionId, String packageOrVersionKey) {
    final textId = textVersionId.toUpperCase();
    final packageId = _catalog.any((p) => p.id == packageOrVersionKey)
        ? packageOrVersionKey
        : _catalog
            .where((p) => p.bibleVersionId.toUpperCase() == packageOrVersionKey)
            .map((p) => p.id)
            .firstOrNull;
    if (packageId == null) return;
    final list = _textVersionToPackageIds.putIfAbsent(textId, () => []);
    if (!list.contains(packageId)) list.add(packageId);
  }

  List<AudioPackageInfo> packagesForTextVersion(String textVersionId) {
    final ids =
        _textVersionToPackageIds[textVersionId.toUpperCase()] ?? const [];
    return [
      for (final id in ids)
        if (_catalog.any((p) => p.id == id))
          _catalog.firstWhere((p) => p.id == id),
    ].where(canActivate).toList();
  }

  AudioPackageInfo? packageById(String packageId) {
    for (final pkg in _catalog) {
      if (pkg.id == packageId) return pkg;
    }
    return null;
  }

  AudioPackageInfo? bestPackageForTextVersion(
    String textVersionId, {
    String? preferredPackageId,
  }) {
    final matches = packagesForTextVersion(textVersionId);
    if (matches.isEmpty) return null;
    if (preferredPackageId != null &&
        preferredPackageId.isNotEmpty &&
        matches.any((p) => p.id == preferredPackageId)) {
      return matches.firstWhere((p) => p.id == preferredPackageId);
    }
    return matches.first;
  }

  bool hasAudioForTextVersion(String textVersionId) =>
      packagesForTextVersion(textVersionId).isNotEmpty;

  String? defaultPackageIdForTextVersion(String textVersionId) =>
      bestPackageForTextVersion(textVersionId)?.id;

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

  List<AudioPackageInfo> get visibleDownloadablePackages {
    final q = _query.trim().toLowerCase();
    return downloadablePackages.where((pkg) {
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
