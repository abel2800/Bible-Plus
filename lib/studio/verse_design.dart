import 'package:flutter/material.dart';

enum StudioExportPreset {
  story,
  post,
  wallpaper,
  square,
  facebook,
  whatsapp,
  pinterest,
  tablet,
  desktop,
}

enum StudioLayoutPreset {
  centered,
  magazine,
  instagram,
  minimal,
  pinterest,
}

enum StudioFontId {
  playfair,
  cormorant,
  libreBaskerville,
  poppins,
  manrope,
  inter,
  dancingScript,
  greatVibes,
  sacramento,
  bebasNeue,
  anton,
  nunito,
  quicksand,
  cinzel,
  fraunces,
}

enum StudioTextEffect {
  none,
  shadow,
  glow,
  outline,
  gold,
  softBlur,
  neon,
  silver,
  emboss,
  gradientFill,
}

enum VerseMood {
  auto,
  hope,
  prayer,
  love,
  strength,
  peace,
  majesty,
  neutral,
  morning,
  night,
  christmas,
  easter,
  wedding,
  healing,
  faith,
  baptism,
  youth,
  children,
  luxury,
}

enum StudioDecorId {
  none,
  cross,
  dove,
  olive,
  star,
  rays,
  sparkles,
  heart,
  crown,
  bible,
  prayerHands,
  sun,
  moon,
}

enum StudioTextureId {
  none,
  paper,
  canvas,
  dust,
  light,
  vignette,
  snow,
  gold,
  watercolor,
}

enum StudioFrameId {
  none,
  thin,
  doubleLine,
  softGlow,
  ornate,
}

enum StudioMotionId {
  none,
  sparkles,
  floatingDust,
  snow,
  lightRays,
  rain,
}

enum StudioPhotoFilter {
  none,
  warm,
  vintage,
  blackWhite,
  hdr,
}

enum StudioTextPath {
  straight,
  arc,
  wave,
}

enum StudioLayerId {
  verse,
  reference,
  logo,
  decor,
}

class StudioGradientSpec {
  const StudioGradientSpec({
    required this.id,
    required this.name,
    required this.category,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  final String id;
  final String name;
  final String category;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  LinearGradient toGradient() => LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      );
}

class LayerTransform {
  const LayerTransform({
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.rotation = 0,
  });

  final double dx;
  final double dy;
  final double scale;
  final double rotation;

