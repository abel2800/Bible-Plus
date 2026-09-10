import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'font_env_stub.dart' if (dart.library.io) 'font_env_io.dart';

export '../theme/app_colors.dart';
export '../theme/app_theme.dart' show AppText;

class AppTheme {
  // Night palette (default app shell).
  static const Color gold = Color(0xFFBD9A4C);
  static const Color goldBright = Color(0xFFD3B765);
  static const Color goldMuted = Color(0xFF8A7038);
  static const Color goldSoft = Color(0xFFC4AA6E);
  static const Color goldGlow = Color(0x21C9A542);

  // Day palette.
  static const Color goldLight = Color(0xFFB08A28);
  static const Color goldBrightLight = Color(0xFFD4AF37);
  static const Color goldMutedLight = Color(0xFF8A6D1F);
  static const Color goldGlowLight = Color(0x21B08A28);

  static Color primaryGold(Brightness brightness) =>
      brightness == Brightness.dark ? gold : goldLight;

  static Color brightGold(Brightness brightness) =>
      brightness == Brightness.dark ? goldBright : goldBrightLight;

  static Color mutedGold(Brightness brightness) =>
      brightness == Brightness.dark ? goldMuted : goldMutedLight;

  static Color glowGold(Brightness brightness) =>
      brightness == Brightness.dark ? goldGlow : goldGlowLight;
  static const Color vermilion = Color(0xFF9C3B2A);
  static const Color indigo = Color(0xFF232C4D);
  static const Color moss = Color(0xFF556B45);
  static const Color teal = moss;
  static const Color onGold = Color(0xFF1C1607);

  static const Color appBgLight = Color(0xFFF7F5EF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFF3F1EA);
  static const Color borderLight = Color(0x38B08A28);
  static const Color ink = Color(0xFF1A1815);
  static const Color inkSoft = Color(0xFF68625A);
  static const Color inkFaint = Color(0xFFA09A8F);

  static const Color appBgDark = Color(0xFF0D0C0A);
  static const Color surfaceDark = Color(0xFF161512);
  static const Color surface2Dark = Color(0xFF1B1916);
  static const Color borderDark = Color(0x21C9A542);
  static const Color inkDark = Color(0xFFF5F3EE);
  static const Color inkSoftDark = Color(0xFFA7A29A);
  static const Color inkFaintDark = Color(0xFF6F6A61);

  static const Color success = Color(0xFF8FBF8A);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = vermilion;

