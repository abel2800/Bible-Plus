import 'package:flutter/foundation.dart';

import '../models/bible_package.dart';
import '../services/bible_package_service.dart';

class BibleStoreProvider with ChangeNotifier {
  BibleStoreProvider(this._packages);

  final BiblePackageService _packages;
  String _query = '';
  String _language = 'all';
  String _category = 'all';
  bool _ready = false;
  String? _error;

  bool get ready => _ready;
  String? get error => _error;
  String get query => _query;
  String get languageFilter => _language;
  String get categoryFilter => _category;

  List<BiblePackageInfo> get catalog => _packages.catalog;
  Map<String, InstalledBiblePackage> get installed => _packages.installed;
  Map<String, PackageDownloadProgress> get progress => _packages.progress;

  Future<void> initialize() async {
    try {
      await _packages.initialize();
      _ready = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _ready = true;
    }
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

  void setCategoryFilter(String value) {
    _category = value;
    notifyListeners();
  }

  List<BiblePackageInfo> get visiblePackages {
    final q = _query.trim().toLowerCase();
    return catalog.where((pkg) {
      if (_language != 'all' && pkg.language != _language) return false;
      if (_category != 'all' && !pkg.category.contains(_category)) return false;
      if (q.isEmpty) return true;
      return pkg.name.toLowerCase().contains(q) ||
          pkg.abbreviation.toLowerCase().contains(q) ||
          pkg.languageName.toLowerCase().contains(q) ||
          pkg.description.toLowerCase().contains(q);
    }).toList();
  }

  List<String> get languages {
    final set = catalog.map((e) => e.language).toSet().toList()..sort();
    return set;
  }

  bool isInstalled(String packageId) => _packages.isInstalled(packageId);

  Future<void> install(BiblePackageInfo pkg) async {
    notifyListeners();
    try {
      await _packages.installPackage(
        pkg,
        onProgress: (_) => notifyListeners(),
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> uninstall(String packageId) async {
    await _packages.uninstallPackage(packageId);
    notifyListeners();
  }

  Future<int> storageBytes() => _packages.totalStorageBytes();
}
