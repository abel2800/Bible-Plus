import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

/// Atmospheric gold-gradient backdrop used across Bible Plus screens.
class BpPlusBackground extends StatelessWidget {
  const BpPlusBackground({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = context.goldPalette;
    final base = brightness == Brightness.dark
        ? AppTheme.appBgDark
        : AppTheme.appBgLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.85),
          radius: 1.4,
          colors: [palette.glow, base],
          stops: const [0.0, 0.55],
        ),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}
