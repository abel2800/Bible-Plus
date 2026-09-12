import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../services/audio_service.dart';
import '../widgets/design/bp_reader_audio_sheet.dart';

/// Opens the unified gold-themed audio sheet from any entry point.
Future<void> openUnifiedAudioPlayer(
  BuildContext context, {
  String? bookTitle,
  String? narratorLabel,
}) {
  final audio = context.read<AudioService>();
  final bible = context.read<BibleProvider>();
  final book = bible.selectedBook;
  final resolvedTitle = bookTitle ??
      (audio.activeTitle.isNotEmpty
          ? audio.activeTitle
          : book != null
              ? '${book.name}, Chapter ${bible.selectedChapter}'
              : 'Audio Bible');
  final resolvedNarrator = narratorLabel ??
      (audio.activeSubtitle.isNotEmpty
          ? audio.activeSubtitle
          : 'Narrated · ${(audio.activeVersion != null && audio.activeVersion!.isNotEmpty) ? audio.activeVersion : bible.currentVersion}');

  return BpReaderAudioSheet.show(
    context,
    bookTitle: resolvedTitle,
    narratorLabel: resolvedNarrator,
  );
}
