class Bookmark {
  final String id;
  final String verseReference;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ownerId;
  final String versionId;
  final String? canonicalVerseId;
  final int syncVersion;
  final DateTime? deletedAt;

  Bookmark({
    required this.id,
    required this.verseReference,
    required this.text,
    required this.createdAt,
    DateTime? updatedAt,
    this.ownerId = 'guest',
    this.versionId = 'WEB',
    this.canonicalVerseId,
    this.syncVersion = 0,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      verseReference: json['verseReference'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.parse(json['createdAt'] as String),
      ownerId: json['ownerId'] as String? ?? 'guest',
      versionId: json['versionId'] as String? ?? 'WEB',
      canonicalVerseId: json['canonicalVerseId'] as String?,
      syncVersion: json['syncVersion'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verseReference': verseReference,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'ownerId': ownerId,
      'versionId': versionId,
      'canonicalVerseId': canonicalVerseId,
      'syncVersion': syncVersion,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
