class AudioQueueItem {
  const AudioQueueItem({
    required this.versionId,
    required this.bookId,
    required this.chapter,
    required this.bookName,
    this.voiceLabel,
    this.verseCharWeights,
    this.audioPackageId,
  });

  final String versionId;
  final int bookId;
  final int chapter;
  final String bookName;
  final String? voiceLabel;

  /// Character lengths per verse — used to estimate follow-along highlighting.
  final List<int>? verseCharWeights;
  final String? audioPackageId;

  String get title => '$bookName $chapter';

  AudioQueueItem copyWith({
    String? versionId,
    int? bookId,
    int? chapter,
    String? bookName,
    String? voiceLabel,
    List<int>? verseCharWeights,
    String? audioPackageId,
  }) {
    return AudioQueueItem(
      versionId: versionId ?? this.versionId,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      bookName: bookName ?? this.bookName,
      voiceLabel: voiceLabel ?? this.voiceLabel,
      verseCharWeights: verseCharWeights ?? this.verseCharWeights,
      audioPackageId: audioPackageId ?? this.audioPackageId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AudioQueueItem &&
        other.versionId == versionId &&
        other.bookId == bookId &&
        other.chapter == chapter &&
        other.bookName == bookName &&
        other.voiceLabel == voiceLabel &&
        other.audioPackageId == audioPackageId &&
        _listEquals(other.verseCharWeights, verseCharWeights);
  }

  @override
  int get hashCode => Object.hash(
        versionId,
        bookId,
        chapter,
        bookName,
        voiceLabel,
        audioPackageId,
        verseCharWeights == null ? null : Object.hashAll(verseCharWeights!),
      );
}

bool _listEquals(List<int>? a, List<int>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
