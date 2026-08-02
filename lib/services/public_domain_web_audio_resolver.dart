import 'dart:convert';

import 'package:flutter/services.dart';

import 'audio_contracts.dart';

class PublicDomainWebAudioResolver implements AudioChapterResolver {
  PublicDomainWebAudioResolver._({
    required this.baseUrl,
    required this.filesetId,
    required this.attribution,
    required this.downloadPermitted,
    required Map<int, _BookAudio> books,
  }) : _books = books;

  factory PublicDomainWebAudioResolver.fromJson(Map<String, dynamic> json) {
    final books = <int, _BookAudio>{};
    for (final item in json['books'] as List<dynamic>? ?? const []) {
      final map = Map<String, dynamic>.from(item as Map);
      final bookId = map['bookId'] as int;
      books[bookId] = _BookAudio(
        folder: map['folder'] as String,
        chapters: (map['chapters'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );
    }
    return PublicDomainWebAudioResolver._(
      baseUrl: json['baseUrl'] as String,
      filesetId: json['filesetId'] as String? ?? 'web-henson-ebible',
      attribution: json['attribution'] as String? ??
          'World English Bible audio narrated by Winfred W. Henson (eBible.org).',
      downloadPermitted: json['downloadPermitted'] as bool? ?? true,
      books: books,
    );
  }

  static const assetPath = 'assets/catalog/web_henson_audio_manifest.json';

  static Future<PublicDomainWebAudioResolver> loadFromAssets() async {
    final raw = await rootBundle.loadString(assetPath);
    return PublicDomainWebAudioResolver.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  final String baseUrl;
  final String filesetId;
  final String attribution;
  final bool downloadPermitted;
  final Map<int, _BookAudio> _books;

  static const supportedVersionIds = {'WEB', 'KJV', 'ASV'};

  static const _fcbhNtNames = <String>[
    'Matthew',
    'Mark',
    'Luke',
    'John',
    'Acts',
    'Romans',
    '1Corinthians',
    '2Corinthians',
    'Galatians',
    'Ephesians',
    'Philippians',
    'Colossians',
    '1Thess',
    '2Thess',
    '1Timothy',
    '2Timothy',
    'Titus',
    'Philemon',
    'Hebrews',
    'James',
    '1Peter',
    '2Peter',
    '1John',
    '2John',
    '3John',
    'Jude',
    'Revelation',
  ];

  @override
  Future<AudioChapterSource?> resolve({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    if (!supportedVersionIds.contains(versionId.toUpperCase())) {
      return null;
    }
    final book = _books[bookId];
    if (book == null || chapter < 1 || chapter > book.chapters.length) {
      return null;
    }

    final fcbh = _fcbhNtUri(bookId, chapter);
    if (fcbh != null) {
      return AudioChapterSource(
        uri: fcbh,
        filesetId: 'web-fcbh-nt-ebible',
        attribution:
            'World English Bible New Testament audio ℗ Faith Comes By Hearing via eBible.org. Copying and redistribution is allowed.',
        downloadPermitted: true,
      );
    }

    final fileName = Uri.decodeComponent(book.chapters[chapter - 1]);
    final uri = Uri.parse(baseUrl).resolve('${book.folder}/').resolve(fileName);
    if (uri.scheme != 'https' ||
        (uri.host.toLowerCase() != 'ebible.org' &&
            uri.host.toLowerCase() != 'www.ebible.org')) {
      return null;
    }
    return AudioChapterSource(
      uri: uri,
      filesetId: filesetId,
      attribution: attribution,
      downloadPermitted: downloadPermitted,
    );
  }

  Uri? _fcbhNtUri(int bookId, int chapter) {
    if (bookId < 40 || bookId > 66) return null;
    final ntIndex = bookId - 39;
    final name = _fcbhNtNames[ntIndex - 1];
    final file =
        '${ntIndex.toString().padLeft(2, '0')}_${chapter.toString().padLeft(2, '0')}_$name.mp3';
    return Uri.https('ebible.org', '/eng-web/mp3/$file');
  }
}

class _BookAudio {
  const _BookAudio({required this.folder, required this.chapters});

  final String folder;
  final List<String> chapters;
}