  LayerTransform copyWith({
    double? dx,
    double? dy,
    double? scale,
    double? rotation,
  }) {
    return LayerTransform(
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'dx': dx,
        'dy': dy,
        'scale': scale,
        'rotation': rotation,
      };

  factory LayerTransform.fromJson(Map<String, dynamic> json) {
    return LayerTransform(
      dx: (json['dx'] as num?)?.toDouble() ?? 0,
      dy: (json['dy'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WordHighlight {
  const WordHighlight({
    required this.wordIndex,
    required this.colorValue,
  });

  final int wordIndex;
  final int colorValue;

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'wordIndex': wordIndex,
        'colorValue': colorValue,
      };

  factory WordHighlight.fromJson(Map<String, dynamic> json) {
    return WordHighlight(
      wordIndex: json['wordIndex'] as int? ?? 0,
      colorValue: json['colorValue'] as int? ?? 0xFFFFFFFF,
    );
  }
}

class ColorPaletteRec {
  const ColorPaletteRec({
    required this.name,
    required this.backgroundGradientId,
    required this.textColorValue,
    required this.accentColorValue,
  });

  final String name;
  final String backgroundGradientId;
  final int textColorValue;
  final int accentColorValue;
}

class VerseDesign {
  VerseDesign({
    this.verseText = '',
    this.reference = '',
    this.exportPreset = StudioExportPreset.story,
    this.layout = StudioLayoutPreset.centered,
    this.gradientId = 'emerald_teal',
    this.fontId = StudioFontId.fraunces,
    this.fontSize = 26,
    this.textColorValue = 0xFFFFFFFF,
    this.accentColorValue = 0xFFC08A28,
    this.textAlign = TextAlign.center,
    this.letterSpacing = 0.2,
    this.lineHeight = 1.45,
    this.effect = StudioTextEffect.shadow,
    this.glassEnabled = false,
    this.smartBreaks = true,
    this.mood = VerseMood.auto,
    this.detectedMood = VerseMood.neutral,
    this.decor = StudioDecorId.none,
    this.texture = StudioTextureId.none,
    this.frame = StudioFrameId.none,
    this.motion = StudioMotionId.none,
    this.photoFilter = StudioPhotoFilter.none,
    this.textPath = StudioTextPath.straight,
    this.scenicPackId = 'none',
    this.showLogo = true,
    this.quoteAnimation = true,
    this.photoPath,
    this.photoBlur = 0,
    this.photoBrightness = 0,
    this.photoContrast = 0,
    this.photoSaturation = 0,
    this.photoDarken = 0.35,
    this.verseTransform = const LayerTransform(),
    this.referenceTransform = const LayerTransform(),
    this.logoTransform = const LayerTransform(),
    this.decorTransform = const LayerTransform(),
    this.highlights = const [],
    this.templateName,
  });

  String verseText;
  String reference;
  StudioExportPreset exportPreset;
  StudioLayoutPreset layout;
  String gradientId;
  StudioFontId fontId;
  double fontSize;
  int textColorValue;
  int accentColorValue;
  TextAlign textAlign;
  double letterSpacing;
  double lineHeight;
  StudioTextEffect effect;
  bool glassEnabled;
  bool smartBreaks;
  VerseMood mood;
  VerseMood detectedMood;
  StudioDecorId decor;
  StudioTextureId texture;
  StudioFrameId frame;
  StudioMotionId motion;
  StudioPhotoFilter photoFilter;
  StudioTextPath textPath;
  String scenicPackId;
  bool showLogo;
  bool quoteAnimation;
  String? photoPath;
  double photoBlur;
  double photoBrightness;
  double photoContrast;
  double photoSaturation;
  double photoDarken;
  LayerTransform verseTransform;
  LayerTransform referenceTransform;
  LayerTransform logoTransform;
  LayerTransform decorTransform;
  List<WordHighlight> highlights;
  String? templateName;

  Color get textColor => Color(textColorValue);
  Color get accentColor => Color(accentColorValue);

  VerseMood get effectiveMood => mood == VerseMood.auto ? detectedMood : mood;

  Size get exportPixelSize {
    switch (exportPreset) {
      case StudioExportPreset.story:
        return const Size(1080, 1920);
      case StudioExportPreset.post:
        return const Size(1080, 1080);
      case StudioExportPreset.wallpaper:
        return const Size(1440, 3200);
      case StudioExportPreset.square:
        return const Size(1080, 1080);
      case StudioExportPreset.facebook:
        return const Size(1200, 630);
      case StudioExportPreset.whatsapp:
        return const Size(1080, 1920);
      case StudioExportPreset.pinterest:
        return const Size(1000, 1500);
      case StudioExportPreset.tablet:
        return const Size(2048, 2732);
      case StudioExportPreset.desktop:
        return const Size(1920, 1080);
    }
  }

  double get aspectRatio {
    final s = exportPixelSize;
    return s.width / s.height;
  }

  String get exportLabel {
    switch (exportPreset) {
      case StudioExportPreset.story:
        return 'IG Story 1080×1920';
      case StudioExportPreset.post:
        return 'IG Post 1080×1080';
      case StudioExportPreset.wallpaper:
        return 'Phone 1440×3200';
      case StudioExportPreset.square:
        return 'Square';
      case StudioExportPreset.facebook:
        return 'Facebook';
      case StudioExportPreset.whatsapp:
        return 'WhatsApp Status';
      case StudioExportPreset.pinterest:
        return 'Pinterest';
      case StudioExportPreset.tablet:
        return 'Tablet';
      case StudioExportPreset.desktop:
        return 'Desktop';
    }
  }

  VerseDesign copy() {
    return VerseDesign(
      verseText: verseText,
      reference: reference,
      exportPreset: exportPreset,
      layout: layout,
      gradientId: gradientId,
      fontId: fontId,
      fontSize: fontSize,
      textColorValue: textColorValue,
      accentColorValue: accentColorValue,
      textAlign: textAlign,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      effect: effect,
      glassEnabled: glassEnabled,
      smartBreaks: smartBreaks,
      mood: mood,
      detectedMood: detectedMood,
      decor: decor,
      texture: texture,
      frame: frame,
      motion: motion,
      photoFilter: photoFilter,
      textPath: textPath,
      scenicPackId: scenicPackId,
      showLogo: showLogo,
      quoteAnimation: quoteAnimation,
      photoPath: photoPath,
      photoBlur: photoBlur,
      photoBrightness: photoBrightness,
      photoContrast: photoContrast,
      photoSaturation: photoSaturation,
      photoDarken: photoDarken,
      verseTransform: verseTransform,
      referenceTransform: referenceTransform,
      logoTransform: logoTransform,
      decorTransform: decorTransform,
      highlights: List<WordHighlight>.from(highlights),
      templateName: templateName,
    );
  }

  void applyFrom(VerseDesign next) {
    verseText = next.verseText;
    reference = next.reference;
    exportPreset = next.exportPreset;
    layout = next.layout;
    gradientId = next.gradientId;
    fontId = next.fontId;
    fontSize = next.fontSize;
    textColorValue = next.textColorValue;
    accentColorValue = next.accentColorValue;
    textAlign = next.textAlign;
    letterSpacing = next.letterSpacing;
    lineHeight = next.lineHeight;
    effect = next.effect;
    glassEnabled = next.glassEnabled;
    smartBreaks = next.smartBreaks;
    mood = next.mood;
    detectedMood = next.detectedMood;
    decor = next.decor;
    texture = next.texture;
    frame = next.frame;
    motion = next.motion;
    photoFilter = next.photoFilter;
    textPath = next.textPath;
    scenicPackId = next.scenicPackId;
    showLogo = next.showLogo;
    quoteAnimation = next.quoteAnimation;
    photoPath = next.photoPath;
    photoBlur = next.photoBlur;
    photoBrightness = next.photoBrightness;
    photoContrast = next.photoContrast;
    photoSaturation = next.photoSaturation;
    photoDarken = next.photoDarken;
    verseTransform = next.verseTransform;
    referenceTransform = next.referenceTransform;
    logoTransform = next.logoTransform;
    decorTransform = next.decorTransform;
    highlights = List<WordHighlight>.from(next.highlights);
    templateName = next.templateName;
  }

  Map<String, dynamic> toJson() => {
        'verseText': verseText,
        'reference': reference,
        'exportPreset': exportPreset.name,
        'layout': layout.name,
        'gradientId': gradientId,
        'fontId': fontId.name,
        'fontSize': fontSize,
        'textColorValue': textColorValue,
        'accentColorValue': accentColorValue,
        'textAlign': textAlign.name,
        'letterSpacing': letterSpacing,
        'lineHeight': lineHeight,
        'effect': effect.name,
        'glassEnabled': glassEnabled,
        'smartBreaks': smartBreaks,
        'mood': mood.name,
        'detectedMood': detectedMood.name,
        'decor': decor.name,
        'texture': texture.name,
        'frame': frame.name,
        'motion': motion.name,
        'photoFilter': photoFilter.name,
        'textPath': textPath.name,
        'scenicPackId': scenicPackId,
        'showLogo': showLogo,
        'quoteAnimation': quoteAnimation,
        'photoPath': photoPath,
        'photoBlur': photoBlur,
        'photoBrightness': photoBrightness,
        'photoContrast': photoContrast,
        'photoSaturation': photoSaturation,
        'photoDarken': photoDarken,
        'verseTransform': verseTransform.toJson(),
        'referenceTransform': referenceTransform.toJson(),
        'logoTransform': logoTransform.toJson(),
        'decorTransform': decorTransform.toJson(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
        'templateName': templateName,
      };

  static T _enum<T extends Enum>(List<T> values, String? name, T fallback) {
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  factory VerseDesign.fromJson(Map<String, dynamic> json) {
    TextAlign align = TextAlign.center;
    final alignName = json['textAlign'] as String?;
    if (alignName == 'left') align = TextAlign.left;
    if (alignName == 'right') align = TextAlign.right;

    return VerseDesign(
      verseText: json['verseText'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      exportPreset: _enum(
        StudioExportPreset.values,
        json['exportPreset'] as String?,
        StudioExportPreset.story,
      ),
      layout: _enum(
        StudioLayoutPreset.values,
        json['layout'] as String?,
        StudioLayoutPreset.centered,
      ),
      gradientId: json['gradientId'] as String? ?? 'emerald_teal',
      fontId: _enum(
        StudioFontId.values,
        json['fontId'] as String?,
        StudioFontId.fraunces,
      ),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 26,
      textColorValue: json['textColorValue'] as int? ?? 0xFFFFFFFF,
      accentColorValue: json['accentColorValue'] as int? ?? 0xFFC08A28,
      textAlign: align,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.2,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.45,
      effect: _enum(
        StudioTextEffect.values,
        json['effect'] as String?,
        StudioTextEffect.shadow,
      ),
      glassEnabled: json['glassEnabled'] as bool? ?? false,
      smartBreaks: json['smartBreaks'] as bool? ?? true,
      mood: _enum(VerseMood.values, json['mood'] as String?, VerseMood.auto),
      detectedMood: _enum(
        VerseMood.values,
        json['detectedMood'] as String?,
        VerseMood.neutral,
      ),
      decor: _enum(
        StudioDecorId.values,
        json['decor'] as String?,
        StudioDecorId.none,
      ),
      texture: _enum(
        StudioTextureId.values,
        json['texture'] as String?,
        StudioTextureId.none,
      ),
      frame: _enum(
        StudioFrameId.values,
        json['frame'] as String?,
        StudioFrameId.none,
      ),
      motion: _enum(
        StudioMotionId.values,
        json['motion'] as String?,
        StudioMotionId.none,
      ),
      photoFilter: _enum(
        StudioPhotoFilter.values,
        json['photoFilter'] as String?,
        StudioPhotoFilter.none,
      ),
      textPath: _enum(
        StudioTextPath.values,
        json['textPath'] as String?,
        StudioTextPath.straight,
      ),
      scenicPackId: json['scenicPackId'] as String? ?? 'none',
      showLogo: json['showLogo'] as bool? ?? true,
      quoteAnimation: json['quoteAnimation'] as bool? ?? true,
      photoPath: json['photoPath'] as String?,
      photoBlur: (json['photoBlur'] as num?)?.toDouble() ?? 0,
      photoBrightness: (json['photoBrightness'] as num?)?.toDouble() ?? 0,
      photoContrast: (json['photoContrast'] as num?)?.toDouble() ?? 0,
      photoSaturation: (json['photoSaturation'] as num?)?.toDouble() ?? 0,
      photoDarken: (json['photoDarken'] as num?)?.toDouble() ?? 0.35,
      verseTransform: json['verseTransform'] is Map
          ? LayerTransform.fromJson(
              Map<String, dynamic>.from(json['verseTransform'] as Map),
            )
          : const LayerTransform(),
      referenceTransform: json['referenceTransform'] is Map
          ? LayerTransform.fromJson(
              Map<String, dynamic>.from(json['referenceTransform'] as Map),
            )
          : const LayerTransform(),
      logoTransform: json['logoTransform'] is Map
          ? LayerTransform.fromJson(
              Map<String, dynamic>.from(json['logoTransform'] as Map),
            )
          : const LayerTransform(),
      decorTransform: json['decorTransform'] is Map
          ? LayerTransform.fromJson(
              Map<String, dynamic>.from(json['decorTransform'] as Map),
            )
          : const LayerTransform(),
      highlights: (json['highlights'] as List<dynamic>? ?? [])
          .map(
            (e) => WordHighlight.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      templateName: json['templateName'] as String?,
    );
  }
}
