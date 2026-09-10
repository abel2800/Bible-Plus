import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

/// Shared glassmorphism primitives — matches bible-plus-glass-ui.html.
class BpGlassBackground extends StatelessWidget {
  const BpGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.colors;

    if (isDark) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1526), Color(0xFF050910)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.55, -0.95),
                  radius: 1.25,
                  colors: [
                    const Color(0xFF5EE6D0).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, 0.0),
                  radius: 0.95,
                  colors: [
                    const Color(0xFF3C5AA0).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.5, 1.2),
                  radius: 1.0,
                  colors: [
                    const Color(0xFF142850).withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            child,
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.appBg,
        gradient: RadialGradient(
          center: const Alignment(-0.15, -0.88),
          radius: 1.35,
          colors: [
            context.goldPalette.glow,
            t.appBg,
          ],
          stops: const [0.0, 0.55],
        ),
      ),
      child: child,
    );
  }
}

class BpGlassPanel extends StatelessWidget {
  const BpGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 18,
    this.leftAccent,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? leftAccent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : context.goldPalette.glow;

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    final panel = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.02),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.58),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: isDark ? 30 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.35),
              border: leftAccent != null
                  ? Border(left: BorderSide(color: leftAccent!, width: 2))
                  : null,
            ),
            child: onTap == null
                ? content
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      child: content,
                    ),
                  ),
          ),
        ),
      ),
    );

    return panel;
  }
}

class BpGlassChip extends StatelessWidget {
  const BpGlassChip({
    super.key,
    required this.label,
    this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.colors;
    final accent = isDark ? const Color(0xFF5EE6D0) : AppTheme.gold;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.55)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : t.border.withValues(alpha: 0.55)),
            ),
            gradient: LinearGradient(
              colors: active
                  ? [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.08),
                    ]
                  : isDark
                      ? [
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.02),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.75),
                          Colors.white.withValues(alpha: 0.45),
                        ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Text(
            label,
            style: AppTheme.ui(
              fontSize: 11.5,
              color: active ? (isDark ? accent : AppTheme.onGold) : t.inkSoft,
              weight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class BpGlassNavBar extends StatelessWidget {
  const BpGlassNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : context.goldPalette.glow;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.09),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.62),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Page shell: glass backdrop + safe area content.
class BpGlassPage extends StatelessWidget {
  const BpGlassPage({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 720,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return BpGlassBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}
