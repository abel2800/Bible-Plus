import 'gradient_library.dart';
import 'verse_design.dart';

class MoodPack {
  const MoodPack({
    required this.mood,
    required this.label,
    required this.gradientIds,
    required this.fontId,
    required this.layout,
    required this.effect,
    required this.glass,
    required this.decor,
    required this.textColorValue,
    required this.accentColorValue,
  });

  final VerseMood mood;
  final String label;
  final List<String> gradientIds;
  final StudioFontId fontId;
  final StudioLayoutPreset layout;
  final StudioTextEffect effect;
  final bool glass;
  final StudioDecorId decor;
  final int textColorValue;
  final int accentColorValue;
}

class MoodEngine {
  MoodEngine._();

  static const packs = <VerseMood, MoodPack>{
    VerseMood.hope: MoodPack(
      mood: VerseMood.hope,
      label: 'Hope',
      gradientIds: ['hope_sunrise', 'sunset', 'easter'],
      fontId: StudioFontId.playfair,
      layout: StudioLayoutPreset.pinterest,
      effect: StudioTextEffect.gold,
      glass: false,
      decor: StudioDecorId.rays,
      textColorValue: 0xFFFFFFF4,
      accentColorValue: 0xFFE8C766,
    ),
    VerseMood.prayer: MoodPack(
      mood: VerseMood.prayer,
      label: 'Prayer',
      gradientIds: ['candlelight', 'dark_mode', 'majesty'],
      fontId: StudioFontId.greatVibes,
      layout: StudioLayoutPreset.centered,
      effect: StudioTextEffect.glow,
      glass: true,
      decor: StudioDecorId.cross,
      textColorValue: 0xFFF6F0E1,
      accentColorValue: 0xFFC08A28,
    ),
    VerseMood.love: MoodPack(
      mood: VerseMood.love,
      label: 'Love',
      gradientIds: ['blush_love', 'purple_pink', 'sunset'],
      fontId: StudioFontId.dancingScript,
      layout: StudioLayoutPreset.instagram,
      effect: StudioTextEffect.shadow,
      glass: true,
      decor: StudioDecorId.heart,
      textColorValue: 0xFFFFFFF8,
      accentColorValue: 0xFFE8A0BF,
    ),
    VerseMood.strength: MoodPack(
      mood: VerseMood.strength,
      label: 'Strength',
      gradientIds: ['mountain', 'forest', 'orange_red'],
      fontId: StudioFontId.bebasNeue,
      layout: StudioLayoutPreset.magazine,
      effect: StudioTextEffect.outline,
      glass: false,
      decor: StudioDecorId.star,
      textColorValue: 0xFFFFFFFF,
      accentColorValue: 0xFFE8C766,
    ),
    VerseMood.peace: MoodPack(
      mood: VerseMood.peace,
      label: 'Peace',
      gradientIds: ['peace_lake', 'ocean', 'sky_soft'],
      fontId: StudioFontId.cormorant,
      layout: StudioLayoutPreset.minimal,
      effect: StudioTextEffect.softBlur,
      glass: false,
      decor: StudioDecorId.olive,
      textColorValue: 0xFFF1E9D6,
      accentColorValue: 0xFF7FDBDA,
    ),
    VerseMood.majesty: MoodPack(
      mood: VerseMood.majesty,
      label: 'Majesty',
      gradientIds: ['majesty', 'luxury_navy_gold', 'gold_black'],
      fontId: StudioFontId.cinzel,
      layout: StudioLayoutPreset.magazine,
      effect: StudioTextEffect.gold,
      glass: false,
      decor: StudioDecorId.crown,
      textColorValue: 0xFFF6F0E1,
      accentColorValue: 0xFFC08A28,
    ),
    VerseMood.neutral: MoodPack(
      mood: VerseMood.neutral,
      label: 'Neutral',
      gradientIds: ['emerald_teal', 'minimal_ink', 'aurora'],
      fontId: StudioFontId.fraunces,
      layout: StudioLayoutPreset.centered,
      effect: StudioTextEffect.shadow,
      glass: false,
      decor: StudioDecorId.none,
      textColorValue: 0xFFFFFFFF,
      accentColorValue: 0xFFC08A28,
    ),
    VerseMood.morning: MoodPack(
      mood: VerseMood.morning,
      label: 'Morning',
      gradientIds: ['hope_sunrise', 'sky_soft', 'easter'],
      fontId: StudioFontId.playfair,
      layout: StudioLayoutPreset.pinterest,
      effect: StudioTextEffect.softBlur,
      glass: false,
      decor: StudioDecorId.sun,
      textColorValue: 0xFF201A10,
      accentColorValue: 0xFFC08A28,
    ),
    VerseMood.night: MoodPack(
      mood: VerseMood.night,
      label: 'Night',
      gradientIds: ['galaxy', 'dark_mode', 'candlelight'],
      fontId: StudioFontId.cormorant,
      layout: StudioLayoutPreset.centered,
      effect: StudioTextEffect.glow,
      glass: true,
      decor: StudioDecorId.moon,
      textColorValue: 0xFFF1E9D6,
      accentColorValue: 0xFFE8C766,
    ),
    VerseMood.christmas: MoodPack(
      mood: VerseMood.christmas,
      label: 'Christmas',
      gradientIds: ['christmas', 'forest', 'gold_black'],
      fontId: StudioFontId.cinzel,
      layout: StudioLayoutPreset.instagram,
      effect: StudioTextEffect.gold,
      glass: false,
      decor: StudioDecorId.star,
      textColorValue: 0xFFFFFFF4,
      accentColorValue: 0xFFE8C766,
    ),
    VerseMood.easter: MoodPack(
      mood: VerseMood.easter,
      label: 'Easter',
      gradientIds: ['easter', 'hope_sunrise', 'sky_soft'],
      fontId: StudioFontId.libreBaskerville,
      layout: StudioLayoutPreset.centered,
      effect: StudioTextEffect.shadow,
      glass: false,
      decor: StudioDecorId.cross,
      textColorValue: 0xFF201A10,
      accentColorValue: 0xFF1E7F72,
    ),
    VerseMood.wedding: MoodPack(
      mood: VerseMood.wedding,
      label: 'Wedding',
      gradientIds: ['blush_love', 'minimal_cream', 'luxury_navy_gold'],
      fontId: StudioFontId.greatVibes,
      layout: StudioLayoutPreset.pinterest,
      effect: StudioTextEffect.softBlur,
      glass: true,
      decor: StudioDecorId.heart,
      textColorValue: 0xFF3D2A2A,
      accentColorValue: 0xFFC08A28,
    ),
    VerseMood.healing: MoodPack(
      mood: VerseMood.healing,
      label: 'Healing',
      gradientIds: ['peace_lake', 'ocean', 'forest'],
      fontId: StudioFontId.cormorant,
      layout: StudioLayoutPreset.minimal,
      effect: StudioTextEffect.softBlur,
      glass: false,
      decor: StudioDecorId.olive,
      textColorValue: 0xFFF1E9D6,
      accentColorValue: 0xFF7FDBDA,
    ),
    VerseMood.faith: MoodPack(
      mood: VerseMood.faith,
      label: 'Faith',
      gradientIds: ['majesty', 'aurora', 'emerald_teal'],
      fontId: StudioFontId.cinzel,
      layout: StudioLayoutPreset.magazine,
      effect: StudioTextEffect.gold,
      glass: false,
      decor: StudioDecorId.cross,
      textColorValue: 0xFFF6F0E1,
      accentColorValue: 0xFFC08A28,
    ),
    VerseMood.baptism: MoodPack(
      mood: VerseMood.baptism,
      label: 'Baptism',
      gradientIds: ['ocean', 'blue_cyan', 'peace_lake'],
      fontId: StudioFontId.playfair,
      layout: StudioLayoutPreset.instagram,
      effect: StudioTextEffect.glow,
      glass: true,
      decor: StudioDecorId.dove,
      textColorValue: 0xFFFFFFFF,
      accentColorValue: 0xFF56CCF2,
    ),
    VerseMood.youth: MoodPack(
      mood: VerseMood.youth,
      label: 'Youth',
      gradientIds: ['purple_pink', 'abstract_violet', 'orange_red'],
      fontId: StudioFontId.poppins,
      layout: StudioLayoutPreset.magazine,
      effect: StudioTextEffect.neon,
      glass: false,
      decor: StudioDecorId.sparkles,
      textColorValue: 0xFFFFFFFF,
      accentColorValue: 0xFFE8A0BF,
    ),
    VerseMood.children: MoodPack(
      mood: VerseMood.children,
      label: 'Children',
      gradientIds: ['sky_soft', 'easter', 'hope_sunrise'],
      fontId: StudioFontId.nunito,
      layout: StudioLayoutPreset.centered,
      effect: StudioTextEffect.shadow,
      glass: false,
      decor: StudioDecorId.star,
      textColorValue: 0xFF201A10,
      accentColorValue: 0xFFC08A28,
    ),
    VerseMood.luxury: MoodPack(
      mood: VerseMood.luxury,
      label: 'Luxury',
      gradientIds: ['luxury_navy_gold', 'gold_black', 'majesty'],
      fontId: StudioFontId.cinzel,
      layout: StudioLayoutPreset.pinterest,
      effect: StudioTextEffect.gold,
      glass: false,
      decor: StudioDecorId.crown,
      textColorValue: 0xFFF6F0E1,
      accentColorValue: 0xFFC08A28,
    ),
  };

