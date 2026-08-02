import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_book.dart';
import 'audio_contracts.dart';

class BibleBrainFileset {
  const BibleBrainFileset({
    required this.id,
    required this.mediaType,
    required this.downloadPermitted,
    this.segmentationType,
  });

  final String id;
  final String mediaType;
  final bool downloadPermitted;
  final String? segmentationType;

  bool get isAudio => mediaType.toLowerCase().contains('audio');
  bool get isText => mediaType.toLowerCase().contains('text');
  bool get hasVerseTiming => segmentationType == 'verse';
}

class BibleBrainBibleSummary {
  const BibleBrainBibleSummary({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.languageIso,
    required this.languageName,
    this.hasAudio = false,
    this.hasText = false,
  });

  final String id;
  final String name;
  final String abbreviation;
  final String languageIso;
  final String languageName;
  final bool hasAudio;
  final bool hasText;
}

abstract interface class BibleBrainCatalogGateway {
  Future<List<BibleBrainFileset>> audioFilesets(String bibleId);
  Future<List<BibleBrainFileset>> textFilesets(String bibleId);
  Future<List<BibleBrainBibleSummary>> listBibles({
    String? languageCode,
    String? media,
    int limit = 50,
  });
  Future<List<BibleBook>> books(String bibleId);
  Future<List<AudioVerseTiming>> chapterTimings({
    required String filesetId,
    required String bookCode,
    required int chapter,
  });
}

class BibleBrainCatalogService implements BibleBrainCatalogGateway {
  BibleBrainCatalogService({
    required this.apiKey,
    http.Client? client,
    SharedPreferences? preferences,
    Uri? apiBase,
  })  : _client = client ?? http.Client(),
        _preferences = preferences,
        apiBase = apiBase ?? Uri.parse('https://4.dbt.io/api/');

  final String apiKey;
  final http.Client _client;
  final SharedPreferences? _preferences;
  final Uri apiBase;

  static const _cacheLifetime = Duration(hours: 24);

  static const bookCodes = <String>[
    'GEN',
    'EXO',
    'LEV',
    'NUM',
    'DEU',
    'JOS',
    'JDG',
    'RUT',
    '1SA',
    '2SA',
    '1KI',
    '2KI',
    '1CH',
    '2CH',
    'EZR',
    'NEH',
    'EST',
    'JOB',
    'PSA',
    'PRO',
    'ECC',
    'SNG',
    'ISA',
    'JER',
    'LAM',
    'EZK',
    'DAN',
    'HOS',
    'JOL',
    'AMO',
    'OBA',
    'JON',
    'MIC',
    'NAM',
    'HAB',
    'ZEP',
    'HAG',
    'ZEC',
    'MAL',
    'MAT',
    'MRK',
    'LUK',
    'JHN',
    'ACT',
    'ROM',
    '1CO',
    '2CO',
    'GAL',
    'EPH',
    'PHP',
    'COL',
    '1TH',
    '2TH',
    '1TI',
    '2TI',
    'TIT',
    'PHM',
    'HEB',
    'JAS',
    '1PE',
    '2PE',
    '1JN',
    '2JN',
    '3JN',
    'JUD',
    'REV',
  ];

