import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/app_theme.dart';

class BpGoldButton extends StatelessWidget {
  const BpGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.goldPalette;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.onGold.withValues(alpha: 0.9),
            ),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppTheme.onGold),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTheme.ui(
                  fontSize: 14,
                  weight: FontWeight.w600,
                  color: AppTheme.onGold,
                ),
              ),
            ],
          );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.goldBright, palette.gold],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.glow,
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          child: expanded ? Center(child: child) : child,
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class BpGoldProgressTrack extends StatelessWidget {
  const BpGoldProgressTrack({
    super.key,
    required this.progress,
    this.height = 4,
  });

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.goldPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track.withValues(alpha: 0.65)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.goldMuted, palette.gold],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BpStatPill extends StatelessWidget {
  const BpStatPill({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.brandTitle(
              fontSize: 19,
              weight: FontWeight.w500,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.ui(fontSize: 9, color: t.inkFaint),
          ),
        ],
      ),
    );
  }
}
