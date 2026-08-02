import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_pulse/services/bible_brain_catalog_service.dart';
import 'package:bible_pulse/services/bible_brain_text_service.dart';

void main() {
  test('discovers audio filesets and applies download permissions', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = BibleBrainCatalogService(
      apiKey: 'test-key',
      preferences: preferences,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/download/list')) {
          return http.Response(
            '{"data":[{"fileset_id":"AMHABC_N2DA"}]}',
            200,
          );
        }
        expect(request.url.path, endsWith('/bibles/AMHABC'));
        return http.Response(
          '{"data":{"filesets":{"AMHABC_N2DA":'
          '{"id":"AMHABC_N2DA","type":"audio",'
          '"segmentation_type":"chapter"}}}}',
          200,
        );
      }),
    );

    final filesets = await service.audioFilesets('AMHABC');

    expect(filesets, hasLength(1));
    expect(filesets.single.id, 'AMHABC_N2DA');
    expect(filesets.single.downloadPermitted, isTrue);
  });

  test('lists bibles for a language code', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = BibleBrainCatalogService(
      apiKey: 'test-key',
      preferences: preferences,
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/bibles'));
        expect(request.url.queryParameters['language_code'], 'am');
        return http.Response(
          '{"data":[{"id":"AMHABC","abbr":"AMH","name":"Amharic Bible",'
          '"iso":"am","language_name":"Amharic",'
          '"filesets":[{"id":"AMHABC_ET","type":"text_plain"},'
          '{"id":"AMHABC_N2DA","type":"audio"}]}]}',
          200,
        );
      }),
    );

    final bibles = await service.listBibles(languageCode: 'am');

    expect(bibles, hasLength(1));
    expect(bibles.single.id, 'AMHABC');
    expect(bibles.single.hasText, isTrue);
    expect(bibles.single.hasAudio, isTrue);
  });

  test('loads chapter verses from Bible Brain text endpoint', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final catalog = BibleBrainCatalogService(
      apiKey: 'test-key',
      preferences: preferences,
      client: MockClient((request) async {
        if (request.url.path.contains('/book')) {
          return http.Response(
            '{"data":[{"book_id":"JHN","name":"John","chapters":21}]}',
            200,
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final text = BibleBrainTextService(
      apiKey: 'test-key',
      catalog: catalog,
      client: MockClient((request) async {
        expect(request.url.path, contains('/bible/AMHABC/verses/JHN/3'));
        return http.Response(
          '{"data":[{"verse_start":16,"verse_text":"For God so loved"},'
          '{"verse_start":17,"verse_text":"For God sent"}]}',
          200,
        );
      }),
    );

    final verses = await text.chapter(
      bibleId: 'AMHABC',
      bookId: 43,
      chapter: 3,
    );

    expect(verses, hasLength(2));
    expect(verses.first.verse, 16);
    expect(verses.first.text, contains('loved'));
  });
}
