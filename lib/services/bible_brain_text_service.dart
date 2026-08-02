import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import 'bible_brain_catalog_service.dart';

abstract interface class BibleBrainTextGateway {
  Future<List<BibleBook>> books(String bibleId);
  Future<List<BibleVerse>> chapter({
    required String bibleId,
    required int bookId,
    required int chapter,
  });
}

class BibleBrainTextService implements BibleBrainTextGateway {
  BibleBrainTextService({
    required this.apiKey,
    required this.catalog,
    http.Client? client,
    Uri? apiBase,
  })  : apiBase = apiBase ?? Uri.parse('https://4.dbt.io/api/'),
        _client = client ?? http.Client();

  final String apiKey;
  final BibleBrainCatalogGateway catalog;
  final http.Client _client;
  final Uri apiBase;

  static const bookCodes = BibleBrainCatalogService.bookCodes;

  @override
  Future<List<BibleBook>> books(String bibleId) {
    return catalog.books(bibleId);
  }

  @override
  Future<List<BibleVerse>> chapter({
    required String bibleId,
    required int bookId,
    required int chapter,
  }) async {
    if (bookId < 1 || bookId > bookCodes.length) return const [];
    final bookCode = bookCodes[bookId - 1];
    final endpoint =
        apiBase.resolve('bible/$bibleId/verses/$bookCode/$chapter');
    final uri = endpoint.replace(
      queryParameters: {
        'v': '4',
        'key': apiKey,
        'chapter': '$chapter',
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode == 404) return const [];
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Bible Brain returned ${response.statusCode}.');
    }
    final payload = jsonDecode(response.body);
    final verses = <BibleVerse>[];
    for (final value in _maps(payload)) {
      final verseNumber = _integer(
        value,
        const ['verse_start', 'verse', 'verse_number', 'verse_sequence'],
      );
      final text = _string(
        value,
        const ['verse_text', 'text', 'content'],
      );
      if (verseNumber == null || text == null || text.trim().isEmpty) continue;
      verses.add(
        BibleVerse(
          id: verseNumber,
          book: bookId,
          chapter: chapter,
          verse: verseNumber,
          text: text,
        ),
      );
    }
    verses.sort((a, b) => a.verse.compareTo(b.verse));
    final unique = <int, BibleVerse>{
      for (final verse in verses) verse.verse: verse,
    };
    return unique.values.toList()..sort((a, b) => a.verse.compareTo(b.verse));
  }

  Iterable<Map<String, dynamic>> _maps(Object? value) sync* {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final data = map['data'];
      if (data != null) {
        yield* _maps(data);
        return;
      }
      yield map;
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
}
