enum JourneySessionType { reading, listening }

class JourneySession {
  const JourneySession({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.bookId,
    this.bookName,
    this.chapter,
    this.startVerse,
    this.endVerse,
    this.completedChapters = 0,
    this.syncVersion = 0,
  });

  final String id;
  final String ownerId;
  final JourneySessionType type;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? bookId;
  final String? bookName;
  final int? chapter;
  final int? startVerse;
  final int? endVerse;
  final int completedChapters;
  final int syncVersion;

  Map<String, Object?> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'type': type.name,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt?.toUtc().toIso8601String(),
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'bookId': bookId,
        'bookName': bookName,
        'chapter': chapter,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'completedChapters': completedChapters,
        'syncVersion': syncVersion,
      };

  factory JourneySession.fromJson(Map<String, Object?> json) {
    return JourneySession(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? 'guest',
      type: JourneySessionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => JourneySessionType.reading,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String).toUtc(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      bookId: (json['bookId'] as num?)?.toInt(),
      bookName: json['bookName'] as String?,
      chapter: (json['chapter'] as num?)?.toInt(),
      startVerse: (json['startVerse'] as num?)?.toInt(),
      endVerse: (json['endVerse'] as num?)?.toInt(),
      completedChapters: (json['completedChapters'] as num?)?.toInt() ?? 0,
      syncVersion: (json['syncVersion'] as num?)?.toInt() ?? 0,
    );
  }

  JourneySession copyWith({
    String? ownerId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    DateTime? updatedAt,
    int? endVerse,
    int? completedChapters,
    int? syncVersion,
  }) =>
      JourneySession(
        id: id,
        ownerId: ownerId ?? this.ownerId,
        type: type,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        bookId: bookId,
        bookName: bookName,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse ?? this.endVerse,
        completedChapters: completedChapters ?? this.completedChapters,
        syncVersion: syncVersion ?? this.syncVersion,
      );
}
