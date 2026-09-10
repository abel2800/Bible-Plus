import 'package:flutter/material.dart';

class ReaderColorTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color verseNumberColor;
  final Color headerColor;
  final Color accentColor;
  final Color surfaceColor;
  final bool isDark;
  final bool isGlass;

  const ReaderColorTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.verseNumberColor,
    required this.headerColor,
    required this.accentColor,
    required this.surfaceColor,
    this.isDark = false,
    this.isGlass = false,
  });

  factory ReaderColorTheme.fromJson(Map<String, dynamic> json) {
    final theme = getById(json['id'] as String? ?? 'dark');
    return theme ??
        ReaderColorTheme(
          id: json['id'],
          name: json['name'],
          backgroundColor: Color(json['backgroundColor']),
          textColor: Color(json['textColor']),
          verseNumberColor: Color(json['verseNumberColor']),
          headerColor: Color(json['headerColor']),
          accentColor: Color(json['accentColor'] ?? json['verseNumberColor']),
          surfaceColor: Color(json['surfaceColor'] ?? json['backgroundColor']),
          isDark: json['isDark'] ?? false,
          isGlass: json['isGlass'] ?? false,
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
      'accentColor': accentColor.toARGB32(),
      'surfaceColor': surfaceColor.toARGB32(),
      'isDark': isDark,
      'isGlass': isGlass,
    };
  }

  /// Five reading themes from the Bible Plus design system (gold + glass UI).
  static List<ReaderColorTheme> get presets => [
        const ReaderColorTheme(
          id: 'dark',
          name: 'Night',
          backgroundColor: Color(0xFF0D0C0A),
          textColor: Color(0xFFF5F3EE),
          verseNumberColor: Color(0xFF6F6A61),
          headerColor: Color(0xFFF5F3EE),
          accentColor: Color(0xFFBD9A4C),
          surfaceColor: Color(0xFF161512),
          isDark: true,
        ),
        const ReaderColorTheme(
          id: 'light',
          name: 'Parchment',
          backgroundColor: Color(0xFFF4EFE3),
          textColor: Color(0xFF1A1815),
          verseNumberColor: Color(0xFFA09A8F),
          headerColor: Color(0xFF1A1815),
          accentColor: Color(0xFFB08A28),
          surfaceColor: Color(0xFFFFFFFF),
          isDark: false,
        ),
        const ReaderColorTheme(
          id: 'sepia',
          name: 'Sepia',
          backgroundColor: Color(0xFFE9DCC3),
          textColor: Color(0xFF3E3428),
          verseNumberColor: Color(0xFF8A7A66),
          headerColor: Color(0xFF3E3428),
          accentColor: Color(0xFFB08A28),
          surfaceColor: Color(0xFFF3EBD8),
          isDark: false,
        ),
        const ReaderColorTheme(
          id: 'void',
          name: 'Void',
          backgroundColor: Color(0xFF050910),
          textColor: Color(0xFFEEF3F8),
          verseNumberColor: Color(0xFF5C6E86),
          headerColor: Color(0xFFEEF3F8),
          accentColor: Color(0xFFBD9A4C),
          surfaceColor: Color(0xFF0A0E16),
          isDark: true,
        ),
        const ReaderColorTheme(
          id: 'glass',
          name: 'Glass',
          backgroundColor: Color(0xFF0A1526),
          textColor: Color(0xFFDBE4EE),
          verseNumberColor: Color(0xFF5C6E86),
          headerColor: Color(0xFFEEF3F8),
          accentColor: Color(0xFF5EE6D0),
          surfaceColor: Color(0x1FFFFFFF),
          isDark: true,
          isGlass: true,
        ),
      ];

  static String normalizeId(String id) {
    switch (id) {
      case 'eye_comfort':
      case 'parchment_warm':
        return 'sepia';
      case 'black':
      case 'blue_night':
      case 'forest':
      case 'gold_night':
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
