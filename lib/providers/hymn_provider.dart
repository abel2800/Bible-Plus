import 'package:flutter/material.dart';

import '../models/hymn.dart';
import '../services/licensed_catalog_service.dart';

class HymnProvider extends ChangeNotifier {
  HymnProvider({LicensedCatalogService? catalogs})
      : _catalogs = catalogs ?? LicensedCatalogService();

  final LicensedCatalogService _catalogs;
  List<Hymn> _hymns = const [];
  final List<String> _favoriteIds = [];
  bool _isLoading = false;
  String? _error;

  List<Hymn> get hymns => List.unmodifiable(_hymns);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHymns() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final catalogs = await _catalogs.loadFeature('hymns', Hymn.fromJson);
      _hymns = catalogs.expand((catalog) => catalog.items).toList();
    } catch (error) {
      _error = 'Unable to load the licensed hymn catalog.';
      _hymns = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String hymnId) async {
    if (_favoriteIds.contains(hymnId)) {
      _favoriteIds.remove(hymnId);
    } else {
      _favoriteIds.add(hymnId);
    }
    notifyListeners();
  }

  bool isFavorite(String hymnId) => _favoriteIds.contains(hymnId);
}
