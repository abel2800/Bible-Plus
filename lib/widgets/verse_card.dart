import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bible_verse.dart';
import '../models/color_theme.dart';
import '../utils/app_theme.dart';
import '../widgets/verse_action_bottom_sheet.dart';

bool isEthiopicScriptVersion(String versionId) {
  final id = versionId.toLowerCase();
  return id.contains('amh') ||
      id.contains('am-') ||
      id.contains('weahadu') ||
      id.contains('gez') ||
      id.contains('ti-') ||
      id.contains('orm') ||
      id.contains('nasv');
}

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
  final Color? accentColor;
  final double fontSize;
  final double lineHeight;
  final String? fontFamily;
  final bool useSystemFont;
  final bool useDropCap;
  final bool showVerseNumbers;
  final bool redLetterWords;
  final ReaderColorTheme? readerTheme;
  final bool selected;
  final VoidCallback? onTap;

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
    this.accentColor,
    this.fontSize = 16,
    this.lineHeight = 1.85,
    this.fontFamily,
    this.useSystemFont = false,
    this.useDropCap = false,
    this.showVerseNumbers = true,
    this.redLetterWords = false,
    this.readerTheme,
    this.selected = false,
    this.onTap,
  });

  static const _redLetter = Color(0xFF9C3B2A);

  static bool _isGospel(int bookId) => bookId >= 40 && bookId <= 43;

  List<TextSpan> _textSpans(String text, TextStyle style) {
    if (!redLetterWords || !_isGospel(verse.book)) {
      return [TextSpan(text: text, style: style)];
    }
    final spans = <TextSpan>[];
    final pattern = RegExp(r'"([^"]*)"');
    var start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(
            TextSpan(text: text.substring(start, match.start), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: style.copyWith(color: _redLetter),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    return spans.isEmpty ? [TextSpan(text: text, style: style)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    final ink = textColor ?? AppTheme.ink;
    final numberColor = verseNumberColor ?? AppTheme.inkFaint;
    final accent = accentColor ?? AppTheme.gold;
    final active = isAudioActive || isHighlighted || selected;
    final fill = isAudioActive
        ? accent.withValues(alpha: readerTheme?.isGlass == true ? 0.10 : 0.22)
        : isHighlighted
            ? (highlightColor ?? accent).withValues(alpha: 0.22)
            : selected
                ? (readerTheme?.surfaceColor ?? accent.withValues(alpha: 0.12))
                : Colors.transparent;
    final ethiopic = isEthiopicScriptVersion(versionId);

    final bodyStyle = ethiopic
        ? AppTheme.ethopic(
            fontSize: fontSize,
            height: lineHeight,
            color: ink.withValues(alpha: active ? 1 : 0.92),
          )
        : AppTheme.scripture(
            fontSize: fontSize,
            height: lineHeight,
            color: ink.withValues(alpha: active ? 1 : 0.92),
            fontFamily: fontFamily,
            useSystemFont: useSystemFont,
          );

    final numberStyle = AppTheme.ui(
      fontSize: 9.5,
      weight: FontWeight.w500,
      color: active ? accent : numberColor,
      height: 1.2,
    );

    final text = verse.text.trim();
    final showDropCap = useDropCap &&
        text.isNotEmpty &&
        !ethiopic &&
        RegExp(r'[A-Za-z]').hasMatch(text[0]);

    Widget verseBody;
    if (showDropCap) {
      final drop = text[0].toUpperCase();
      final rest = text.length > 1 ? text.substring(1) : '';
      verseBody = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 2),
            child: Text(
              drop,
              style: AppTheme.displayCap(
                fontSize: 50,
                color: accent,
                height: 0.82,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  if (showVerseNumbers)
                    TextSpan(text: '${verse.verse} ', style: numberStyle),
                  ..._textSpans(rest, bodyStyle),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      verseBody = Text.rich(
        TextSpan(
          style: bodyStyle,
          children: [
            if (showVerseNumbers)
              TextSpan(text: '${verse.verse} ', style: numberStyle),
            ..._textSpans(text, bodyStyle),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        } else {
          _showActions(context);
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showActions(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: active
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
            : EdgeInsets.zero,
        decoration: active
            ? BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(6),
                border: isHighlighted || isAudioActive
                    ? Border(
                        bottom: BorderSide(
                          color: accent.withValues(alpha: 0.85),
                          width: 2,
                        ),
                      )
                    : selected
                        ? Border.all(
                            color: accent.withValues(alpha: 0.25),
                          )
                        : null,
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: verseBody),
            if (isBookmarked || hasNote) ...[
              const SizedBox(width: 6),
              Column(
                children: [
                  if (isBookmarked)
                    Icon(
                      Icons.bookmark_rounded,
                      size: 14,
                      color: accent.withValues(alpha: 0.9),
                    ),
                  if (hasNote)
                    Padding(
                      padding: EdgeInsets.only(top: isBookmarked ? 4 : 0),
                      child: Icon(
                        Icons.note_alt_rounded,
                        size: 14,
                        color: accent.withValues(alpha: 0.75),
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerseActionBottomSheet(
        verse: verse,
        reference: reference,
        versionId: versionId,
      ),
    );
  }
}
