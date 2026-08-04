import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bible_verse.dart';
import '../utils/app_theme.dart';
import '../widgets/verse_action_bottom_sheet.dart';

class VerseCard extends StatelessWidget {
  final BibleVerse verse;
  final String reference;
  final String versionId;
  final bool isHighlighted;
  final Color? highlightColor;
  final bool isBookmarked;
  final bool hasNote;
  final bool isAudioActive;
  final Color? textColor;
  final Color? verseNumberColor;
  final double fontSize;
  final double lineHeight;
  final String? fontFamily;
  final bool useSystemFont;

  const VerseCard({
    super.key,
    required this.verse,
    required this.reference,
    required this.versionId,
    this.isHighlighted = false,
    this.highlightColor,
    this.isBookmarked = false,
    this.hasNote = false,
    this.isAudioActive = false,
    this.textColor,
    this.verseNumberColor,
    this.fontSize = 16,
    this.lineHeight = 1.75,
    this.fontFamily,
    this.useSystemFont = false,
  });

  @override
  Widget build(BuildContext context) {
    final ink = textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.inkDark
            : AppTheme.ink);
    final numberColor = verseNumberColor ?? AppTheme.gold;
    final tint = isAudioActive
        ? AppTheme.teal.withValues(alpha: 0.18)
        : isHighlighted
            ? (highlightColor ?? AppTheme.gold).withValues(alpha: 0.16)
            : Colors.transparent;
    final borderColor = isAudioActive
        ? AppTheme.teal.withValues(alpha: 0.45)
        : isHighlighted
            ? (highlightColor ?? AppTheme.gold).withValues(alpha: 0.28)
            : Colors.transparent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showActions(context);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showActions(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          vertical: 9,
          horizontal: tint == Colors.transparent ? 0 : 10,
        ),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(10),
          border: borderColor == Colors.transparent
              ? null
              : Border.all(color: borderColor, width: 1.1),
          boxShadow: isAudioActive
              ? [
                  BoxShadow(
                    color: AppTheme.teal.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${verse.verse}',
                  style: AppTheme.ui(
                    fontSize: 10.5,
                    weight: FontWeight.w700,
                    color: numberColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                verse.text,
                style: AppTheme.scripture(
                  fontSize: fontSize,
                  height: lineHeight,
                  color: ink,
                  fontFamily: fontFamily,
                  useSystemFont: useSystemFont,
                ),
              ),
            ),
            if (isBookmarked || hasNote) ...[
              const SizedBox(width: 6),
              Column(
                children: [
                  if (isBookmarked)
                    Icon(
                      Icons.bookmark_rounded,
                      size: 14,
                      color: AppTheme.gold.withValues(alpha: 0.9),
                    ),
                  if (hasNote)
                    Padding(
                      padding: EdgeInsets.only(top: isBookmarked ? 4 : 0),
                      child: Icon(
                        Icons.note_alt_rounded,
                        size: 14,
                        color: AppTheme.teal.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VerseActionBottomSheet(
        verse: verse,
        reference: reference,
        versionId: versionId,
      ),
    );
  }
}
