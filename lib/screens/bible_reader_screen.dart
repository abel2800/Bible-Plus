import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bible_verse.dart';
import '../models/color_theme.dart';
import '../providers/bible_provider.dart';
import '../providers/audio_store_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/color_theme_provider.dart';
import '../providers/font_settings_provider.dart';
import '../providers/study_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/parallel_reading_provider.dart';
import '../providers/reader_preferences_provider.dart';
import '../providers/reminder_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/book_selector_bottom_sheet.dart';
import '../widgets/version_selector_bottom_sheet.dart';
import '../widgets/design/bp_widgets.dart';
import '../widgets/design/bp_reader_ui.dart';
import '../services/audio_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/verse_card.dart';
import '../widgets/design/bp_reader_note_sheet.dart';
import '../widgets/design/bp_reader_settings_sheet.dart';
import '../widgets/design/bp_reader_audio_sheet.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _readerStackKey = GlobalKey();
  final Map<int, GlobalKey> _verseKeys = {};
  int? _parallelBook;
  int? _parallelChapter;
  int? _lastAudioVerse;
  String? _streakDayRecorded;
  bool _focusMode = false;
  bool _appliedFocusOnOpen = false;
  int? _selectedVerse;
  double? _popupTop;
  double? _popupLeft;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bibleProvider = Provider.of<BibleProvider>(context);
    final studyProvider = Provider.of<StudyProvider>(context);
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final fontSettings = context.watch<FontSettingsProvider>().fontSettings;
    final audioService = context.watch<AudioService>();
    final audioStore = context.watch<AudioStoreProvider>();
    final parallel = context.watch<ParallelReadingProvider>();
    final readerPrefs = context.watch<ReaderPreferencesProvider>();
    final l10n = AppLocalizations.of(context);
    if (!_appliedFocusOnOpen &&
        readerPrefs.ready &&
        readerPrefs.focusOnOpen &&
        bibleProvider.currentChapter.isNotEmpty) {
      _appliedFocusOnOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _focusMode = true);
      });
    }
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    if (bibleProvider.currentChapter.isNotEmpty) {
      final todayKey =
          '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
      if (_streakDayRecorded != todayKey) {
        _streakDayRecorded = todayKey;
        final engagement = context.read<EngagementProvider>();
        final reminders = context.read<ReminderProvider>();
        final messenger = ScaffoldMessenger.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final chapterCount = bibleProvider.currentChapter.length;
          final celebration = await engagement.recordReading(
            DateTime.now(),
            chapterCount.clamp(1, 8),
          );
          await reminders.refreshStreakNotifications(
            streak: engagement.streakWithGrace(),
            readToday: engagement.hasReadToday(),
          );
          if (celebration != null && mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(celebration),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    }
    final selectedBook = bibleProvider.selectedBook;
    if (parallel.enabled &&
        selectedBook != null &&
        (_parallelBook != selectedBook.id ||
            _parallelChapter != bibleProvider.selectedChapter)) {
      _parallelBook = selectedBook.id;
      _parallelChapter = bibleProvider.selectedChapter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        parallel.loadChapter(selectedBook.id, bibleProvider.selectedChapter);
      });
    }
    final hasChapterAudio = audioStore.hasAudioForTextVersion(
      bibleProvider.currentVersion,
    );
    final audioMatchesReader = audioService.hasActiveSession &&
        bibleProvider.selectedBook?.id == audioService.activeBookId &&
        bibleProvider.selectedChapter == audioService.activeChapter &&
        bibleProvider.currentVersion == audioService.activeVersion;

    if (audioMatchesReader &&
        audioService.currentVerse != null &&
        audioService.currentVerse != _lastAudioVerse) {
      _lastAudioVerse = audioService.currentVerse;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final verseContext = _verseKeys[_lastAudioVerse]?.currentContext;
        if (verseContext != null) {
          Scrollable.ensureVisible(
            verseContext,
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            alignment: audioService.hasVerseTimings ? 0.28 : 0.18,
          );
        }
      });
    } else if (!audioMatchesReader) {
      _lastAudioVerse = null;
    }

    final showMiniAudio = selectedBook != null &&
        hasChapterAudio &&
        bibleProvider.currentChapter.isNotEmpty &&
        !_focusMode;
    final listBottomPad = showMiniAudio ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: readerTheme.backgroundColor,
      body: BpReaderBackground(
        theme: readerTheme,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (selectedBook != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          offset:
                              _focusMode ? const Offset(0, -1.2) : Offset.zero,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 240),
                            opacity: _focusMode ? 0 : 1,
                            child: IgnorePointer(
                              ignoring: _focusMode,
                              child: BpReaderTopBar(
                                theme: readerTheme,
                                bookName: selectedBook.name,
                                chapter: bibleProvider.selectedChapter,
                                version: bibleProvider.currentVersion,
                                onTitleTap: () => _showBookSelector(context),
                                onTranslationTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      const VersionSelectorBottomSheet(),
                                ),
                                onSettingsTap: () =>
                                    BpReaderSettingsSheet.show(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BpReaderFocusToggle(
                        theme: readerTheme,
                        active: _focusMode,
                        onChanged: (value) => setState(() {
                          _focusMode = value;
                          if (value) {
                            _selectedVerse = null;
                            _popupTop = null;
                            _popupLeft = null;
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: bibleProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : bibleProvider.currentChapter.isEmpty
                        ? _buildEmptyState(context, bibleProvider, l10n)
                        : Stack(
                            key: _readerStackKey,
                            children: [
                              ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  listBottomPad + bottomInset + 72,
                                ),
                                itemCount:
                                    bibleProvider.currentChapter.length + 1,
                                itemBuilder: (context, rawIndex) {
                                  if (rawIndex == 0) {
                                    return BpReaderChapterHeading(
                                      chapter: bibleProvider.selectedChapter,
                                      theme: readerTheme,
                                    );
                                  }
                                  final index = rawIndex - 1;
                                  final verse =
                                      bibleProvider.currentChapter[index];
                                  final reference =
                                      bibleProvider.getVerseReference(verse);
                                  final versionId =
                                      bibleProvider.currentVersion;
                                  final isHighlighted =
                                      studyProvider.isHighlighted(
                                    reference,
                                    versionId: versionId,
                                  );
                                  final highlightColor =
                                      studyProvider.getHighlightColor(
                                    reference,
                                    versionId: versionId,
                                  );
                                  final isSpoken = audioMatchesReader &&
                                      audioService.currentVerse == verse.verse;
                                  final secondary = parallel.enabled
                                      ? parallel.verse(verse.verse)
                                      : null;
                                  final isSelected =
                                      _selectedVerse == verse.verse;

                                  return KeyedSubtree(
                                    key: _verseKeys.putIfAbsent(
                                      verse.verse,
                                      GlobalKey.new,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        VerseCard(
                                          verse: verse,
                                          reference: reference,
                                          versionId: versionId,
                                          isHighlighted: isHighlighted,
                                          highlightColor: highlightColor,
                                          isBookmarked:
                                              studyProvider.isBookmarked(
                                            reference,
                                            versionId: versionId,
                                          ),
                                          hasNote:
                                              studyProvider.getNoteForVerse(
                                                    reference,
                                                    versionId: versionId,
                                                  ) !=
                                                  null,
                                          isAudioActive: isSpoken,
                                          selected: isSelected,
                                          onTap: () =>
                                              _toggleVersePopup(verse.verse),
                                          textColor: readerTheme.textColor,
                                          verseNumberColor:
                                              readerTheme.verseNumberColor,
                                          accentColor: readerTheme.accentColor,
                                          fontSize: fontSettings.fontSize,
                                          lineHeight: fontSettings.lineHeight,
                                          fontFamily: fontSettings.fontFamily,
                                          useSystemFont:
                                              fontSettings.useSystemFont,
                                          useDropCap: verse.verse == 1,
                                          showVerseNumbers:
                                              readerPrefs.showVerseNumbers,
                                          redLetterWords:
                                              readerPrefs.redLetterWords,
                                          readerTheme: readerTheme,
                                        ),
                                        if (secondary != null) ...[
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 18),
                                            child: Text(
                                              secondary.text,
                                              style: AppTheme.ethopic(
                                                fontSize:
                                                    fontSettings.fontSize - 1,
                                                color: readerTheme.textColor
                                                    .withValues(alpha: 0.85),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                              if (selectedBook != null && !_focusMode)
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  top: MediaQuery.sizeOf(context).height * 0.38,
                                  child: BpReaderChapterNav(
                                    theme: readerTheme,
                                    onPrevious: () =>
                                        bibleProvider.previousChapter(),
                                    onNext: () => bibleProvider.nextChapter(),
                                  ),
                                ),
                              if (_selectedVerse != null)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: _dismissVersePopup,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              if (_selectedVerse != null &&
                                  _popupTop != null &&
                                  _popupLeft != null)
                                Positioned(
                                  top: _popupTop,
                                  left: _popupLeft,
                                  child: _buildVersePopup(
                                    context,
                                    bibleProvider: bibleProvider,
                                    studyProvider: studyProvider,
                                    readerTheme: readerTheme,
                                  ),
                                ),
                              if (showMiniAudio)
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 8 + bottomInset,
                                  child: BpReaderAudioBar(
                                    theme: readerTheme,
                                    title:
                                        '${selectedBook.name} ${bibleProvider.selectedChapter} — Audio Bible',
                                    onTogglePlay: () =>
                                        _toggleAudio(context, bibleProvider),
                                    onOpenPlayer: () =>
                                        _openAudioSheet(context, bibleProvider),
                                  ),
                                ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissVersePopup() {
    setState(() {
      _selectedVerse = null;
      _popupTop = null;
      _popupLeft = null;
    });
  }

  void _toggleVersePopup(int verseNum) {
    if (_selectedVerse == verseNum) {
      setState(() {
        _selectedVerse = null;
        _popupTop = null;
        _popupLeft = null;
      });
      return;
    }
    setState(() => _selectedVerse = verseNum);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _positionVersePopup(verseNum);
    });
  }

  void _positionVersePopup(int verseNum) {
    final verseContext = _verseKeys[verseNum]?.currentContext;
    final stackContext = _readerStackKey.currentContext;
    if (verseContext == null || stackContext == null || !mounted) return;

    final verseBox = verseContext.findRenderObject() as RenderBox?;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (verseBox == null || stackBox == null) return;

    final versePos = verseBox.localToGlobal(Offset.zero, ancestor: stackBox);
    var top = versePos.dy + verseBox.size.height + 8;
    var left = versePos.dx.clamp(12.0, stackBox.size.width - 228);
    if (top + 130 > stackBox.size.height - 96) {
      top = (versePos.dy - 130).clamp(8.0, stackBox.size.height - 140);
    }
    setState(() {
      _popupTop = top;
      _popupLeft = left;
    });
  }

  Widget _buildVersePopup(
    BuildContext context, {
    required BibleProvider bibleProvider,
    required StudyProvider studyProvider,
    required ReaderColorTheme readerTheme,
  }) {
    final verseNum = _selectedVerse!;
    final verse =
        bibleProvider.currentChapter.firstWhere((v) => v.verse == verseNum);
    final reference = bibleProvider.getVerseReference(verse);
    final versionId = bibleProvider.currentVersion;

    return BpVersePopup(
      theme: readerTheme,
      selectedColor: studyProvider.getHighlightColor(
        reference,
        versionId: versionId,
      ),
      isBookmarked: studyProvider.isBookmarked(
        reference,
        versionId: versionId,
      ),
      onHighlight: (color) async {
        await studyProvider.addHighlight(
          reference,
          verse.text,
          color,
          versionId: versionId,
        );
      },
      onNote: () {
        setState(() {
          _selectedVerse = null;
          _popupTop = null;
          _popupLeft = null;
        });
        _showVerseNoteSheet(
          context,
          verse: verse,
          reference: reference,
          versionId: versionId,
        );
      },
      onBookmark: () async {
        if (studyProvider.isBookmarked(reference, versionId: versionId)) {
          await studyProvider.removeBookmark(reference, versionId: versionId);
        } else {
          await studyProvider.addBookmark(
            reference,
            verse.text,
            versionId: versionId,
          );
        }
      },
      onCopy: () async {
        await Clipboard.setData(
          ClipboardData(text: '${verse.text}\n— $reference'),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verse copied'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onShare: () async {
        final text = '${verse.text}\n— $reference\n\nBible Plus';
        try {
          await Share.share(text);
        } catch (_) {
          await Clipboard.setData(ClipboardData(text: text));
        }
      },
      onClear: () async {
        await studyProvider.removeHighlight(reference, versionId: versionId);
        setState(() {
          _selectedVerse = null;
          _popupTop = null;
          _popupLeft = null;
        });
      },
    );
  }

  void _openAudioSheet(BuildContext context, BibleProvider bibleProvider) {
    final book = bibleProvider.selectedBook;
    if (book == null) return;
    BpReaderAudioSheet.show(
      context,
      bookTitle: '${book.name}, Chapter ${bibleProvider.selectedChapter}',
      narratorLabel: 'Narrated · ${bibleProvider.currentVersion}',
    );
  }

  Future<void> _toggleAudio(
    BuildContext context,
    BibleProvider bibleProvider,
  ) async {
    final audio = context.read<AudioService>();
    if (audio.isPlaying) {
      await audio.pause();
      return;
    }
    if (audio.hasActiveSession &&
        audio.activeBookId == bibleProvider.selectedBook?.id &&
        audio.activeChapter == bibleProvider.selectedChapter) {
      await audio.play();
      return;
    }
    await _playChapterAudio(context, bibleProvider);
  }

  Future<void> _playChapterAudio(
    BuildContext context,
    BibleProvider bibleProvider, {
    bool openPlayer = false,
  }) async {
    if (bibleProvider.selectedBook == null) return;

    final audioService = Provider.of<AudioService>(context, listen: false);
    final audioStore = Provider.of<AudioStoreProvider>(context, listen: false);
    final prefs = Provider.of<UserPreferencesProvider>(context, listen: false);
    final book = bibleProvider.selectedBook!;
    final audioPackage = audioStore.bestPackageForTextVersion(
      bibleProvider.currentVersion,
      preferredPackageId: prefs.preferredAudioPackageId,
    );
    if (audioPackage == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No audio is available for ${bibleProvider.currentVersion}.',
            ),
          ),
        );
      }
      return;
    }
    await audioService.playChapter(
      bibleProvider.currentVersion,
      book.id,
      bibleProvider.selectedChapter,
      bookName: book.name,
      bookChapterCount: book.chapters,
      audioPackageId: audioPackage.id,
      verseCharWeights: [
        for (final verse in bibleProvider.currentChapter)
          verse.text.length.clamp(1, 10000),
      ],
      bookCatalog: [
        for (final b in bibleProvider.books)
          (id: b.id, name: b.name, chapters: b.chapters),
      ],
    );
    if (!context.mounted) return;
    if (audioService.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(audioService.lastError!)),
      );
      return;
    }
    if (openPlayer) {
      _openAudioSheet(context, bibleProvider);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bibleProvider = Provider.of<BibleProvider>(context, listen: false);
      final pending = bibleProvider.pendingScrollVerse;
      if (pending != null &&
          bibleProvider.pendingScrollBookId == bibleProvider.selectedBook?.id &&
          bibleProvider.pendingScrollChapter == bibleProvider.selectedChapter) {
        final index =
            bibleProvider.currentChapter.indexWhere((v) => v.verse == pending);
        if (index != -1) {
          final verseContext = _verseKeys[pending]?.currentContext;
          if (verseContext != null) {
            Scrollable.ensureVisible(
              verseContext,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
        }
        bibleProvider.clearPendingScroll();
      }
    });
  }

  Future<void> _showVerseNoteSheet(
    BuildContext context, {
    required BibleVerse verse,
    required String reference,
    required String versionId,
  }) {
    return BpReaderNoteSheet.show(
      context,
      verse: verse,
      reference: reference,
      versionId: versionId,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    BibleProvider bibleProvider,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final book = bibleProvider.selectedBook;
    final hasBook = book != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: AppTheme.gold.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 20),
            Text(
              hasBook
                  ? 'Could not load ${book.name} ${bibleProvider.selectedChapter}.'
                  : l10n.chooseBookToRead,
              textAlign: TextAlign.center,
              style: AppTheme.brandTitle(
                fontSize: 22,
                weight: FontWeight.w700,
                color: isDark ? AppTheme.inkDark : AppTheme.ink,
              ),
            ),
            if (hasBook) ...[
              const SizedBox(height: 10),
              Text(
                'Try another translation or tap browse to pick a chapter.',
                textAlign: TextAlign.center,
                style: AppTheme.ui(
                  fontSize: 14,
                  color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: BpPrimaryButton(
                label: l10n.browseBooks,
                onPressed: () => showBookSelector(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookSelector(BuildContext context) {
    showBookSelector(context);
  }
}
