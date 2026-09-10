import 'audio_contracts.dart';

/// Routes playback to a specific audio package resolver, with composite fallback.
class CatalogAudioResolver implements AudioChapterResolver {
  CatalogAudioResolver({
    required Map<String, AudioChapterResolver> packageResolvers,
    required AudioChapterResolver fallback,
  })  : _packageResolvers = packageResolvers,
        _fallback = fallback;

  final Map<String, AudioChapterResolver> _packageResolvers;
  final AudioChapterResolver _fallback;
  String? _activePackageId;

  Map<String, AudioChapterResolver> get packageResolvers =>
      Map.unmodifiable(_packageResolvers);

  void setActivePackageId(String? packageId) {
    _activePackageId = packageId;
  }

  AudioChapterResolver? resolverForPackage(String packageId) =>
      _packageResolvers[packageId];

  @override
  Future<AudioChapterSource?> resolve({
    required String versionId,
    required int bookId,
    required int chapter,
  }) async {
    if (_activePackageId != null) {
      final scoped = _packageResolvers[_activePackageId];
      if (scoped != null) {
        return scoped.resolve(
          versionId: versionId,
          bookId: bookId,
          chapter: chapter,
        );
      }
      return null;
    }
    return _fallback.resolve(
      versionId: versionId,
      bookId: bookId,
      chapter: chapter,
    );
  }
}
