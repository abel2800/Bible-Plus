class BibleBook {
  final int id;
  final String name;
  final int chapters;
  final String testament;

  BibleBook({
    required this.id,
    required this.name,
    required this.chapters,
    required this.testament,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as int,
      name: json['name'] as String,
      chapters: json['chapters'] as int,
      testament: json['testament'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chapters': chapters,
      'testament': testament,
    };
  }
}
