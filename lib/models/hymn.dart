class Hymn {
  final String id;
  final String number;
  final String title;
  final String? subtitle;
  final List<String> verses;
  final String? chorus;
  final String? author;
  final String? composer;
  final int? year;
  final String? category;
  final List<String> tags;
  final String? tune;
  final String? scripture;
  final String? audioUrl;

  Hymn({
    required this.id,
    required this.number,
    required this.title,
    this.subtitle,
    required this.verses,
    this.chorus,
    this.author,
    this.composer,
    this.year,
    this.category,
    List<String>? tags,
    this.tune,
    this.scripture,
    this.audioUrl,
  }) : tags = tags ?? [];

  factory Hymn.fromJson(Map<String, dynamic> json) {
    return Hymn(
      id: json['id'] ?? '',
      number: json['number'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      verses: List<String>.from(json['verses'] ?? []),
      chorus: json['chorus'],
      author: json['author'],
      composer: json['composer'],
      year: json['year'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      tune: json['tune'],
      scripture: json['scripture'],
      audioUrl: json['audioUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'subtitle': subtitle,
      'verses': verses,
      'chorus': chorus,
      'author': author,
      'composer': composer,
      'year': year,
      'category': category,
      'tags': tags,
      'tune': tune,
      'scripture': scripture,
      'audioUrl': audioUrl,
    };
  }

  String get fullText {
    final buffer = StringBuffer();

    for (var i = 0; i < verses.length; i++) {
      buffer.writeln('${i + 1}. ${verses[i]}');

      if (chorus != null && i < verses.length - 1) {
        buffer.writeln('\nChorus:');
        buffer.writeln(chorus);
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
