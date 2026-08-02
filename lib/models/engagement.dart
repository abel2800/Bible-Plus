class StudyMemory {
  const StudyMemory({
    required this.kind,
    required this.reference,
    required this.text,
    required this.createdAt,
  });

  final String kind;
  final String reference;
  final String text;
  final DateTime createdAt;
}

class PrayerEntry {
  const PrayerEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.verseReference,
    this.answeredAt,
  });

  final String id;
  final String text;
  final String? verseReference;
  final DateTime createdAt;
  final DateTime? answeredAt;

  bool get isAnswered => answeredAt != null;

  factory PrayerEntry.fromJson(Map<String, dynamic> json) {
    return PrayerEntry(
      id: json['id'] as String,
      text: json['text'] as String,
      verseReference: json['verseReference'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      answeredAt: json['answeredAt'] == null
          ? null
          : DateTime.parse(json['answeredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'verseReference': verseReference,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'answeredAt': answeredAt?.toUtc().toIso8601String(),
      };

  PrayerEntry copyWith({String? text, DateTime? answeredAt}) => PrayerEntry(
        id: id,
        text: text ?? this.text,
        verseReference: verseReference,
        createdAt: createdAt,
        answeredAt: answeredAt ?? this.answeredAt,
      );
}
