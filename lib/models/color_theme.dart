import 'package:flutter/material.dart';

class ReaderColorTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color verseNumberColor;
  final Color headerColor;
  final bool isDark;

  const ReaderColorTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.verseNumberColor,
    required this.headerColor,
    this.isDark = false,
  });

  factory ReaderColorTheme.fromJson(Map<String, dynamic> json) {
    return ReaderColorTheme(
      id: json['id'],
      name: json['name'],
      backgroundColor: Color(json['backgroundColor']),
      textColor: Color(json['textColor']),
      verseNumberColor: Color(json['verseNumberColor']),
      headerColor: Color(json['headerColor']),
      isDark: json['isDark'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backgroundColor': backgroundColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'verseNumberColor': verseNumberColor.toARGB32(),
      'headerColor': headerColor.toARGB32(),
      'isDark': isDark,
    };
  }

  static List<ReaderColorTheme> get presets => [
        const ReaderColorTheme(
          id: 'light',
          name: 'Light',
          backgroundColor: Color(0xFFFFFFFF),
          textColor: Color(0xFF1A1A1A),
          verseNumberColor: Color(0xFFC08A28),
          headerColor: Color(0xFF1A1A1A),
          isDark: false,
        ),
        const ReaderColorTheme(
          id: 'dark',
          name: 'Dark',
          backgroundColor: Color(0xFF10182A),
          textColor: Color(0xFFF1E9D6),
          verseNumberColor: Color(0xFFE8C766),
          headerColor: Color(0xFFF1E9D6),
          isDark: true,
        ),
        const ReaderColorTheme(
          id: 'eye_comfort',
          name: 'Eye Comfort',
          backgroundColor: Color(0xFFF4ECD8),
          textColor: Color(0xFF4A3B28),
          verseNumberColor: Color(0xFFC08A28),
          headerColor: Color(0xFF3E2F1F),
          isDark: false,
        ),
      ];

  static String normalizeId(String id) {
    switch (id) {
      case 'sepia':
      case 'parchment':
        return 'eye_comfort';
      case 'black':
      case 'blue_night':
      case 'forest':
        return 'dark';
      default:
        return id;
    }
  }

  static ReaderColorTheme? getById(String id) {
    final normalized = normalizeId(id);
    for (final theme in presets) {
      if (theme.id == normalized) return theme;
    }
    return null;
  }
}
