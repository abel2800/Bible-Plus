import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../screens/audio_now_playing_screen.dart';
import '../services/audio_service.dart';
import '../services/audio_share_link.dart';
import '../services/deep_link_service.dart';

/// Listens for shared audio links and starts that chapter in Now Playing.
class AudioDeepLinkListener extends StatefulWidget {
  const AudioDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<AudioDeepLinkListener> createState() => _AudioDeepLinkListenerState();
}

class _AudioDeepLinkListenerState extends State<AudioDeepLinkListener> {
  StreamSubscription<AudioShareTarget>? _sub;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = DeepLinkService.instance.takePending();
      if (pending != null) {
        unawaited(_open(pending));
      }
      _sub = DeepLinkService.instance.stream.listen((target) {
        unawaited(_open(target));
      });
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _open(AudioShareTarget target) async {
    if (!mounted || _handling) return;
    _handling = true;
    try {
      final bible = context.read<BibleProvider>();
      final audio = context.read<AudioService>();
      if (!audio.enabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio is not available in this build.'),
          ),
        );
        return;
      }

      await bible.ready;
      if (!mounted) return;

      BibleBookLookup? match;
      for (final book in bible.books) {
        if (book.id == target.bookId) {
          match = (id: book.id, name: book.name, chapters: book.chapters);
          break;
        }
      }

      final bookName =
          target.bookName ?? match?.name ?? 'Book ${target.bookId}';
      final chapterCount = match?.chapters;

      await audio.playChapter(
        target.versionId,
        target.bookId,
        target.chapter,
        bookName: bookName,
        bookChapterCount: chapterCount,
        bookCatalog: [
          for (final b in bible.books)
            (id: b.id, name: b.name, chapters: b.chapters),
        ],
      );

      if (!mounted) return;
      if (audio.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(audio.lastError!)),
        );
        return;
      }

      // Avoid stacking multiple Now Playing routes from repeated links.
      Navigator.of(context).popUntil((route) => route.isFirst);
      await AudioNowPlayingScreen.open(context);
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

typedef BibleBookLookup = ({int id, String name, int chapters});
