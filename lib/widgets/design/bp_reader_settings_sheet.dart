import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/font_settings.dart';
import '../../providers/bible_provider.dart';
import '../../providers/color_theme_provider.dart';
import '../../providers/font_settings_provider.dart';
import '../../providers/parallel_reading_provider.dart';
import '../../providers/reader_preferences_provider.dart';
import '../../utils/app_theme.dart';
import 'bp_reader_sheet_chrome.dart';
import 'bp_reader_ui.dart';

class BpReaderSettingsSheet extends StatelessWidget {
  const BpReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BpReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final colors = BpReaderSheetColors(theme: readerTheme);
    final themeProvider = context.watch<ColorThemeProvider>();
    final fonts = context.watch<FontSettingsProvider>();
    final prefs = context.watch<ReaderPreferencesProvider>();
    final parallel = context.watch<ParallelReadingProvider>();

    String activeFontId = 'serif';
    if (fonts.fontSettings.useSystemFont) {
      activeFontId = 'sans';
    } else if (fonts.fontFamily == 'Fraunces') {
      activeFontId = 'fraunces';
    } else if (fonts.fontFamily == 'Roboto' ||
        fonts.fontFamily == 'Open Sans') {
      activeFontId = 'sans';
    }

    return BpReaderSheetContainer(
      colors: colors,
      title: 'Reading Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BpReaderMiniLabel(colors: colors, label: 'Reading theme'),
            BpReaderThemeSwatches(
              themes: themeProvider.availableThemes,
              selectedId: themeProvider.currentTheme.id,
              onSelected: themeProvider.setTheme,
            ),
            BpReaderMiniLabel(colors: colors, label: 'Type'),
            BpReaderSettingsRow(
              colors: colors,
              label: 'Font size',
              trailing: BpReaderStepper(
                colors: colors,
                valueLabel: fonts.fontSize.round().toString(),
                onDecrement: () {
                  final next = (fonts.fontSize - 1).clamp(14.0, 30.0);
                  fonts.setFontSize(next);
                },
                onIncrement: () {
                  final next = (fonts.fontSize + 1).clamp(14.0, 30.0);
                  fonts.setFontSize(next);
                },
              ),
            ),
            Divider(height: 1, color: colors.borderSoft),
            BpReaderSettingsRow(
              colors: colors,
              label: 'Line spacing',
              trailing: BpReaderStepper(
                colors: colors,
                valueLabel: fonts.lineHeight.toStringAsFixed(2),
                onDecrement: () {
                  final next = (fonts.lineHeight - 0.05).clamp(1.2, 2.0);
                  fonts.setLineHeight(next);
                },
                onIncrement: () {
                  final next = (fonts.lineHeight + 0.05).clamp(1.2, 2.0);
                  fonts.setLineHeight(next);
                },
              ),
            ),
            BpReaderMiniLabel(colors: colors, label: 'Font family'),
            Row(
              children: [
                Expanded(
                  child: _FontOpt(
                    colors: colors,
                    label: 'Serif',
                    active: activeFontId == 'serif',
                    style: AppTheme.scripture(fontSize: 11.5),
                    onTap: () {
                      final font = AvailableFont.defaultFonts
                          .firstWhere((f) => f.id == 'source_serif');
                      fonts.setAvailableFont(font);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FontOpt(
                    colors: colors,
                    label: 'Fraunces',
                    active: activeFontId == 'fraunces',
                    style: AppTheme.brandTitle(fontSize: 11.5),
                    onTap: () => fonts.setFontFamily('Fraunces'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FontOpt(
                    colors: colors,
                    label: 'Sans',
                    active: activeFontId == 'sans',
                    style: AppTheme.ui(fontSize: 11.5),
                    onTap: () {
                      final font = AvailableFont.defaultFonts
                          .firstWhere((f) => f.id == 'roboto');
                      fonts.setAvailableFont(font);
                    },
                  ),
                ),
              ],
            ),
            BpReaderMiniLabel(colors: colors, label: 'Options'),
            BpReaderSettingsRow(
              colors: colors,
              label: 'Verse numbers',
              trailing: BpReaderSwitch(
                colors: colors,
                value: prefs.showVerseNumbers,
                onChanged: prefs.setShowVerseNumbers,
              ),
            ),
            Divider(height: 1, color: colors.borderSoft),
            BpReaderSettingsRow(
              colors: colors,
              label: 'Red-letter words',
              trailing: BpReaderSwitch(
                colors: colors,
                value: prefs.redLetterWords,
                onChanged: prefs.setRedLetterWords,
              ),
            ),
            Divider(height: 1, color: colors.borderSoft),
            BpReaderSettingsRow(
              colors: colors,
              label: 'Focus mode on open',
              trailing: BpReaderSwitch(
                colors: colors,
                value: prefs.focusOnOpen,
                onChanged: prefs.setFocusOnOpen,
              ),
            ),
            if (parallel.available) ...[
              Divider(height: 1, color: colors.borderSoft),
              BpReaderSettingsRow(
                colors: colors,
                label: 'Parallel reading (Amharic)',
                trailing: BpReaderSwitch(
                  colors: colors,
                  value: parallel.enabled,
                  onChanged: (value) async {
                    await parallel.setEnabled(value);
                    if (value && context.mounted) {
                      final bible = context.read<BibleProvider>();
                      final book = bible.selectedBook;
                      if (book != null) {
                        await parallel.loadChapter(
                          book.id,
                          bible.selectedChapter,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FontOpt extends StatelessWidget {
  const _FontOpt({
    required this.colors,
    required this.label,
    required this.active,
    required this.style,
    required this.onTap,
  });

  final BpReaderSheetColors colors;
  final String label;
  final bool active;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? colors.gold : colors.borderFlat,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: style.copyWith(
              color: active ? colors.gold : colors.text2,
            ),
          ),
        ),
      ),
    );
  }
}