  @override
  Future<List<BibleBrainBibleSummary>> listBibles({
    String? languageCode,
    String? media,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'v': '4',
      'key': apiKey,
      'limit': '$limit',
    };
    if (languageCode != null && languageCode.isNotEmpty) {
      query['language_code'] = languageCode;
    }
    if (media != null && media.isNotEmpty) {
      query['media'] = media;
    }
    final cacheKey = 'bibles_${languageCode ?? 'all'}_${media ?? 'any'}_$limit';
    final payload = await _cachedJson(
      cacheKey,
      apiBase.resolve('bibles').replace(queryParameters: query),
    );
    final results = <BibleBrainBibleSummary>[];
    final seen = <String>{};
    for (final value in _topLevelMaps(payload)) {
      final id = _string(value, const ['id', 'bible_id', 'abbr']);
      final name = _string(value, const ['name', 'vname', 'title']);
      if (id == null || name == null || !seen.add(id)) continue;
      final iso = _string(value, const ['iso', 'language_iso', 'language']) ??
          languageCode ??
          '';
      final languageName = _string(
            value,
            const ['language_name', 'languageName', 'autonym'],
          ) ??
          iso;
      final abbreviation =
          _string(value, const ['abbr', 'abbreviation', 'id']) ?? id;
      final mediaTypes = _collectMediaTypes(value);
      results.add(
        BibleBrainBibleSummary(
          id: id,
          name: name,
          abbreviation: abbreviation,
          languageIso: iso,
          languageName: languageName,
          hasAudio: mediaTypes.any((type) => type.contains('audio')),
          hasText: mediaTypes.any((type) => type.contains('text')),
        ),
      );
    }
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  @override
  Future<List<BibleBook>> books(String bibleId) async {
    final payload = await _cachedJson(
      'books_$bibleId',
      apiBase.resolve('bibles/$bibleId/book').replace(
        queryParameters: {'v': '4', 'key': apiKey},
      ),
    );
    final books = <BibleBook>[];
    for (final value in _topLevelMaps(payload)) {
      final bookCode = _string(
        value,
        const ['book_id', 'id', 'book_id_osis', 'abbr'],
      );
      final name = _string(value, const ['name', 'name_short', 'book_name']);
      if (bookCode == null || name == null) continue;
      final index = bookCodes.indexOf(bookCode.toUpperCase());
      if (index < 0) continue;
      final chapters = _integer(
            value,
            const ['chapters', 'number_of_chapters', 'chapter_count'],
          ) ??
          0;
      if (chapters <= 0) continue;
      final bookId = index + 1;
      books.add(
        BibleBook(
          id: bookId,
          name: name,
          chapters: chapters,
          testament: bookId <= 39 ? 'OT' : 'NT',
        ),
      );
    }
    books.sort((a, b) => a.id.compareTo(b.id));
    final unique = <int, BibleBook>{for (final book in books) book.id: book};
    return unique.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<List<BibleBrainFileset>> audioFilesets(String bibleId) async {
    return _filesets(bibleId, audioOnly: true);
  }

  @override
  Future<List<BibleBrainFileset>> textFilesets(String bibleId) async {
    return _filesets(bibleId, audioOnly: false, textOnly: true);
  }

  Future<List<BibleBrainFileset>> _filesets(
    String bibleId, {
    bool audioOnly = false,
    bool textOnly = false,
  }) async {
    final bible = await _cachedJson(
      'bible_$bibleId',
      apiBase.resolve('bibles/$bibleId').replace(
        queryParameters: {
          'v': '4',
          'key': apiKey,
          'verify_content': 'true',
          'verify_segmentation': 'true',
        },
      ),
    );
    final downloads = await _downloadableFilesets();
    final candidates = <BibleBrainFileset>[];
    for (final value in _maps(bible)) {
      final id = _string(value, const ['id', 'fileset_id']);
      final type = _string(
        value,
        const ['type', 'set_type_code', 'media', 'media_type'],
      );
      if (id == null || type == null) continue;
      final lower = type.toLowerCase();
      if (audioOnly && !lower.contains('audio')) continue;
      if (textOnly && !lower.contains('text')) continue;
      candidates.add(
        BibleBrainFileset(
          id: id,
          mediaType: type,
          downloadPermitted: downloads.contains(id),
          segmentationType: _string(
            value,
            const ['segmentation_type', 'segmentationType'],
          ),
        ),
      );
    }
    final unique = <String, BibleBrainFileset>{
      for (final fileset in candidates) fileset.id: fileset,
    }.values.toList();
    unique.sort((a, b) {
      if (a.downloadPermitted != b.downloadPermitted) {
        return a.downloadPermitted ? -1 : 1;
      }
      return a.id.compareTo(b.id);
    });
    return unique;
  }

  Future<Set<String>> _downloadableFilesets() async {
    final payload = await _cachedJson(
      'download_list',
      apiBase.resolve('download/list').replace(
        queryParameters: {
          'v': '4',
          'key': apiKey,
          'type': 'audio',
          'limit': '1000',
        },
      ),
    );
    return _maps(payload)
        .map((value) => _string(value, const ['id', 'fileset_id']))
        .whereType<String>()
        .toSet();
  }

  @override
  Future<List<AudioVerseTiming>> chapterTimings({
    required String filesetId,
    required String bookCode,
    required int chapter,
  }) async {
    final payload = await _cachedJson(
      'timing_${filesetId}_${bookCode}_$chapter',
      apiBase.resolve('timestamps/$filesetId/$bookCode/$chapter').replace(
        queryParameters: {'v': '4', 'key': apiKey},
      ),
    );
    final timings = <AudioVerseTiming>[];
    for (final value in _maps(payload)) {
      final verse =
          _integer(value, const ['verse_start', 'verse', 'verse_number']);
      final start = _seconds(value, const ['timestamp', 'start', 'start_time']);
      if (verse == null || start == null) continue;
      final end = _seconds(value, const ['end', 'end_time']);
      timings.add(
        AudioVerseTiming(
          verse: verse,
          start: Duration(milliseconds: (start * 1000).round()),
          end:
              end == null ? null : Duration(milliseconds: (end * 1000).round()),
        ),
      );
    }
    timings.sort((a, b) => a.start.compareTo(b.start));
    return timings;
  }

  Set<String> _collectMediaTypes(Map<String, dynamic> value) {
    final types = <String>{};
    void walk(Object? node) {
      if (node is Map) {
        final map = Map<String, dynamic>.from(node);
        final type = _string(
          map,
          const ['type', 'set_type_code', 'media', 'media_type'],
        );
        if (type != null) types.add(type.toLowerCase());
        for (final nested in map.values) {
          walk(nested);
        }
      } else if (node is List) {
        for (final nested in node) {
          walk(nested);
        }
      }
    }

    walk(value);
    return types;
  }

  Future<Object?> _cachedJson(String key, Uri uri) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final timestamp = preferences.getInt('bible_brain_${key}_cached_at');
    final cached = preferences.getString('bible_brain_$key');
    if (timestamp != null &&
        cached != null &&
        DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
            ) <
            _cacheLifetime) {
      return jsonDecode(cached);
    }
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Bible Brain returned ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    await preferences.setString('bible_brain_$key', response.body);
    await preferences.setInt(
      'bible_brain_${key}_cached_at',
      DateTime.now().millisecondsSinceEpoch,
    );
    return decoded;
  }

