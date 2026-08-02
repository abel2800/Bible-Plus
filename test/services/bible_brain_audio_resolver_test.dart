import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bible_pulse/models/bible_book.dart';
import 'package:bible_pulse/services/bible_brain_audio_resolver.dart';
import 'package:bible_pulse/services/bible_brain_catalog_service.dart';
import 'package:bible_pulse/services/audio_contracts.dart';

void main() {
  test('resolves an approved HTTPS Bible Brain media URL', () async {
    final resolver = BibleBrainAudioResolver(
      apiKey: 'test-key',
      versionBibleIds: const {'WEB': 'ENGWEB'},
      allowedMediaHosts: const {'media.example.test'},
      catalog: const _FakeCatalog(downloadPermitted: false),
      client: MockClient((request) async {
        expect(request.url.path, contains('/ENGWEBN2DA/JHN/3'));
        expect(request.url.queryParameters['key'], 'test-key');
        return http.Response(
          '{"data":[{"path":"https://media.example.test/john-3.mp3"}]}',
          200,
        );
      }),
    );

    final source = await resolver.resolve(
      versionId: 'WEB',
      bookId: 43,
      chapter: 3,
    );

    expect(source?.uri.host, 'media.example.test');
    expect(source?.downloadPermitted, isFalse);
  });

  test('rejects media from an unapproved host', () async {
    final resolver = BibleBrainAudioResolver(
      apiKey: 'test-key',
      versionBibleIds: const {'WEB': 'ENGWEB'},
      allowedMediaHosts: const {'approved.example.test'},
      catalog: const _FakeCatalog(downloadPermitted: false),
      client: MockClient(
        (_) async => http.Response(
          '{"data":[{"path":"https://evil.example/audio.mp3"}]}',
          200,
        ),
      ),
    );

    expect(
      () => resolver.resolve(versionId: 'WEB', bookId: 43, chapter: 3),
      throwsStateError,
    );
  });
}

class _FakeCatalog implements BibleBrainCatalogGateway {
  const _FakeCatalog({required this.downloadPermitted});

  final bool downloadPermitted;

  @override
  Future<List<BibleBrainFileset>> audioFilesets(String bibleId) async => [
        BibleBrainFileset(
          id: 'ENGWEBN2DA',
          mediaType: 'audio',
          downloadPermitted: downloadPermitted,
        ),
      ];

  @override
  Future<List<BibleBrainFileset>> textFilesets(String bibleId) async =>
      const [];

  @override
  Future<List<BibleBrainBibleSummary>> listBibles({
    String? languageCode,
    String? media,
    int limit = 50,
  }) async =>
      const [];

  @override
  Future<List<BibleBook>> books(String bibleId) async => const [];

  @override
  Future<List<AudioVerseTiming>> chapterTimings({
    required String filesetId,
    required String bookCode,
    required int chapter,
  }) async =>
      const [];
}
