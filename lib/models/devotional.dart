class Devotional {
  final String id;
  final DateTime date;
  final String dailyVerse;
  final String verseReference;
  final String dailyPrayer;
  final String? imageUrl;

  Devotional({
    required this.id,
    required this.date,
    required this.dailyVerse,
    required this.verseReference,
    required this.dailyPrayer,
    this.imageUrl,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      dailyVerse: json['dailyVerse'] as String,
      verseReference: json['verseReference'] as String,
      dailyPrayer: json['dailyPrayer'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'dailyVerse': dailyVerse,
      'verseReference': verseReference,
      'dailyPrayer': dailyPrayer,
      'imageUrl': imageUrl,
    };
  }
}
