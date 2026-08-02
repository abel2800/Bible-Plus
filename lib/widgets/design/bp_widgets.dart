import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class BpCard extends StatelessWidget {
  const BpCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final radius = BorderRadius.circular(16);

    final body = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    final shaped = Material(
      color: surface,
      elevation: 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: body,
            ),
    );

    if (margin == null) return shaped;
    return Padding(padding: margin!, child: shaped);
  }
}

class BpRule extends StatelessWidget {
  const BpRule({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        height: 14,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    border,
                    border,
                    Colors.transparent,
                  ],
                  stops: const [0, 0.15, 0.85, 1],
                ),
              ),
            ),
            Container(
              color: bg,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: const ExcludeSemantics(
                child: Text(
                  '◆',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.gold,
                    height: 1,
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

class BpPill extends StatelessWidget {
  const BpPill({
    super.key,
    required this.label,
    this.icon,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: filled
            ? AppTheme.gold
            : (isDark ? AppTheme.surface2Dark : AppTheme.surface2Light),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled
              ? AppTheme.gold
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: filled
                  ? AppTheme.onGold
                  : (isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTheme.ui(
              fontSize: 11,
              weight: FontWeight.w600,
              color: filled
                  ? AppTheme.onGold
                  : (isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class BpIconButton extends StatelessWidget {
  const BpIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Material(
      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class BpBrandMark extends StatelessWidget {
  const BpBrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final letterSize = size * 0.46;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.23),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldSoft,
            AppTheme.gold,
            AppTheme.vermilion,
          ],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.45),
            blurRadius: 36,
            offset: const Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'B',
        style: AppTheme.brandTitle(
          fontSize: letterSize,
          weight: FontWeight.w700,
          color: AppTheme.onGold,
        ),
      ),
    );
  }
}

class BpPrimaryButton extends StatelessWidget {
  const BpPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.goldSoft, AppTheme.gold],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: AppTheme.ui(
                  fontSize: 13.5,
                  weight: FontWeight.w700,
                  color: AppTheme.onGold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BpSectionLabel extends StatelessWidget {
  const BpSectionLabel({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.brandTitle(
                fontSize: 15,
                weight: FontWeight.w600,
                color: isDark ? AppTheme.inkDark : AppTheme.ink,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: AppTheme.ui(
                  fontSize: 11,
                  weight: FontWeight.w600,
                  color: AppTheme.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BpGroupHeader extends StatelessWidget {
  const BpGroupHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.ui(
          fontSize: 11,
          weight: FontWeight.w700,
          letterSpacing: 1,
          color: isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint,
        ),
      ),
    );
  }
}
