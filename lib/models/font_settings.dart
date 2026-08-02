import 'package:flutter/material.dart';

class FontSettings {
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final FontWeight fontWeight;
  final bool useSystemFont;

  const FontSettings({
    this.fontFamily = 'Merriweather',
    this.fontSize = 18.0,
    this.lineHeight = 1.6,
    this.fontWeight = FontWeight.normal,
    this.useSystemFont = false,
  });

  factory FontSettings.fromJson(Map<String, dynamic> json) {
    return FontSettings(
      fontFamily: json['fontFamily'] ?? 'Merriweather',
      fontSize: (json['fontSize'] ?? 18.0).toDouble(),
      lineHeight: (json['lineHeight'] ?? 1.6).toDouble(),
      fontWeight: FontWeight.values.firstWhere(
        (weight) => weight.value == (json['fontWeight'] ?? 400),
        orElse: () => FontWeight.normal,
      ),
      useSystemFont: json['useSystemFont'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'fontWeight': fontWeight.value,
      'useSystemFont': useSystemFont,
    };
  }

  FontSettings copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    FontWeight? fontWeight,
    bool? useSystemFont,
  }) {
    return FontSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontWeight: fontWeight ?? this.fontWeight,
      useSystemFont: useSystemFont ?? this.useSystemFont,
    );
  }

  TextStyle toTextStyle({Color? color}) {
    return TextStyle(
      fontFamily: useSystemFont ? null : fontFamily,
      fontSize: fontSize,
      height: lineHeight,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

class AvailableFont {
  final String id;
  final String name;
  final String fontFamily;
  final String? description;
  final bool requiresDownload;
  final bool isDownloaded;
  final String? previewText;

  const AvailableFont({
    required this.id,
    required this.name,
    required this.fontFamily,
    this.description,
    this.requiresDownload = false,
    this.isDownloaded = false,
    this.previewText,
  });

  static List<AvailableFont> get defaultFonts => [
        const AvailableFont(
          id: 'system',
          name: 'System Default',
          fontFamily: 'System',
          description: 'Use your device\'s default font',
        ),
        const AvailableFont(
          id: 'roboto',
          name: 'Roboto',
          fontFamily: 'Roboto',
          description: 'Clean and modern',
        ),
        const AvailableFont(
          id: 'merriweather',
          name: 'Merriweather',
          fontFamily: 'Merriweather',
          description: 'Classic serif font',
        ),
        const AvailableFont(
          id: 'open_sans',
          name: 'Open Sans',
          fontFamily: 'Open Sans',
          description: 'Friendly and easy to read',
        ),
        const AvailableFont(
          id: 'lato',
          name: 'Lato',
          fontFamily: 'Lato',
          description: 'Semi-rounded, modern sans-serif',
        ),
        const AvailableFont(
          id: 'source_serif',
          name: 'Source Serif Pro',
          fontFamily: 'Source Serif Pro',
          description: 'Traditional serif typeface',
        ),
        const AvailableFont(
          id: 'libre_baskerville',
          name: 'Libre Baskerville',
          fontFamily: 'Libre Baskerville',
          description: 'Classic book-style font',
        ),
        const AvailableFont(
          id: 'crimson_text',
          name: 'Crimson Text',
          fontFamily: 'Crimson Text',
          description: 'Elegant serif font',
        ),
        const AvailableFont(
          id: 'eb_garamond',
          name: 'EB Garamond',
          fontFamily: 'EB Garamond',
          description: 'Traditional Garamond revival',
        ),
      ];
}
