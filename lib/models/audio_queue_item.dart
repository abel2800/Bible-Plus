class AudioQueueItem {
  const AudioQueueItem({
    required this.versionId,
    required this.bookId,
    required this.chapter,
    required this.bookName,
    this.voiceLabel,
  });

  final String versionId;
  final int bookId;
  final int chapter;
  final String bookName;
  final String? voiceLabel;

  String get title => '$bookName $chapter';

  AudioQueueItem copyWith({
    String? versionId,
    int? bookId,
    int? chapter,
    String? bookName,
    String? voiceLabel,
  }) {
    return AudioQueueItem(
      versionId: versionId ?? this.versionId,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      bookName: bookName ?? this.bookName,
      voiceLabel: voiceLabel ?? this.voiceLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AudioQueueItem &&
        other.versionId == versionId &&
        other.bookId == bookId &&
        other.chapter == chapter &&
        other.bookName == bookName &&
        other.voiceLabel == voiceLabel;
  }

  @override
  int get hashCode => Object.hash(
        versionId,
        bookId,
        chapter,
        bookName,
        voiceLabel,
      );
}
