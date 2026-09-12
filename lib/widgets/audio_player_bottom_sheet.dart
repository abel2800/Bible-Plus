import 'package:flutter/material.dart';

import '../models/bible_book.dart';
import '../utils/audio_player_navigation.dart';

class AudioPlayerBottomSheet extends StatelessWidget {
  final BibleBook book;
  final int chapter;
  final String versionId;

  const AudioPlayerBottomSheet({
    super.key,
    required this.book,
    required this.chapter,
    this.versionId = 'WEB',
  });

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      navigator.pop();
      openUnifiedAudioPlayer(
        navigator.context,
        bookTitle: '${book.name}, Chapter $chapter',
        narratorLabel: 'Narrated · $versionId',
      );
    });
    return const SizedBox.shrink();
  }
}
