import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';

class ReaderPlaybackControls extends StatelessWidget {
  const ReaderPlaybackControls({
    super.key,
    required this.audioEnabled,
    this.onOpenPlayer,
  });

  final bool audioEnabled;
  final VoidCallback? onOpenPlayer;

  Future<void> _stepChapter(BuildContext context, int delta) async {
    final bible = context.read<BibleProvider>();
    if (delta > 0) {
      await bible.nextChapter();
    } else {
      await bible.previousChapter();
    }
  }

  Future<void> _togglePlay(BuildContext context) async {
    final bible = context.read<BibleProvider>();
    final audio = context.read<AudioService>();
    final book = bible.selectedBook;
    if (book == null) return;

    if (!audio.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is not available in this build.')),
      );
      return;
    }

    if (audio.isPlaying) {
      await audio.pause();
      return;
    }

    final sameChapter = audio.hasActiveSession &&
        audio.activeBookId == book.id &&
        audio.activeChapter == bible.selectedChapter &&
        audio.activeVersion == bible.currentVersion &&
        audio.duration > Duration.zero;

    if (sameChapter) {
      await audio.play();
    } else {
      await audio.playChapter(
        bible.currentVersion,
        book.id,
        bible.selectedChapter,
        bookName: book.name,
        bookChapterCount: book.chapters,
        bookCatalog: [
          for (final b in bible.books)
            (id: b.id, name: b.name, chapters: b.chapters),
        ],
      );
    }

    if (context.mounted && audio.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(audio.lastError!)),
      );
    }
    onOpenPlayer?.call();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubble =
        (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72);

    return IgnorePointer(
      ignoring: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundControl(
            size: 44,
            color: bubble,
            icon: Icons.chevron_left_rounded,
            onPressed: () => _stepChapter(context, -1),
          ),
          const SizedBox(width: 14),
          _RoundControl(
            size: 64,
            color: bubble,
            icon: audio.isLoading
                ? null
                : (audio.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
            loading: audio.isLoading,
            onPressed: audioEnabled ? () => _togglePlay(context) : null,
          ),
          const SizedBox(width: 14),
          _RoundControl(
            size: 44,
            color: bubble,
            icon: Icons.chevron_right_rounded,
            onPressed: () => _stepChapter(context, 1),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.size,
    required this.color,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final double size;
  final Color color;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;

    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: loading
              ? Padding(
                  padding: EdgeInsets.all(size * 0.28),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: fg,
                  ),
                )
              : Icon(icon, color: fg, size: size * 0.48),
        ),
      ),
    );
  }
}

class ReaderSpeedChip extends StatelessWidget {
  const ReaderSpeedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label =
        '${audio.speed.toStringAsFixed(audio.speed % 1 == 0 ? 0 : 2)}×';

    return Material(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: audio.enabled ? audio.cycleSpeed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: AppTheme.ui(
              fontSize: 12,
              weight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
