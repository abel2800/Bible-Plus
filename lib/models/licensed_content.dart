class LicensedContentMetadata {
  const LicensedContentMetadata({
    required this.id,
    required this.feature,
    required this.path,
    required this.source,
    required this.license,
    required this.attribution,
    required this.sha256,
    required this.language,
    required this.approved,
    required this.commercialUse,
    required this.redistribution,
    this.publisher,
    this.revision,
    this.expiresAt,
  });

  final String id;
  final String feature;
  final String path;
  final String source;
  final String license;
  final String attribution;
  final String sha256;
  final String language;
  final bool approved;
  final bool commercialUse;
  final bool redistribution;
  final String? publisher;
  final String? revision;
  final DateTime? expiresAt;

  bool get isCurrentlyApproved =>
      approved &&
      commercialUse &&
      redistribution &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now().toUtc()));

  factory LicensedContentMetadata.fromJson(Map<String, dynamic> json) {
    return LicensedContentMetadata(
      id: json['id'] as String,
      feature: json['feature'] as String,
      path: json['path'] as String,
      source: json['source'] as String,
      license: json['license'] as String,
      attribution: json['attribution'] as String,
      sha256: json['sha256'] as String,
      language: json['language'] as String? ?? 'und',
      approved: json['approved'] as bool? ?? false,
      commercialUse: json['commercialUse'] as bool? ?? false,
      redistribution: json['redistribution'] as bool? ?? false,
      publisher: json['publisher'] as String?,
      revision: json['revision'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class LicensedCatalog<T> {
  const LicensedCatalog({required this.metadata, required this.items});

  final LicensedContentMetadata metadata;
  final List<T> items;
}
