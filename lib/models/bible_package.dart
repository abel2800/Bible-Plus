class BiblePackageInstall {
  final String type;
  final String? path;
  final String? url;
  final String? format;
  final String? reason;

  const BiblePackageInstall({
    required this.type,
    this.path,
    this.url,
    this.format,
    this.reason,
  });

  factory BiblePackageInstall.fromJson(Map<String, dynamic> json) {
    return BiblePackageInstall(
      type: json['type'] as String? ?? 'unavailable',
      path: json['path'] as String?,
      url: json['url'] as String?,
      format: json['format'] as String?,
      reason: json['reason'] as String?,
    );
  }

  bool get isDownloadable =>
      type == 'asset' ||
      type == 'bible_brain' ||
      (type == 'url' && (url?.isNotEmpty ?? false));
  bool get requiresLicense => type == 'unavailable';
  bool get isBibleBrain => type == 'bible_brain';
}

class BiblePackageInfo {
  final String id;
  final String versionId;
  final String name;
  final String abbreviation;
  final String language;
  final String languageName;
  final String description;
  final String license;
  final String attribution;
  final String source;
  final bool commercialUse;
  final bool redistribution;
  final bool approved;
  final List<String> category;
  final int fileSizeBytes;
  final int offlineSizeBytes;
  final String updatedAt;
  final BiblePackageInstall install;

  const BiblePackageInfo({
    required this.id,
    required this.versionId,
    required this.name,
    required this.abbreviation,
    required this.language,
    required this.languageName,
    required this.description,
    required this.license,
    required this.attribution,
    required this.source,
    required this.commercialUse,
    required this.redistribution,
    required this.approved,
    required this.category,
    required this.fileSizeBytes,
    required this.offlineSizeBytes,
    required this.updatedAt,
    required this.install,
  });

  factory BiblePackageInfo.fromJson(Map<String, dynamic> json) {
    return BiblePackageInfo(
      id: json['id'] as String,
      versionId: json['versionId'] as String,
      name: json['name'] as String,
      abbreviation:
          json['abbreviation'] as String? ?? json['versionId'] as String,
      language: json['language'] as String,
      languageName:
          json['languageName'] as String? ?? json['language'] as String,
      description: json['description'] as String? ?? '',
      license: json['license'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
      source: json['source'] as String? ?? '',
      commercialUse: json['commercialUse'] as bool? ?? false,
      redistribution: json['redistribution'] as bool? ?? false,
      approved: json['approved'] as bool? ?? false,
      category: (json['category'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      offlineSizeBytes: json['offlineSizeBytes'] as int? ?? 0,
      updatedAt: json['updatedAt'] as String? ?? '',
      install: BiblePackageInstall.fromJson(
        Map<String, dynamic>.from(json['install'] as Map? ?? const {}),
      ),
    );
  }

  bool get canInstall {
    if (install.type == 'bible_brain') {
      return approved && install.path != null && install.path!.isNotEmpty;
    }
    return approved &&
        commercialUse &&
        redistribution &&
        install.isDownloadable;
  }
}

class InstalledBiblePackage {
  final String packageId;
  final String versionId;
  final String language;
  final String localPath;
  final String installedAt;
  final int sizeBytes;
  final bool bundled;

  const InstalledBiblePackage({
    required this.packageId,
    required this.versionId,
    required this.language,
    required this.localPath,
    required this.installedAt,
    required this.sizeBytes,
    this.bundled = false,
  });

  Map<String, dynamic> toJson() => {
        'packageId': packageId,
        'versionId': versionId,
        'language': language,
        'localPath': localPath,
        'installedAt': installedAt,
        'sizeBytes': sizeBytes,
        'bundled': bundled,
      };

  factory InstalledBiblePackage.fromJson(Map<String, dynamic> json) {
    return InstalledBiblePackage(
      packageId: json['packageId'] as String,
      versionId: json['versionId'] as String,
      language: json['language'] as String,
      localPath: json['localPath'] as String,
      installedAt: json['installedAt'] as String,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      bundled: json['bundled'] as bool? ?? false,
    );
  }
}

enum PackageDownloadState {
  idle,
  queued,
  downloading,
  paused,
  verifying,
  installing,
  failed,
  completed
}

class PackageDownloadProgress {
  final String packageId;
  final PackageDownloadState state;
  final double progress;
  final String? error;

  const PackageDownloadProgress({
    required this.packageId,
    required this.state,
    this.progress = 0,
    this.error,
  });
}
