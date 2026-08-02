import 'package:flutter_test/flutter_test.dart';
import 'package:bible_pulse/services/public_domain_web_audio_resolver.dart';

void main() {
  late PublicDomainWebAudioResolver resolver;

  setUp(() {
    resolver = PublicDomainWebAudioResolver.fromJson({
      'baseUrl': 'https://ebible.org/eng-web/audio/',
      'filesetId': 'web-henson-ebible',
      'attribution': 'Henson PD',
      'downloadPermitted': true,
      'books': [
        {
          'bookId': 1,
          'folder': '01_Genesis',
          'chapters': ['01_01_Genesis_Chapter_One.mp3'],
        },
        {
          'bookId': 40,
          'folder': '40_Matthew',
          'chapters': ['01%200929%20Matthew-Chapter%20One.mp3'],
        },
      ],
    });
  });

  test('resolves WEB Genesis via Henson path', () async {
    final genesis = await resolver.resolve(
      versionId: 'WEB',
      bookId: 1,
      chapter: 1,
    );
    expect(genesis, isNotNull);
    expect(
      genesis!.uri.toString(),
      'https://ebible.org/eng-web/audio/01_Genesis/01_01_Genesis_Chapter_One.mp3',
    );
    expect(genesis.downloadPermitted, isTrue);
  });

  test('resolves Matthew via FCBH NT clean URL for KJV too', () async {
    final matthew = await resolver.resolve(
      versionId: 'kjv',
      bookId: 40,
      chapter: 1,
    );
    expect(matthew, isNotNull);
    expect(
      matthew!.uri.toString(),
      'https://ebible.org/eng-web/mp3/01_01_Matthew.mp3',
    );
  });

  test('rejects unsupported versions', () async {
    expect(
      await resolver.resolve(versionId: 'AMH', bookId: 1, chapter: 1),
      isNull,
    );
    expect(
      await resolver.resolve(versionId: 'WEB', bookId: 1, chapter: 2),
      isNull,
    );
  });
}