  static const _keywords = <VerseMood, List<String>>{
    VerseMood.hope: [
      'hope',
      'future',
      'renew',
      'restore',
      'light',
      'dawn',
      'rejoice',
      'joy',
      'promise',
      'alive',
      'rise',
      'save',
      'salvation',
    ],
    VerseMood.prayer: [
      'pray',
      'prayer',
      'ask',
      'seek',
      'knock',
      'petition',
      'supplication',
      'watch',
      'cry',
      'hear me',
      'amen',
    ],
    VerseMood.love: [
      'love',
      'loved',
      'loveth',
      'charity',
      'beloved',
      'heart',
      'compassion',
      'kindness',
      'mercy',
      'forgave',
      'forgive',
    ],
    VerseMood.strength: [
      'strength',
      'strong',
      'power',
      'mighty',
      'courage',
      'fear not',
      'be strong',
      'armor',
      'warrior',
      'victory',
      'overcome',
      'stand',
    ],
    VerseMood.peace: [
      'peace',
      'still',
      'quiet',
      'rest',
      'calm',
      'shepherd',
      'waters',
      'comfort',
      'fearless',
      'refuge',
      'trust',
    ],
    VerseMood.majesty: [
      'king',
      'lord of lords',
      'glory',
      'holy',
      'throne',
      'majesty',
      'worship',
      'exalted',
      'almighty',
      'sovereign',
      'reign',
      'kingdom',
    ],
  };

