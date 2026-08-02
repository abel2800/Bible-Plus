import 'audio_contracts.dart';

class PersistentAudioChapterCache implements AudioChapterCache {
  PersistentAudioChapterCache();

  @override
  Future<Uri?> lookup(String cacheKey, AudioChapterSource source) async => null;

  @override
  Future<bool> has(String cacheKey) async => false;

  @override
  Future<Uri> prepare(
    String cacheKey,
    AudioChapterSource source, {
    required int maxBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    return source.uri;
  }

  @override
  Future<int> sizeBytes() async => 0;

  @override
  Future<void> clear() async {}
}
