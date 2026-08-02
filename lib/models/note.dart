class Note {
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

  Note({
    required this.id,
    required this.verseReference,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId = 'guest',
    this.versionId = 'WEB',
    this.canonicalVerseId,
    this.syncVersion = 0,
    this.deletedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      verseReference: json['verseReference'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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

  Note copyWith({
    String? id,
    String? verseReference,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerId,
    String? versionId,
    String? canonicalVerseId,
    int? syncVersion,
    DateTime? deletedAt,
  }) {
    return Note(
      id: id ?? this.id,
      verseReference: verseReference ?? this.verseReference,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      versionId: versionId ?? this.versionId,
      canonicalVerseId: canonicalVerseId ?? this.canonicalVerseId,
      syncVersion: syncVersion ?? this.syncVersion,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
