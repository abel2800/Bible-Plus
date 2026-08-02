import '../utils/scripture_text.dart';

class BibleVerse {
  final int id;
  final int book;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required String text,
  }) : text = ScriptureText.clean(text);

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      id: json['id'] as int,
      book: json['book'] as int,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
    };
  }
}
