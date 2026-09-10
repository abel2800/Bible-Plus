import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class BpBrandAssets {
  BpBrandAssets._();

  static const logoPath = 'assets/branding/bible_plus_logo.png';
}

class BpBrandMark extends StatelessWidget {
  const BpBrandMark({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.wordmarkSize = 17,
  });

  final double size;
  final bool showWordmark;
  final double wordmarkSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            BpBrandAssets.logoPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.menu_book_rounded,
              color: AppTheme.gold,
              size: size * 0.45,
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              style: AppTheme.brandTitle(
                fontSize: wordmarkSize,
                weight: FontWeight.w500,
                color: ink,
              ),
              children: const [
                TextSpan(text: 'Bible '),
                TextSpan(
                  text: 'Plus',
                  style: TextStyle(color: AppTheme.gold),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class BpAvatar extends StatelessWidget {
  const BpAvatar({
    super.key,
    required this.initial,
    this.size = 40,
    this.onTap,
  });

  final String initial;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.goldBright, AppTheme.goldMuted],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTheme.brandTitle(
          fontSize: size * 0.38,
          weight: FontWeight.w600,
          color: AppTheme.onGold,
        ),
      ),
    );

    if (onTap == null) return avatar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}
