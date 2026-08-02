import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/font_env_stub.dart'
    if (dart.library.io) '../utils/font_env_io.dart';
import 'app_colors.dart';

class AppText {
  static TextStyle display(
    BuildContext c, {
    double size = 22,
    FontWeight w = FontWeight.w700,
  }) {
    final color = c.colors.ink;
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontWeight: w,
        color: color,
        height: 1.15,
      );
    }
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: 1.15,
    );
  }

  static TextStyle scripture(
    BuildContext c, {
    double size = 16,
    FontStyle style = FontStyle.normal,
    Color? color,
  }) {
    final ink = color ?? c.colors.ink;
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontStyle: style,
        color: ink,
        height: 1.7,
      );
    }
    return GoogleFonts.sourceSerif4(
      fontSize: size,
      fontStyle: style,
      color: ink,
      height: 1.7,
    );
  }

  static TextStyle ui(
    BuildContext c, {
    double size = 13.5,
    FontWeight w = FontWeight.w500,
    Color? color,
  }) {
    final ink = color ?? c.colors.ink;
    if (isFlutterTest) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: size,
        fontWeight: w,
        color: ink,
      );
    }
    return GoogleFonts.inter(fontSize: size, fontWeight: w, color: ink);
  }

  static TextStyle uiFaint(
    BuildContext c, {
    double size = 11.5,
    FontWeight w = FontWeight.w600,
  }) {
    return ui(c, size: size, w: w, color: c.colors.inkFaint);
  }
}
