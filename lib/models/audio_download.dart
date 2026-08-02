class AudioDownload {
  const AudioDownload({
    required this.versionId,
    required this.filesetId,
    required this.bookId,
    required this.chapter,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSize,
    this.sha256,
  });

  final String versionId;
  final String filesetId;
  final int bookId;
  final int chapter;
  final String localPath;
  final DateTime downloadedAt;
  final int fileSize;
  final String? sha256;

  factory AudioDownload.fromJson(Map<String, dynamic> json) {
    return AudioDownload(
      versionId: json['versionId'] as String,
      filesetId: json['filesetId'] as String,
      bookId: json['bookId'] as int,
      chapter: json['chapter'] as int,
      localPath: json['localPath'] as String,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      fileSize: json['fileSize'] as int,
      sha256: json['sha256'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'versionId': versionId,
        'filesetId': filesetId,
        'bookId': bookId,
        'chapter': chapter,
        'localPath': localPath,
        'downloadedAt': downloadedAt.toUtc().toIso8601String(),
        'fileSize': fileSize,
        'sha256': sha256,
      };
}
