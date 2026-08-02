import 'package:flutter/material.dart';

import '../models/audio_artwork_theme.dart';

class AudioArtworkService {
  const AudioArtworkService();

  static const AudioArtworkTheme _fallback = AudioArtworkTheme(
    title: 'Scripture Audio',
    subtitle: 'Steady truth for every chapter',
    palette: [
      Color(0xFF1F3A5F),
      Color(0xFF466C96),
      Color(0xFFE0B766),
    ],
    icon: Icons.auto_stories_rounded,
  );

  AudioArtworkTheme forBook(String? bookName) {
    final key = (bookName ?? '').trim().toLowerCase();
    if (key.isEmpty) return _fallback;

    if (key == 'genesis') {
      return const AudioArtworkTheme(
        title: 'Genesis',
        subtitle: 'Earth, light, and beginning',
        palette: [
          Color(0xFF183A2E),
          Color(0xFF507C4D),
          Color(0xFFD8B15A),
        ],
        icon: Icons.landscape_rounded,
      );
    }
    if (key == 'psalms') {
      return const AudioArtworkTheme(
        title: 'Psalms',
        subtitle: 'Songs at sunrise',
        palette: [
          Color(0xFF40205B),
          Color(0xFF8B5FBF),
          Color(0xFFF2C57C),
        ],
        icon: Icons.wb_twilight_rounded,
      );
    }
    if (key == 'john') {
      return const AudioArtworkTheme(
        title: 'John',
        subtitle: 'Light and living water',
        palette: [
          Color(0xFF14385D),
          Color(0xFF4D91D1),
          Color(0xFFBFE3FF),
        ],
        icon: Icons.water_drop_rounded,
      );
    }
    if (key == 'proverbs') {
      return const AudioArtworkTheme(
        title: 'Proverbs',
        subtitle: 'Wisdom shaped in gold',
        palette: [
          Color(0xFF5B3F14),
          Color(0xFFC3912D),
          Color(0xFFF4D788),
        ],
        icon: Icons.lightbulb_rounded,
      );
    }
    if (key == 'revelation') {
      return const AudioArtworkTheme(
        title: 'Revelation',
        subtitle: 'Celestial hope and glory',
        palette: [
          Color(0xFF111B44),
          Color(0xFF324A8A),
          Color(0xFFE7C96F),
        ],
        icon: Icons.nights_stay_rounded,
      );
    }

    final oldTestament = {
      'exodus',
      'leviticus',
      'numbers',
      'deuteronomy',
      'joshua',
      'judges',
      'ruth',
      '1 samuel',
      '2 samuel',
      '1 kings',
      '2 kings',
      '1 chronicles',
      '2 chronicles',
      'ezra',
      'nehemiah',
      'esther',
      'job',
      'ecclesiastes',
      'song of solomon',
      'isaiah',
      'jeremiah',
      'lamentations',
      'ezekiel',
      'daniel',
      'hosea',
      'joel',
      'amos',
      'obadiah',
      'jonah',
      'micah',
      'nahum',
      'habakkuk',
      'zephaniah',
      'haggai',
      'zechariah',
      'malachi',
    };
    if (oldTestament.contains(key)) {
      return const AudioArtworkTheme(
        title: 'Old Testament',
        subtitle: 'History, law, and promise',
        palette: [
          Color(0xFF3A2C1E),
          Color(0xFF7A5A37),
          Color(0xFFD9B76B),
        ],
        icon: Icons.terrain_rounded,
      );
    }

    return const AudioArtworkTheme(
      title: 'New Testament',
      subtitle: 'Grace, witness, and hope',
      palette: [
        Color(0xFF1A3758),
        Color(0xFF5D84B1),
        Color(0xFFE7D8A0),
      ],
      icon: Icons.brightness_5_rounded,
    );
  }
}
