import 'package:flutter/material.dart';

class AudioArtworkTheme {
  const AudioArtworkTheme({
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<Color> palette;
  final IconData icon;

  Color get primaryColor => palette.first;
  Color get accentColor => palette.length > 1 ? palette[1] : palette.first;
}
