class AudioPackageInfo {
  final String id;
  final String bibleVersionId;
  final String name;
  final String language;
  final String languageName;
  final String translation;
  final String narrator;
  final String description;
  final String license;
  final String quality;
  final String durationLabel;
  final int fileSizeBytes;
  final List<String> category;
  final bool approved;
  final bool requiresAudioConfig;
  final String updatedAt;

  const AudioPackageInfo({
    required this.id,
    required this.bibleVersionId,
    required this.name,
    required this.language,
    required this.languageName,
    required this.translation,
    required this.narrator,
    required this.description,
    required this.license,
    required this.quality,
    required this.durationLabel,
    required this.fileSizeBytes,
    required this.category,
    required this.approved,
    required this.requiresAudioConfig,
    required this.updatedAt,
  });

  factory AudioPackageInfo.fromJson(Map<String, dynamic> json) {
    return AudioPackageInfo(
      id: json['id'] as String,
      bibleVersionId: json['bibleVersionId'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      languageName:
          json['languageName'] as String? ?? json['language'] as String,
      translation: json['translation'] as String? ?? '',
      narrator: json['narrator'] as String? ?? '',
      description: json['description'] as String? ?? '',
      license: json['license'] as String? ?? '',
      quality: json['quality'] as String? ?? 'standard',
      durationLabel: json['durationLabel'] as String? ?? '',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      category: (json['category'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      approved: json['approved'] as bool? ?? false,
      requiresAudioConfig: json['requiresAudioConfig'] as bool? ?? true,
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class InstalledAudioPackage {
  final String packageId;
  final String bibleVersionId;
  final String installedAt;
  final int chaptersCached;
  final int sizeBytes;

  const InstalledAudioPackage({
    required this.packageId,
    required this.bibleVersionId,
    required this.installedAt,
    required this.chaptersCached,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'packageId': packageId,
        'bibleVersionId': bibleVersionId,
        'installedAt': installedAt,
        'chaptersCached': chaptersCached,
        'sizeBytes': sizeBytes,
      };

  factory InstalledAudioPackage.fromJson(Map<String, dynamic> json) {
    return InstalledAudioPackage(
      packageId: json['packageId'] as String,
      bibleVersionId: json['bibleVersionId'] as String,
      installedAt: json['installedAt'] as String,
      chaptersCached: json['chaptersCached'] as int? ?? 0,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
    );
  }
}
