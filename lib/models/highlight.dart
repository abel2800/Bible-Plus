class Highlight {
  final String id;
  final String verseReference;
  final String text;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ownerId;
  final String versionId;
  final String? canonicalVerseId;
  final int syncVersion;
  final DateTime? deletedAt;

  Highlight({
    required this.id,
    required this.verseReference,
    required this.text,
    required this.color,
    required this.createdAt,
    DateTime? updatedAt,
    this.ownerId = 'guest',
    this.versionId = 'WEB',
    this.canonicalVerseId,
    this.syncVersion = 0,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      verseReference: json['verseReference'] as String,
      text: json['text'] as String,
      color: json['color'] as int,
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
      'color': color,
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
