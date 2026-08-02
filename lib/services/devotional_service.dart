import '../models/devotional.dart';
import 'licensed_catalog_service.dart';

class DevotionalService {
  DevotionalService({LicensedCatalogService? catalogs})
      : _catalogs = catalogs ?? LicensedCatalogService();

  final LicensedCatalogService _catalogs;

  Future<Devotional?> getTodayDevotional() async {
    final catalogs =
        await _catalogs.loadFeature('devotionals', Devotional.fromJson);
    final devotionals = catalogs.expand((catalog) => catalog.items).toList();
    if (devotionals.isEmpty) return null;
    final now = DateTime.now();
    for (final devotional in devotionals) {
      if (devotional.date.month == now.month &&
          devotional.date.day == now.day) {
        return devotional;
      }
    }
    return devotionals.first;
  }
}
