import 'package:flutter/material.dart';

class AppBrand {
  static const gold = Color(0xFFC08A28);
  static const goldSoft = Color(0xFFE8C766);
  static const vermilion = Color(0xFFA83232);
  static const teal = Color(0xFF1E7F72);
  static const onGold = Color(0xFF241804);
  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFF39C12);
  static const error = Color(0xFFE15252);
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

  const AppColors({
    required this.bg,
    required this.appBg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
  });

  static const light = AppColors(
    bg: Color(0xFFEFE7D2),
    appBg: Color(0xFFF6F0E1),
    surface: Color(0xFFFFFDF8),
    surface2: Color(0xFFFBF4E4),
    border: Color(0xFFDED0AC),
    ink: Color(0xFF201A10),
    inkSoft: Color(0xFF6B5D42),
    inkFaint: Color(0xFF9C8D6C),
  );

  static const dark = AppColors(
    bg: Color(0xFF0E1420),
    appBg: Color(0xFF10182A),
    surface: Color(0xFF161F33),
    surface2: Color(0xFF1B2540),
    border: Color(0xFF2A3654),
    ink: Color(0xFFF1E9D6),
    inkSoft: Color(0xFFB7AD90),
    inkFaint: Color(0xFF6E7793),
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
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