  static List<BoxShadow> cardShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : const Color(0xFF463414).withValues(alpha: 0.22),
          blurRadius: 28,
          offset: const Offset(0, 14),
          spreadRadius: -12,
        ),
      ];

  static TextStyle brandTitle({
    double fontSize = 20,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'serif',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.2,
      );
    }
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.2,
    );
  }

  static TextStyle scripture({
    double fontSize = 16,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.75,
    FontStyle style = FontStyle.normal,
    String? fontFamily,
    bool useSystemFont = false,
  }) {
    if (isFlutterTest || useSystemFont || fontFamily == 'System') {
      return TextStyle(
        fontFamily: useSystemFont || fontFamily == 'System' ? null : 'serif',
        fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
        fontStyle: style,
      );
    }

    switch (fontFamily) {
      case 'Roboto':
        return GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
      case 'Merriweather':
        return GoogleFonts.merriweather(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
      case 'Open Sans':
        return GoogleFonts.openSans(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
      case 'Lato':
        return GoogleFonts.lato(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
      case 'Libre Baskerville':
        return GoogleFonts.libreBaskerville(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
      case 'Crimson Text':
        return GoogleFonts.crimsonText(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
      case 'EB Garamond':
        return GoogleFonts.ebGaramond(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
      case 'Source Serif Pro':
      default:
        return GoogleFonts.sourceSerif4(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: height,
          fontStyle: style,
        );
    }
  }

  static TextStyle ui({
    double fontSize = 13.5,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle displayCap({
    double fontSize = 52,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 0.78,
  }) {
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'serif',
        fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
        fontSize: fontSize,
        fontWeight: weight,
        color: color ?? gold,
        height: height,
      );
    }
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: weight,
      color: color ?? gold,
      height: height,
    ).copyWith(
      fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
    );
  }

  static TextStyle ethopic({
    double fontSize = 16,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.7,
  }) {
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'serif',
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
      );
    }
    return GoogleFonts.notoSerifEthiopic(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final inkColor = brightness == Brightness.dark ? inkDark : ink;
    final base = brightness == Brightness.dark
        ? ThemeData(brightness: Brightness.dark).textTheme
        : ThemeData(brightness: Brightness.light).textTheme;
    if (isFlutterTest) {
      return base.apply(bodyColor: inkColor, displayColor: inkColor).copyWith(
            displayLarge: brandTitle(fontSize: 30, color: inkColor),
            headlineMedium: brandTitle(fontSize: 24, color: inkColor),
            titleLarge: brandTitle(
              fontSize: 19,
              weight: FontWeight.w600,
              color: inkColor,
            ),
            titleMedium: brandTitle(
              fontSize: 15,
              weight: FontWeight.w600,
              color: inkColor,
            ),
            bodyLarge: scripture(fontSize: 16, color: inkColor),
            bodyMedium: ui(fontSize: 14, color: inkColor),
            bodySmall: ui(
              fontSize: 12,
              color: brightness == Brightness.dark ? inkSoftDark : inkSoft,
            ),
            labelLarge: ui(
              fontSize: 13.5,
              weight: FontWeight.w600,
              color: inkColor,
            ),
          );
    }
    return GoogleFonts.interTextTheme(base)
        .apply(bodyColor: inkColor, displayColor: inkColor)
        .copyWith(
          displayLarge: brandTitle(fontSize: 30, color: inkColor),
          headlineMedium: brandTitle(fontSize: 24, color: inkColor),
          titleLarge: brandTitle(
            fontSize: 19,
            weight: FontWeight.w600,
            color: inkColor,
          ),
          titleMedium: brandTitle(
            fontSize: 15,
            weight: FontWeight.w600,
            color: inkColor,
          ),
          bodyLarge: scripture(fontSize: 16, color: inkColor),
          bodyMedium: ui(fontSize: 14, color: inkColor),
          bodySmall: ui(
            fontSize: 12,
            color: brightness == Brightness.dark ? inkSoftDark : inkSoft,
          ),
          labelLarge: ui(
            fontSize: 13.5,
            weight: FontWeight.w600,
            color: inkColor,
          ),
        );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: goldLight,
      secondary: indigo,
      surface: surfaceLight,
      surfaceContainerHighest: surface2Light,
      outline: borderLight,
      error: vermilion,
      onPrimary: onGold,
      onSecondary: Colors.white,
      onSurface: ink,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: appBgLight,
    dividerColor: borderLight,
    textTheme: _buildTextTheme(Brightness.light),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: appBgLight,
      foregroundColor: ink,
      titleTextStyle:
          brandTitle(fontSize: 19, weight: FontWeight.w600, color: ink),
      iconTheme: const IconThemeData(color: inkSoft, size: 22),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surfaceLight,
      indicatorColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return ui(
          fontSize: 10,
          weight: FontWeight.w600,
          color: active ? goldLight : inkFaint,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(color: active ? goldLight : inkFaint, size: 22);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: appBgLight,
      selectedIconTheme: const IconThemeData(color: onGold),
      unselectedIconTheme: const IconThemeData(color: inkSoft),
      selectedLabelTextStyle:
          ui(fontSize: 12, weight: FontWeight.w600, color: ink),
      unselectedLabelTextStyle: ui(fontSize: 12, color: inkSoft),
      indicatorColor: indigo,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldLight,
        foregroundColor: onGold,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: ui(fontSize: 13.5, weight: FontWeight.w700, color: onGold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: borderLight),
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: ui(fontSize: 13, weight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: goldLight,
        foregroundColor: onGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return onGold;
        return surfaceLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return goldLight;
        return borderLight;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface2Light,
      selectedColor: indigo,
      side: const BorderSide(color: borderLight),
      labelStyle: ui(fontSize: 11.5, weight: FontWeight.w600, color: inkSoft),
      secondaryLabelStyle:
          ui(fontSize: 11.5, weight: FontWeight.w600, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldLight, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      hintStyle: ui(fontSize: 13.5, color: inkFaint),
      labelStyle: ui(fontSize: 11, weight: FontWeight.w600, color: inkSoft),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: goldLight,
      foregroundColor: onGold,
      elevation: 2,
    ),
    dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
    extensions: const [AppColors.light],
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: indigo,
      surface: surfaceDark,
      surfaceContainerHighest: surface2Dark,
      outline: borderDark,
      error: vermilion,
      onPrimary: onGold,
      onSecondary: Colors.white,
      onSurface: inkDark,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: appBgDark,
    dividerColor: borderDark,
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: appBgDark,
      foregroundColor: inkDark,
      titleTextStyle:
          brandTitle(fontSize: 19, weight: FontWeight.w600, color: inkDark),
      iconTheme: const IconThemeData(color: inkSoftDark, size: 22),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderDark),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surfaceDark,
      indicatorColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return ui(
          fontSize: 10,
          weight: FontWeight.w600,
          color: active ? gold : inkFaintDark,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          color: active ? gold : inkFaintDark,
          size: 22,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: appBgDark,
      selectedIconTheme: const IconThemeData(color: onGold),
      unselectedIconTheme: const IconThemeData(color: inkSoftDark),
      selectedLabelTextStyle:
          ui(fontSize: 12, weight: FontWeight.w600, color: inkDark),
      unselectedLabelTextStyle: ui(fontSize: 12, color: inkSoftDark),
      indicatorColor: indigo,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: onGold,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: ui(fontSize: 13.5, weight: FontWeight.w700, color: onGold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: inkDark,
        side: const BorderSide(color: borderDark),
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: ui(fontSize: 13, weight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: onGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return onGold;
        return surfaceDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return gold;
        return borderDark;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface2Dark,
      selectedColor: indigo,
      side: const BorderSide(color: borderDark),
      labelStyle:
          ui(fontSize: 11.5, weight: FontWeight.w600, color: inkSoftDark),
      secondaryLabelStyle:
          ui(fontSize: 11.5, weight: FontWeight.w600, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      hintStyle: ui(fontSize: 13.5, color: inkFaintDark),
      labelStyle: ui(fontSize: 11, weight: FontWeight.w600, color: inkSoftDark),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: onGold,
      elevation: 2,
    ),
    dividerTheme: const DividerThemeData(color: borderDark, thickness: 1),
    extensions: const [AppColors.dark],
  );

  static const List<Color> highlightColors = [
    gold,
    indigo,
    vermilion,
    Color(0xFF6E8B3D),
    Color(0xFF7B5EA7),
  ];
}
