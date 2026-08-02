import 'package:flutter/material.dart';

import '../screens/audio_now_playing_screen.dart';
import '../models/bible_book.dart';

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
      AudioNowPlayingScreen.open(navigator.context);
    });
    return const SizedBox.shrink();
  }
}
