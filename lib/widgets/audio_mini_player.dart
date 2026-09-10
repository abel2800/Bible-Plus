import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../providers/color_theme_provider.dart';
import '../services/audio_service.dart';
import '../widgets/design/bp_reader_audio_sheet.dart';
import '../widgets/design/bp_reader_ui.dart';

class AudioMiniPlayer extends StatelessWidget {
  const AudioMiniPlayer({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    if (!audio.showMiniPlayer) {
      return const SizedBox.shrink();
    }

    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final bible = context.watch<BibleProvider>();
    final title = audio.activeTitle.isNotEmpty
        ? audio.activeTitle
        : '${bible.selectedBook?.name ?? 'Bible'} ${bible.selectedChapter} — Audio Bible';

    return Padding(
      padding: margin ?? const EdgeInsets.all(12),
      child: BpReaderAudioBar(
        theme: readerTheme,
        title: title,
        onTogglePlay: () {
          if (audio.isPlaying) {
            audio.pause();
          } else {
            audio.play();
          }
        },
        onOpenPlayer: () {
          BpReaderAudioSheet.show(
            context,
            bookTitle: title,
            narratorLabel: audio.activeSubtitle.isEmpty
                ? 'Bible audio'
                : audio.activeSubtitle,
          );
        },
      ),
    );
  }
}
