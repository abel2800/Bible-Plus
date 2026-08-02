import 'dart:math';

import 'package:flutter/material.dart';

import 'gradient_library.dart';
import 'mood_engine.dart';
import 'verse_design.dart';

/// Curated offline "Magic Design" recipes — Scripture-aware, not cloud AI.
class MagicDesignEngine {
  MagicDesignEngine({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _spin = 0;

  void apply(VerseDesign design) {
    _spin++;
    design.detectedMood = MoodEngine.detect(
      design.verseText,
      reference: design.reference,
    );
    final mood = design.effectiveMood;
    final pack = MoodEngine.packs[mood] ?? MoodEngine.packs[VerseMood.neutral]!;

    // Rotate layout, gradient, font, effect, glass within mood constraints.
    final layouts = StudioLayoutPreset.values;
    final fonts = <StudioFontId>[
      pack.fontId,
      StudioFontId.playfair,
      StudioFontId.cormorant,
      StudioFontId.cinzel,
      StudioFontId.fraunces,
      if (mood == VerseMood.love || mood == VerseMood.prayer)
        StudioFontId.dancingScript,
      if (mood == VerseMood.strength) StudioFontId.bebasNeue,
    ];

    final effects = <StudioTextEffect>[
      pack.effect,
      StudioTextEffect.shadow,
      StudioTextEffect.glow,
      StudioTextEffect.gold,
      StudioTextEffect.outline,
      StudioTextEffect.neon,
      StudioTextEffect.silver,
    ];

    final gradientPool = [
      ...pack.gradientIds,
      ...StudioGradientLibrary.all
          .where((g) => g.category == 'AI Gradients' || g.category == 'Luxury')
          .map((g) => g.id)
          .take(4),
    ];

    design.layout = layouts[(_spin + _random.nextInt(3)) % layouts.length];
    design.fontId = fonts[_spin % fonts.length];
    design.effect = effects[(_spin + 1) % effects.length];
    design.gradientId = gradientPool[_spin % gradientPool.length];
    design.glassEnabled = _spin.isOdd ? pack.glass : !pack.glass;
    design.smartBreaks = true;
    design.decor = _spin % 3 == 0 ? pack.decor : StudioDecorId.none;
    design.textColorValue = pack.textColorValue;
    design.accentColorValue = pack.accentColorValue;
    design.texture = _spin % 4 == 0
        ? StudioTextureId.light
        : _spin % 5 == 0
            ? StudioTextureId.vignette
            : StudioTextureId.none;
    design.frame = _spin % 4 == 0
        ? StudioFrameId.ornate
        : _spin % 3 == 0
            ? StudioFrameId.thin
            : StudioFrameId.none;
    design.motion = _spin % 3 == 0
        ? StudioMotionId.sparkles
        : _spin % 4 == 0
            ? StudioMotionId.lightRays
            : StudioMotionId.none;
    design.letterSpacing = 0.1 + (_spin % 4) * 0.15;
    design.lineHeight = 1.35 + (_spin % 3) * 0.08;
    design.fontSize = 24 + (_spin % 5).toDouble() * 2;
    design.verseTransform = const LayerTransform();
    design.referenceTransform = const LayerTransform();
    design.logoTransform = const LayerTransform();
    design.decorTransform = const LayerTransform();

    // Soft variation on alignment by layout
    switch (design.layout) {
      case StudioLayoutPreset.magazine:
        design.textAlign = TextAlign.left;
        break;
      case StudioLayoutPreset.minimal:
        design.textAlign = TextAlign.left;
        break;
      default:
        design.textAlign = TextAlign.center;
    }
  }
}
