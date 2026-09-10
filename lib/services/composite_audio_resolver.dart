import 'audio_contracts.dart';

/// Tries multiple [AudioChapterResolver] instances in order until one resolves.
class CompositeAudioResolver implements AudioChapterResolver {
  CompositeAudioResolver(this._resolvers);

  final List<AudioChapterResolver> _resolvers;

  @override
  Future<AudioChapterSource?> resolve({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    for (final resolver in _resolvers) {
      final source = await resolver.resolve(
        versionId: versionId,
        bookId: bookId,
        chapter: chapter,
      );
      if (source != null) return source;
    }
    return null;
  }
}

/// Combines chapter resolution with verse timing lookup from a matching resolver.
class CompositeAudioTimingResolver implements AudioTimingResolver {
  CompositeAudioTimingResolver(this._resolvers);

  final List<AudioTimingResolver> _resolvers;

  @override
  Future<List<AudioVerseTiming>> resolveTimings({
    required String filesetId,
    required int bookId,
    required int chapter,
  }) async {
    for (final resolver in _resolvers) {
      final timings = await resolver.resolveTimings(
        filesetId: filesetId,
        bookId: bookId,
        chapter: chapter,
      );
      if (timings.isNotEmpty) return timings;
    }
    return const [];
  }
}
