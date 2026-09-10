import 'package:flutter/material.dart';

/// Gold accent tokens — day and night palettes at matched visual volume.
class GoldPalette {
  const GoldPalette({
    required this.gold,
    required this.goldBright,
    required this.goldMuted,
    required this.goldSoft,
    required this.glow,
    required this.border,
  });

  final Color gold;
  final Color goldBright;
  final Color goldMuted;
  final Color goldSoft;

  /// Pre-composited glow (0.13 opacity) for gradients and shadows.
  final Color glow;
  final Color border;

  static const light = GoldPalette(
    gold: Color(0xFFB08A28),
    goldBright: Color(0xFFD4AF37),
    goldMuted: Color(0xFF8A6D1F),
    goldSoft: Color(0xFFCCAA5A),
    glow: Color(0x21B08A28),
    border: Color(0x38B08A28),
  );

  static const dark = GoldPalette(
    gold: Color(0xFFBD9A4C),
    goldBright: Color(0xFFD3B765),
    goldMuted: Color(0xFF8A7038),
    goldSoft: Color(0xFFC4AA6E),
    glow: Color(0x21C9A542),
    border: Color(0x21C9A542),
  );

  static GoldPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

class AppBrand {
  /// Default shell palette (night).
  static const gold = Color(0xFFBD9A4C);
  static const goldBright = Color(0xFFD3B765);
  static const goldMuted = Color(0xFF8A7038);
  static const goldSoft = Color(0xFFC4AA6E);
  static const goldGlow = Color(0x21C9A542);
  static const vermilion = Color(0xFF9C3B2A);
  static const indigo = Color(0xFF232C4D);
  static const moss = Color(0xFF556B45);
  static const teal = moss;
  static const onGold = Color(0xFF1C1607);
  static const success = Color(0xFF8FBF8A);
  static const warning = Color(0xFFF39C12);
  static const error = Color(0xFFE15252);

  static const radiusLg = 26.0;
  static const radiusMd = 18.0;
  static const radiusSm = 12.0;
}

class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color appBg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color gold;
  final Color goldBright;
  final Color goldMuted;
  final Color goldSoft;
  final Color goldGlow;

  const AppColors({
    required this.bg,
    required this.appBg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.gold,
    required this.goldBright,
    required this.goldMuted,
    required this.goldSoft,
    required this.goldGlow,
  });

  static const light = AppColors(
    bg: Color(0xFFEFECE2),
    appBg: Color(0xFFF7F5EF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF3F1EA),
    border: Color(0x38B08A28),
    ink: Color(0xFF1A1815),
    inkSoft: Color(0xFF68625A),
    inkFaint: Color(0xFFA09A8F),
    gold: Color(0xFFB08A28),
    goldBright: Color(0xFFD4AF37),
    goldMuted: Color(0xFF8A6D1F),
    goldSoft: Color(0xFFCCAA5A),
    goldGlow: Color(0x21B08A28),
  );

  static const dark = AppColors(
    bg: Color(0xFF0A0908),
    appBg: Color(0xFF0D0C0A),
    surface: Color(0xFF161512),
    surface2: Color(0xFF1B1916),
    border: Color(0x21C9A542),
    ink: Color(0xFFF5F3EE),
    inkSoft: Color(0xFFA7A29A),
    inkFaint: Color(0xFF6F6A61),
    gold: Color(0xFFBD9A4C),
    goldBright: Color(0xFFD3B765),
    goldMuted: Color(0xFF8A7038),
    goldSoft: Color(0xFFC4AA6E),
    goldGlow: Color(0x21C9A542),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? appBg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? gold,
    Color? goldBright,
    Color? goldMuted,
    Color? goldSoft,
    Color? goldGlow,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      appBg: appBg ?? this.appBg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      gold: gold ?? this.gold,
      goldBright: goldBright ?? this.goldBright,
      goldMuted: goldMuted ?? this.goldMuted,
      goldSoft: goldSoft ?? this.goldSoft,
      goldGlow: goldGlow ?? this.goldGlow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      appBg: Color.lerp(appBg, other.appBg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldBright: Color.lerp(goldBright, other.goldBright, t)!,
      goldMuted: Color.lerp(goldMuted, other.goldMuted, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      goldGlow: Color.lerp(goldGlow, other.goldGlow, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  GoldPalette get goldPalette =>
      GoldPalette.forBrightness(Theme.of(this).brightness);
}
