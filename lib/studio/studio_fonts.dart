import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/font_env_stub.dart'
    if (dart.library.io) '../utils/font_env_io.dart';
import 'verse_design.dart';

class StudioFonts {
  StudioFonts._();

  static const Map<StudioFontId, String> labels = {
    StudioFontId.playfair: 'Playfair Display',
    StudioFontId.cormorant: 'Cormorant',
    StudioFontId.libreBaskerville: 'Libre Baskerville',
    StudioFontId.poppins: 'Poppins',
    StudioFontId.manrope: 'Manrope',
    StudioFontId.inter: 'Inter',
    StudioFontId.dancingScript: 'Dancing Script',
    StudioFontId.greatVibes: 'Great Vibes',
    StudioFontId.sacramento: 'Sacramento',
    StudioFontId.bebasNeue: 'Bebas Neue',
    StudioFontId.anton: 'Anton',
    StudioFontId.nunito: 'Nunito',
    StudioFontId.quicksand: 'Quicksand',
    StudioFontId.cinzel: 'Cinzel',
    StudioFontId.fraunces: 'Fraunces',
  };

  static const Map<String, List<StudioFontId>> categories = {
    'Elegant': [
      StudioFontId.playfair,
      StudioFontId.cormorant,
      StudioFontId.libreBaskerville,
      StudioFontId.fraunces,
    ],
    'Modern': [
      StudioFontId.poppins,
      StudioFontId.manrope,
      StudioFontId.inter,
    ],
    'Handwriting': [
      StudioFontId.dancingScript,
      StudioFontId.greatVibes,
      StudioFontId.sacramento,
    ],
    'Bold': [
      StudioFontId.bebasNeue,
      StudioFontId.anton,
    ],
    'Cute': [
      StudioFontId.nunito,
      StudioFontId.quicksand,
    ],
    'Christian': [
      StudioFontId.cinzel,
    ],
  };

  static TextStyle styleFor(
    StudioFontId id, {
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w500,
    double height = 1.45,
    double letterSpacing = 0.2,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'serif',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );
    }

