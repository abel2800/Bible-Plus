import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/licensed_content.dart';

class LicensedCatalogService {
  LicensedCatalogService({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<LicensedContentMetadata>? _manifest;

  Future<List<LicensedContentMetadata>> manifest() async {
    if (_manifest case final cached?) return cached;
    final source = await _bundle.loadString('assets/content_manifest.json');
    final json = jsonDecode(source) as Map<String, dynamic>;
    final entries = (json['assets'] as List<dynamic>)
        .map(
          (item) => LicensedContentMetadata.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
    _manifest = entries;
    return entries;
  }

  Future<List<LicensedCatalog<T>>> loadFeature<T>(
    String feature,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final entries = (await manifest())
        .where(
          (entry) => entry.feature == feature && entry.isCurrentlyApproved,
        )
        .toList();
    final catalogs = <LicensedCatalog<T>>[];
    for (final entry in entries) {
      final data = await _bundle.load(entry.path);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (sha256.convert(bytes).toString().toLowerCase() !=
          entry.sha256.toLowerCase()) {
        throw StateError('Catalog checksum mismatch: ${entry.id}');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      final items = decoded is List<dynamic>
          ? decoded
          : (decoded as Map<String, dynamic>)['items'] as List<dynamic>;
      catalogs.add(
        LicensedCatalog(
          metadata: entry,
          items: items
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList(growable: false),
        ),
      );
    }
    return catalogs;
  }
}