  Iterable<Map<String, dynamic>> _topLevelMaps(Object? value) sync* {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final data = map['data'];
      if (data != null) {
        yield* _topLevelMaps(data);
        return;
      }
      yield map;
      return;
    }
    if (value is List) {
      for (final nested in value) {
        if (nested is Map) {
          yield Map<String, dynamic>.from(nested);
        }
      }
    }
  }

  Iterable<Map<String, dynamic>> _maps(Object? value) sync* {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      yield map;
      for (final nested in map.values) {
        yield* _maps(nested);
      }
    } else if (value is List) {
      for (final nested in value) {
        yield* _maps(nested);
      }
    }
  }

  String? _string(Map<String, dynamic> value, List<String> keys) {
    for (final key in keys) {
      final item = value[key];
      if (item is String && item.isNotEmpty) return item;
    }
    return null;
  }

  int? _integer(Map<String, dynamic> value, List<String> keys) {
    for (final key in keys) {
      final item = value[key];
      if (item is int) return item;
      if (item is String) {
        final parsed = int.tryParse(item);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  double? _seconds(Map<String, dynamic> value, List<String> keys) {
    for (final key in keys) {
      final item = value[key];
      if (item is num) return item.toDouble();
      if (item is String) {
        final parsed = double.tryParse(item);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