  static VerseMood detect(String verseText, {String? reference}) {
    final hay = '${verseText.toLowerCase()} ${(reference ?? '').toLowerCase()}';
    final scores = <VerseMood, int>{
      for (final mood in _keywords.keys) mood: 0,
    };

    for (final entry in _keywords.entries) {
      for (final word in entry.value) {
        if (hay.contains(word)) {
          scores[entry.key] = (scores[entry.key] ?? 0) + 1;
        }
      }
    }

    // Soft book-level hints
    final ref = (reference ?? '').toLowerCase();
    if (ref.contains('psalm')) {
      scores[VerseMood.peace] = (scores[VerseMood.peace] ?? 0) + 1;
    }
    if (ref.contains('john') && hay.contains('loved')) {
      scores[VerseMood.love] = (scores[VerseMood.love] ?? 0) + 2;
    }
    if (ref.contains('revelation') || ref.contains('isaiah')) {
      scores[VerseMood.majesty] = (scores[VerseMood.majesty] ?? 0) + 1;
    }

    VerseMood best = VerseMood.neutral;
    var bestScore = 0;
    scores.forEach((mood, score) {
      if (score > bestScore) {
        bestScore = score;
        best = mood;
      }
    });
    return bestScore == 0 ? VerseMood.neutral : best;
  }

  static void applyMood(VerseDesign design, VerseMood mood, {int variant = 0}) {
    final resolved = mood == VerseMood.auto ? design.detectedMood : mood;
    final pack = packs[resolved] ?? packs[VerseMood.neutral]!;
    final gradients = pack.gradientIds;
    final gradientId = gradients[variant % gradients.length];

    design.mood = mood;
    design.gradientId = gradientId;
    design.fontId = pack.fontId;
    design.layout = pack.layout;
    design.effect = pack.effect;
    design.glassEnabled = pack.glass;
    design.decor = pack.decor;
    design.textColorValue = pack.textColorValue;
    design.accentColorValue = pack.accentColorValue;

    // Ensure gradient exists
    StudioGradientLibrary.byId(design.gradientId);
  }

  static String labelFor(VerseMood mood) {
    if (mood == VerseMood.auto) return 'Auto';
    return packs[mood]?.label ?? mood.name;
  }
}
