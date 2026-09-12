import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/audio_download_provider.dart';
import '../../providers/bible_provider.dart';
import '../../providers/color_theme_provider.dart';
import '../../services/audio_service.dart';
import '../../utils/app_theme.dart';
import '../audio_sleep_timer_sheet.dart';

/// Full audio controls sheet — matches bible-plus-reading-page HTML mock.
class BpReaderAudioSheet extends StatelessWidget {
  const BpReaderAudioSheet({
    super.key,
    required this.bookTitle,
    required this.narratorLabel,
  });

  final String bookTitle;
  final String narratorLabel;

  static Future<void> show(
    BuildContext context, {
    required String bookTitle,
    required String narratorLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BpReaderAudioSheet(
        bookTitle: bookTitle,
        narratorLabel: narratorLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final isDark = readerTheme.isDark;
    final sheetBg = isDark ? const Color(0xFF141310) : const Color(0xFFFFFDF9);
    final card = isDark ? const Color(0xFF161512) : Colors.white;
    final card2 = isDark ? const Color(0xFF1B1916) : const Color(0xFFF3F1EA);
    final borderFlat = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.08);
    final gold = readerTheme.accentColor;
    final goldBright = isDark ? AppTheme.goldBright : AppTheme.goldBrightLight;
    final text1 = readerTheme.headerColor;
    final text3 = readerTheme.verseNumberColor;

    final progressMax = audio.duration.inMilliseconds <= 0
        ? 1.0
        : audio.duration.inMilliseconds.toDouble();
    final progress =
        (audio.position.inMilliseconds / progressMax).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: gold.withValues(alpha: 0.13))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderFlat,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Audio Bible',
                    style: AppTheme.brandTitle(
                      fontSize: 16,
                      weight: FontWeight.w500,
                      color: text1,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: card2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: text3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withValues(alpha: 0.13)),
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.5),
                    radius: 1.1,
                    colors: [
                      gold.withValues(alpha: 0.13),
                      card2,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 44,
                  color: gold.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                bookTitle,
                textAlign: TextAlign.center,
                style: AppTheme.brandTitle(
                  fontSize: 17,
                  weight: FontWeight.w500,
                  color: text1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                narratorLabel,
                textAlign: TextAlign.center,
                style: AppTheme.ui(fontSize: 11, color: text3),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: borderFlat,
                  valueColor: AlwaysStoppedAnimation<Color>(gold),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(audio.position),
                    style: AppTheme.ui(fontSize: 10, color: text3),
                  ),
                  Text(
                    audio.duration > Duration.zero
                        ? _fmt(audio.duration)
                        : '--:--',
                    style: AppTheme.ui(fontSize: 10, color: text3),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: audio.hasPreviousQueueItem ||
                            audio.position > const Duration(seconds: 5)
                        ? () => audio.playPreviousInQueue()
                        : null,
                    icon: Icon(Icons.skip_previous_rounded, color: text3),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: audio.isLoading
                          ? null
                          : () {
                              if (audio.isPlaying) {
                                audio.pause();
                              } else {
                                audio.play();
                              }
                            },
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [goldBright, gold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.13),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: audio.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.onGold,
                                ),
                              )
                            : Icon(
                                audio.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppTheme.onGold,
                                size: 26,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => audio.playNextInQueue(),
                    icon: Icon(Icons.skip_next_rounded, color: text3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AudioChip(
                      label: '${audio.speed.toStringAsFixed(1)}×',
                      active: true,
                      card: card,
                      borderFlat: borderFlat,
                      gold: gold,
                      text2: text3,
                      onTap: () {
                        const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
                        final idx = speeds.indexWhere(
                          (s) => (s - audio.speed).abs() < 0.01,
                        );
                        final next = speeds[(idx + 1) % speeds.length];
                        audio.setSpeed(next);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AudioChip(
                      label: audio.sleepUntil != null ? 'Timer on' : 'Sleep timer',
                      active: audio.sleepUntil != null,
                      card: card,
                      borderFlat: borderFlat,
                      gold: gold,
                      text2: text3,
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AudioSleepTimerSheet(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AudioChip(
                      label: 'Download',
                      card: card,
                      borderFlat: borderFlat,
                      gold: gold,
                      text2: text3,
                      onTap: () => _downloadChapter(context, audio),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadChapter(
    BuildContext context,
    AudioService audio,
  ) async {
    final downloads = context.read<AudioDownloadProvider>();
    final bible = context.read<BibleProvider>();
    final bookId = audio.activeBookId ?? bible.selectedBook?.id;
    if (bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chapter selected to download.')),
      );
      return;
    }
    final versionId = (audio.activeVersion != null &&
            audio.activeVersion!.isNotEmpty)
        ? audio.activeVersion!
        : bible.currentVersion;
    final book = bible.books.where((b) => b.id == bookId).firstOrNull;
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find book for download.')),
      );
      return;
    }
    if (downloads.downloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A download is already in progress.')),
      );
      return;
    }
    unawaited(
      downloads.downloadBook(
        versionId: versionId,
        bookId: book.id,
        chapterCount: book.chapters,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${book.name} audio…')),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }
}

class _AudioChip extends StatelessWidget {
  const _AudioChip({
    required this.label,
    required this.card,
    required this.borderFlat,
    required this.gold,
    required this.text2,
    this.active = false,
    this.onTap,
  });

  final String label;
  final Color card;
  final Color borderFlat;
  final Color gold;
  final Color text2;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? gold : borderFlat,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.ui(
              fontSize: 11,
              color: active ? gold : text2,
            ),
          ),
        ),
      ),
    );
  }
}
