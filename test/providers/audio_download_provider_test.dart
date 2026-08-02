import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_pulse/providers/audio_download_provider.dart';
import 'package:bible_pulse/services/audio_contracts.dart';

void main() {
  test('explicit download rejects streaming-only filesets', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AudioDownloadProvider(
      resolver: const _StreamingResolver(),
      cache: _FakeCache(),
    );
    await provider.initialize();
    await provider.setWifiOnly(false);

    await provider.downloadChapters(
      versionId: 'WEB',
      chapters: const [(bookId: 43, chapter: 3)],
    );

    expect(provider.error, contains('streaming only'));
    expect(provider.completedChapters, 0);
  });
}

class _StreamingResolver implements AudioChapterResolver {
  const _StreamingResolver();

  @override
  Future<AudioChapterSource?> resolve({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    return AudioChapterSource(
      uri: Uri.parse('https://media.example.test/chapter.mp3'),
      filesetId: 'STREAM_ONLY',
      attribution: 'Test',
      downloadPermitted: false,
    );
  }
}

class _FakeCache implements AudioChapterCache {
  @override
  Future<void> clear() async {}

  @override
  Future<bool> has(String cacheKey) async => false;

  @override
  Future<Uri?> lookup(String cacheKey, AudioChapterSource source) async => null;

  @override
  Future<Uri> prepare(
    String cacheKey,
    AudioChapterSource source, {
    required int maxBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async =>
      source.uri;

  @override
  Future<int> sizeBytes() async => 0;
}
