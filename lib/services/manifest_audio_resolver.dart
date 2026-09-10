import 'dart:convert';

import 'package:flutter/services.dart';

import 'audio_contracts.dart';

/// Resolves chapter audio from a bundled JSON manifest (baseUrl + per-book filenames).
class ManifestAudioResolver implements AudioChapterResolver {
  ManifestAudioResolver._({
    required this.versionId,
    required this.versionAliases,
    required this.baseUrl,
    required this.filesetId,
    required this.attribution,
    required this.downloadPermitted,
    required this.allowedHosts,
    required Map<int, List<String>> books,
  }) : _books = books;

  factory ManifestAudioResolver.fromJson(Map<String, dynamic> json) {
    final books = <int, List<String>>{};
    for (final item in json['books'] as List<dynamic>? ?? const []) {
      final map = Map<String, dynamic>.from(item as Map);
      final bookId = map['bookId'] as int;
      books[bookId] = (map['chapters'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList();
    }
    return ManifestAudioResolver._(
      versionId: (json['versionId'] as String).toUpperCase(),
      versionAliases: (json['versionAliases'] as List<dynamic>? ?? const [])
          .map((e) => (e as String).toUpperCase())
          .toList(),
      baseUrl: json['baseUrl'] as String,
      filesetId: json['filesetId'] as String? ?? 'manifest-audio',
      attribution: json['attribution'] as String? ?? '',
      downloadPermitted: json['downloadPermitted'] as bool? ?? true,
      allowedHosts: (json['allowedHosts'] as List<dynamic>? ?? const [])
          .map((e) => (e as String).toLowerCase())
          .toSet(),
      books: books,
    );
  }

  static Future<ManifestAudioResolver> loadFromAssets(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return ManifestAudioResolver.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  final String versionId;
  final List<String> versionAliases;
  final String baseUrl;
  final String filesetId;
  final String attribution;
  final bool downloadPermitted;
  final Set<String> allowedHosts;
  final Map<int, List<String>> _books;

  bool supportsVersion(String version) {
    final id = version.toUpperCase();
    return id == versionId || versionAliases.contains(id);
  }

  @override
  Future<AudioChapterSource?> resolve({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    if (!supportsVersion(versionId)) return null;
    final chapters = _books[bookId];
    if (chapters == null || chapter < 1 || chapter > chapters.length) {
      return null;
    }

    final fileName = chapters[chapter - 1];
    final uri = Uri.parse(baseUrl).resolve(fileName);
    if (uri.scheme != 'https') return null;
    if (allowedHosts.isNotEmpty &&
        !allowedHosts.contains(uri.host.toLowerCase())) {
      return null;
    }
    return AudioChapterSource(
      uri: uri,
      filesetId: filesetId,
      attribution: attribution,
      downloadPermitted: downloadPermitted,
    );
  }
}