    switch (id) {
      case StudioFontId.playfair:
        return GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.cormorant:
        return GoogleFonts.cormorantGaramond(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.libreBaskerville:
        return GoogleFonts.libreBaskerville(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.poppins:
        return GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.manrope:
        return GoogleFonts.manrope(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.inter:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.dancingScript:
        return GoogleFonts.dancingScript(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.greatVibes:
        return GoogleFonts.greatVibes(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.sacramento:
        return GoogleFonts.sacramento(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.bebasNeue:
        return GoogleFonts.bebasNeue(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing + 1.2,
          fontStyle: fontStyle,
        );
      case StudioFontId.anton:
        return GoogleFonts.anton(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing + 0.8,
          fontStyle: fontStyle,
        );
      case StudioFontId.nunito:
        return GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.quicksand:
        return GoogleFonts.quicksand(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
      case StudioFontId.cinzel:
        return GoogleFonts.cinzel(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing + 0.6,
          fontStyle: fontStyle,
        );
      case StudioFontId.fraunces:
        return GoogleFonts.fraunces(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        );
    }
  }
}

class StudioTextEffects {
  StudioTextEffects._();

  static List<Shadow>? shadowsFor(StudioTextEffect effect, Color accent) {
    switch (effect) {
      case StudioTextEffect.none:
      case StudioTextEffect.gradientFill:
        return null;
      case StudioTextEffect.shadow:
        return const [
          Shadow(
            color: Color(0x88000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ];
      case StudioTextEffect.glow:
        return [
          Shadow(color: accent.withValues(alpha: 0.85), blurRadius: 18),
          Shadow(color: accent.withValues(alpha: 0.45), blurRadius: 32),
        ];
      case StudioTextEffect.outline:
        return const [
          Shadow(
              color: Color(0xCC000000), blurRadius: 1, offset: Offset(-1, 0)),
          Shadow(color: Color(0xCC000000), blurRadius: 1, offset: Offset(1, 0)),
          Shadow(
              color: Color(0xCC000000), blurRadius: 1, offset: Offset(0, -1)),
          Shadow(color: Color(0xCC000000), blurRadius: 1, offset: Offset(0, 1)),
        ];
      case StudioTextEffect.gold:
        return [
          Shadow(color: accent.withValues(alpha: 0.9), blurRadius: 8),
          const Shadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ];
      case StudioTextEffect.softBlur:
        return const [Shadow(color: Color(0x55000000), blurRadius: 16)];
      case StudioTextEffect.neon:
        return [
          Shadow(color: accent, blurRadius: 6),
          Shadow(color: accent.withValues(alpha: 0.8), blurRadius: 16),
          Shadow(color: accent.withValues(alpha: 0.5), blurRadius: 28),
        ];
      case StudioTextEffect.silver:
        return const [
          Shadow(
              color: Color(0xAAFFFFFF), blurRadius: 4, offset: Offset(0, -1)),
          Shadow(color: Color(0x88000000), blurRadius: 4, offset: Offset(0, 2)),
        ];
      case StudioTextEffect.emboss:
        return const [
          Shadow(
              color: Color(0x66FFFFFF), blurRadius: 1, offset: Offset(-1, -1)),
          Shadow(color: Color(0x99000000), blurRadius: 2, offset: Offset(1, 1)),
        ];
    }
  }

  static Color colorFor(StudioTextEffect effect, Color base, Color accent) {
    switch (effect) {
      case StudioTextEffect.gold:
        return accent;
      case StudioTextEffect.silver:
        return const Color(0xFFE8ECF0);
      case StudioTextEffect.neon:
        return Colors.white;
      default:
        return base;
    }
  }
}

class SmartVerseFormatter {
  SmartVerseFormatter._();

  static String format(String text, {bool enabled = true}) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!enabled || cleaned.isEmpty) return cleaned;
    if (cleaned.length < 42) return cleaned;

    final words = cleaned.split(' ');
    if (words.length <= 4) return words.join('\n');

    final lines = <String>[];
    var current = StringBuffer();
    var count = 0;
    const target = 3;

    for (final word in words) {
      if (count >= target && current.isNotEmpty) {
        lines.add(current.toString());
        current = StringBuffer(word);
        count = 1;
      } else {
        if (current.isNotEmpty) current.write(' ');
        current.write(word);
        count++;
      }
    }
    if (current.isNotEmpty) lines.add(current.toString());

    if (lines.length >= 3 &&
        lines.last.split(' ').length == 1 &&
        lines.length > 1) {
      final prev = lines[lines.length - 2].split(' ');
      if (prev.length > 2) {
        final moved = prev.removeLast();
        lines[lines.length - 2] = prev.join(' ');
        lines[lines.length - 1] = '$moved ${lines.last}';
      }
    }

    return lines.join('\n');
  }

  static List<String> words(String text) => text
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
}

class StudioPaletteEngine {
  StudioPaletteEngine._();

  static List<ColorPaletteRec> recommend(VerseMood mood) {
    switch (mood) {
      case VerseMood.hope:
      case VerseMood.morning:
        return const [
          ColorPaletteRec(
            name: 'Sunrise Gold',
            backgroundGradientId: 'hope_sunrise',
            textColorValue: 0xFFFFFFF4,
            accentColorValue: 0xFFE8C766,
          ),
        ];
      case VerseMood.prayer:
      case VerseMood.night:
        return const [
          ColorPaletteRec(
            name: 'Candle Navy',
            backgroundGradientId: 'candlelight',
            textColorValue: 0xFFF6F0E1,
            accentColorValue: 0xFFC08A28,
          ),
        ];
      case VerseMood.love:
      case VerseMood.wedding:
        return const [
          ColorPaletteRec(
            name: 'Blush Romance',
            backgroundGradientId: 'blush_love',
            textColorValue: 0xFFFFFFF8,
            accentColorValue: 0xFFE8A0BF,
          ),
        ];
      case VerseMood.strength:
        return const [
          ColorPaletteRec(
            name: 'Mountain Strength',
            backgroundGradientId: 'mountain',
            textColorValue: 0xFFFFFFFF,
            accentColorValue: 0xFFE8C766,
          ),
        ];
      case VerseMood.peace:
      case VerseMood.healing:
        return const [
          ColorPaletteRec(
            name: 'Forest Cream',
            backgroundGradientId: 'peace_lake',
            textColorValue: 0xFFF1E9D6,
            accentColorValue: 0xFF7FDBDA,
          ),
        ];
      case VerseMood.majesty:
      case VerseMood.luxury:
      case VerseMood.faith:
        return const [
          ColorPaletteRec(
            name: 'Navy Gold',
            backgroundGradientId: 'majesty',
            textColorValue: 0xFFF6F0E1,
            accentColorValue: 0xFFC08A28,
          ),
        ];
      default:
        return const [
          ColorPaletteRec(
            name: 'Emerald Teal',
            backgroundGradientId: 'emerald_teal',
            textColorValue: 0xFFFFFFFF,
            accentColorValue: 0xFFC08A28,
          ),
        ];
    }
  }
}

class PhotoFilterMatrices {
  PhotoFilterMatrices._();

  static List<double> matrix({
    required double brightness,
    required double contrast,
    required double saturation,
    required StudioPhotoFilter filter,
  }) {
    var c = 1 + contrast;
    var b = brightness * 40;
    var s = 1 + saturation;

    switch (filter) {
      case StudioPhotoFilter.warm:
        b += 8;
        break;
      case StudioPhotoFilter.vintage:
        c *= 0.92;
        s *= 0.7;
        b += 6;
        break;
      case StudioPhotoFilter.blackWhite:
        s = 0;
        break;
      case StudioPhotoFilter.hdr:
        c *= 1.25;
        s *= 1.15;
        break;
      case StudioPhotoFilter.none:
        break;
    }

    final t = (1 - c) / 2 * 255 + b;
    final sr = 0.2126 * (1 - s);
    final sg = 0.7152 * (1 - s);
    final sb = 0.0722 * (1 - s);

    // Contrast + brightness, then saturation.
    return [
      c * (sr + s),
      c * sg,
      c * sb,
      0,
      t,
      c * sr,
      c * (sg + s),
      c * sb,
      0,
      t,
      c * sr,
      c * sg,
      c * (sb + s),
      0,
      t,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
