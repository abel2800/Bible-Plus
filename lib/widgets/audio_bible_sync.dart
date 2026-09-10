import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_store_provider.dart';
import '../providers/bible_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../services/audio_service.dart';

/// Keeps Bible reading and audio playback aligned on book, chapter, and version.
class AudioBibleSync extends StatefulWidget {
  const AudioBibleSync({super.key, required this.child});

  final Widget child;

  @override
  State<AudioBibleSync> createState() => _AudioBibleSyncState();
}

class _AudioBibleSyncState extends State<AudioBibleSync> {
  int? _trackedBibleBook;
  int? _trackedBibleChapter;
  String? _trackedBibleVersion;
  int? _trackedAudioBook;
  int? _trackedAudioChapter;
  String? _trackedAudioVersion;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    context.watch<BibleProvider>();
    context.watch<AudioService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _busy) return;
      unawaited(_reconcile());
    });

    return widget.child;
  }

  Future<void> _reconcile() async {
    final bible = context.read<BibleProvider>();
    final audio = context.read<AudioService>();
    final audioStore = context.read<AudioStoreProvider>();
    final prefs = context.read<UserPreferencesProvider>();

    final bibleBook = bible.selectedBook?.id;
    final bibleChapter = bible.selectedChapter;
    final bibleVersion = bible.currentVersion;

    final audioBook = audio.activeBookId;
    final audioChapter = audio.activeChapter;
    final audioVersion = audio.activeVersion;

    final bibleChanged = bibleBook != _trackedBibleBook ||
        bibleChapter != _trackedBibleChapter ||
        bibleVersion != _trackedBibleVersion;
    final audioChanged = audioBook != _trackedAudioBook ||
        audioChapter != _trackedAudioChapter ||
        audioVersion != _trackedAudioVersion;

    if (!audio.hasActiveSession) {
      _updateTracked(
        bibleBook: bibleBook,
        bibleChapter: bibleChapter,
        bibleVersion: bibleVersion,
        audioBook: audioBook,
        audioChapter: audioChapter,
        audioVersion: audioVersion,
      );
      return;
    }

    if (!bibleChanged && !audioChanged) return;

    _busy = true;
    try {
      if (bibleChanged &&
          bibleVersion != audioVersion &&
          audioVersion != null) {
        final package = audioStore.bestPackageForTextVersion(
          bibleVersion,
          preferredPackageId: prefs.preferredAudioPackageId,
        );
        if (package == null || bibleBook == null) {
          await audio.stopPlayback(clearSession: true);
        } else {
          final resume = audio.isPlaying;
          await _startAudioForReader(bible, audio, package.id);
          if (!resume) await audio.pause();
        }
        return;
      }

      if (audioChanged &&
          audioVersion != null &&
          audioBook != null &&
          audioChapter != null &&
          audioVersion == bibleVersion &&
          (audioBook != bibleBook || audioChapter != bibleChapter)) {
        await bible.loadChapter(audioBook, audioChapter);
        return;
      }

      if (bibleChanged &&
          bibleBook != null &&
          bibleVersion == audioVersion &&
          (audioBook != bibleBook || audioChapter != bibleChapter)) {
        final package = audioStore.bestPackageForTextVersion(
          bibleVersion,
          preferredPackageId: prefs.preferredAudioPackageId,
        );
        if (package == null) {
          await audio.stopPlayback(clearSession: true);
          return;
        }
        final resume = audio.isPlaying;
        await _syncAudioToReader(bible, audio, package.id);
        if (!resume) await audio.pause();
      }
    } finally {
      _busy = false;
      if (!mounted) return;
      final latestBible = context.read<BibleProvider>();
      final latestAudio = context.read<AudioService>();
      _updateTracked(
        bibleBook: latestBible.selectedBook?.id,
        bibleChapter: latestBible.selectedChapter,
        bibleVersion: latestBible.currentVersion,
        audioBook: latestAudio.activeBookId,
        audioChapter: latestAudio.activeChapter,
        audioVersion: latestAudio.activeVersion,
      );
    }
  }

  Future<void> _syncAudioToReader(
    BibleProvider bible,
    AudioService audio,
    String packageId,
  ) async {
    final book = bible.selectedBook;
    if (book == null) return;

    if (audio.activeBookId == book.id &&
        audio.activeVersion == bible.currentVersion) {
      final queueIndex = audio.indexInQueueFor(
        bookId: book.id,
        chapter: bible.selectedChapter,
        versionId: bible.currentVersion,
      );
      if (queueIndex != null) {
        await audio.playQueueItem(queueIndex);
        return;
      }
    }

    await _startAudioForReader(bible, audio, packageId);
  }

  Future<void> _startAudioForReader(
    BibleProvider bible,
    AudioService audio,
    String packageId,
  ) async {
    final book = bible.selectedBook;
    if (book == null) return;

    await audio.playChapter(
      bible.currentVersion,
      book.id,
      bible.selectedChapter,
      bookName: book.name,
      bookChapterCount: book.chapters,
      audioPackageId: packageId,
      verseCharWeights: [
        for (final verse in bible.currentChapter)
          verse.text.length.clamp(1, 10000),
      ],
      bookCatalog: [
        for (final b in bible.books)
          (id: b.id, name: b.name, chapters: b.chapters),
      ],
    );
  }

  void _updateTracked({
    required int? bibleBook,
    required int bibleChapter,
    required String bibleVersion,
    required int? audioBook,
    required int? audioChapter,
    required String? audioVersion,
  }) {
    _trackedBibleBook = bibleBook;
    _trackedBibleChapter = bibleChapter;
    _trackedBibleVersion = bibleVersion;
    _trackedAudioBook = audioBook;
    _trackedAudioChapter = audioChapter;
    _trackedAudioVersion = audioVersion;
  }
}
