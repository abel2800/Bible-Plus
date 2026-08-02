class AudioChapterSource {
  const AudioChapterSource({
    required this.uri,
    required this.filesetId,
    required this.attribution,
    required this.downloadPermitted,
    this.sha256,
    this.expiresAt,
  });

  final Uri uri;
  final String filesetId;
  final String attribution;
  final bool downloadPermitted;
  final String? sha256;
  final DateTime? expiresAt;
}

class AudioVerseTiming {
  const AudioVerseTiming({
    required this.verse,
    required this.start,
    this.end,
  });

  final int verse;
  final Duration start;
  final Duration? end;
}

abstract interface class AudioChapterResolver {
  Future<AudioChapterSource?> resolve({
    required String versionId,
    required int bookId,
    required int chapter,
  });
}

abstract interface class AudioTimingResolver {
  Future<List<AudioVerseTiming>> resolveTimings({
    required String filesetId,
    required int bookId,
    required int chapter,
  });
}

abstract interface class AudioChapterCache {
  Future<Uri?> lookup(String cacheKey, AudioChapterSource source);

  Future<bool> has(String cacheKey);

  Future<Uri> prepare(
    String cacheKey,
    AudioChapterSource source, {
    required int maxBytes,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  });

  Future<int> sizeBytes();
  Future<void> clear();
}
