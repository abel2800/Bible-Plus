import 'dart:convert';

import 'package:http/http.dart' as http;

import 'audio_contracts.dart';
import 'bible_brain_catalog_service.dart';
import 'bible_brain_version_registry.dart';

class BibleBrainAudioResolver
    implements AudioChapterResolver, AudioTimingResolver {
  BibleBrainAudioResolver({
    required this.apiKey,
    required this.versionBibleIds,
    required this.allowedMediaHosts,
    required this.catalog,
    this.versions,
    http.Client? client,
    Uri? apiBase,
  })  : apiBase = apiBase ?? Uri.parse('https://4.dbt.io/api/'),
        _client = client ?? http.Client();

  final String apiKey;
  final Map<String, String> versionBibleIds;
  final BibleBrainVersionRegistry? versions;
  final Set<String> allowedMediaHosts;
  final BibleBrainCatalogGateway catalog;
  final http.Client _client;
  final Uri apiBase;

  String? _bibleIdFor(String versionId) =>
      versions?.bibleIdFor(versionId) ?? versionBibleIds[versionId];

  @override
  Future<AudioChapterSource?> resolve({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    final bibleId = _bibleIdFor(versionId);
    final bookCodes = BibleBrainCatalogService.bookCodes;
    if (bibleId == null || bookId < 1 || bookId > bookCodes.length) {
      return null;
    }
    final filesets = await catalog.audioFilesets(bibleId);
    if (filesets.isEmpty) return null;
    final fileset = filesets.first;
    final endpoint = apiBase.resolve(
      'bibles/filesets/${fileset.id}/${bookCodes[bookId - 1]}/$chapter',
    );
    final uri = endpoint.replace(queryParameters: {'v': '4', 'key': apiKey});
    final response = await _client.get(uri);
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Bible Brain returned ${response.statusCode}.');
    }
    final payload = jsonDecode(response.body);
    final mediaUri = _findHttpsMediaUri(payload);
    if (mediaUri == null || !allowedMediaHosts.contains(mediaUri.host)) {
      throw StateError('Bible Brain returned an unapproved media host.');
    }
    return AudioChapterSource(
      uri: mediaUri,
      filesetId: fileset.id,
      attribution: 'Audio provided by Faith Comes By Hearing / Bible Brain',
      downloadPermitted: fileset.downloadPermitted,
    );
  }

  @override
  Future<List<AudioVerseTiming>> resolveTimings({
    required String filesetId,
    required int bookId,
    required int chapter,
  }) {
    final bookCodes = BibleBrainCatalogService.bookCodes;
    if (bookId < 1 || bookId > bookCodes.length) {
      return Future.value(const []);
    }
    return catalog.chapterTimings(
      filesetId: filesetId,
      bookCode: bookCodes[bookId - 1],
      chapter: chapter,
    );
  }

  Uri? _findHttpsMediaUri(Object? value) {
    if (value is String) {
      final uri = Uri.tryParse(value);
      return uri?.scheme == 'https' ? uri : null;
    }
    if (value is List) {
      for (final item in value) {
        final found = _findHttpsMediaUri(item);
        if (found != null) return found;
      }
    }
    if (value is Map) {
      const preferred = ['path', 'url', 'uri', 'cdn'];
      for (final key in preferred) {
        if (value.containsKey(key)) {
          final found = _findHttpsMediaUri(value[key]);
          if (found != null) return found;
        }
      }
      for (final item in value.values) {
        final found = _findHttpsMediaUri(item);
        if (found != null) return found;
      }
    }
    return null;
  }
}
