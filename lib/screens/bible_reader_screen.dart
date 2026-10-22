import 'package:flutter/foundation.dart';
import 'dart:async';

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
import '../providers/journey_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/parallel_reading_provider.dart';
import '../providers/reader_preferences_provider.dart';
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

class _BibleReaderScreenState extends State<BibleReaderScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _readerStackKey = GlobalKey();
  final Map<int, GlobalKey> _verseKeys = {};
  int? _parallelBook;
  int? _parallelChapter;
  int? _lastAudioVerse;
  String? _journeyContextKey;
  bool _appliedFocusOnOpen = false;
  bool _focusPreferenceApplied = false;
  int? _selectedVerse;
  double? _popupTop;
  double? _popupLeft;
  bool _audioToggleInProgress = false;
  bool _readerWasDragged = false;
  String? _completionRecordedFor;
  String? _activeReaderLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (context.read<NavigationProvider>().focusMode &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        context.read<NavigationProvider>().focusMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _setFocusMode(bool value) {
    context.read<NavigationProvider>().setFocusMode(value);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(
        value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bibleProvider = Provider.of<BibleProvider>(context);
    final studyProvider = Provider.of<StudyProvider>(context);
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final fontSettings = context.watch<FontSettingsProvider>().fontSettings;
    final audioService = context.read<AudioService>();
    final audioState = context
        .select<AudioService, (bool, bool, int?, int?, String?, int?, bool)>(
      (audio) => (
        audio.isPlaying,
        audio.hasActiveSession,
        audio.currentVerse,
        audio.activeBookId,
        audio.activeVersion,
        audio.activeChapter,
        audio.isLoading,
      ),
    );
    final audioStore = context.watch<AudioStoreProvider>();
    final parallel = context.watch<ParallelReadingProvider>();
    final readerPrefs = context.watch<ReaderPreferencesProvider>();
    final navigation = context.watch<NavigationProvider>();
    final focusMode = navigation.focusMode;
    final l10n = AppLocalizations.of(context);
    if (!_focusPreferenceApplied &&
        readerPrefs.ready &&
        navigation.selectedIndex == 1 &&
        bibleProvider.currentChapter.isNotEmpty) {
      _focusPreferenceApplied = true;
      if (readerPrefs.focusOnOpen && !_appliedFocusOnOpen) {
        _appliedFocusOnOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _setFocusMode(true);
        });
      }
    }
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final selectedBook = bibleProvider.selectedBook;
    final readerLocation = selectedBook == null
        ? null
        : '${bibleProvider.currentVersion}:${selectedBook.id}:${bibleProvider.selectedChapter}';
    if (readerLocation != _activeReaderLocation) {
      _activeReaderLocation = readerLocation;
      _completionRecordedFor = null;
      _readerWasDragged = false;
    }
    final selectedReader = navigation.selectedIndex == 1 &&
        selectedBook != null &&
        bibleProvider.currentChapter.isNotEmpty;
    final journeyKey = selectedReader
        ? '${selectedBook.id}:${bibleProvider.selectedChapter}:${bibleProvider.currentVersion}'
        : null;
    final journey = context.read<JourneyProvider>();
    if (journeyKey != _journeyContextKey ||
        (selectedReader && !journey.readerContextActive && !audioState.$1)) {
      if (!selectedReader) {
        journey.endReader();
      } else {
        journey.beginReader(
          bookId: selectedBook.id,
          bookName: selectedBook.name,
          chapter: bibleProvider.selectedChapter,
        );
      }
      _journeyContextKey = journeyKey;
    }
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
    final audioMatchesReader = audioState.$2 &&
        bibleProvider.selectedBook?.id == audioState.$4 &&
        bibleProvider.selectedChapter == audioState.$6 &&
        bibleProvider.currentVersion == audioState.$5;

    if (audioMatchesReader &&
        audioState.$3 != null &&
        audioState.$3 != _lastAudioVerse) {
      _lastAudioVerse = audioState.$3;
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
        (hasChapterAudio || audioMatchesReader) &&
        bibleProvider.currentChapter.isNotEmpty;
    final listBottomPad = showMiniAudio ? 12.0 : 24.0;

    return PopScope(
      canPop: !focusMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && focusMode) _setFocusMode(false);
      },
      child: Scaffold(
        backgroundColor: readerTheme.backgroundColor,
        body: BpReaderBackground(
          theme: readerTheme,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (selectedBook != null && !focusMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
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
                        const SizedBox(width: 8),
                        BpReaderFocusToggle(
                          theme: readerTheme,
                          active: false,
                          onChanged: _setFocusMode,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: bibleProvider.currentChapter.isEmpty
                      ? bibleProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildEmptyState(context, bibleProvider, l10n)
                      : Stack(
                          key: _readerStackKey,
                          children: [
                            Listener(
                              onPointerDown: (_) => context
                                  .read<JourneyProvider>()
                                  .readerInteraction(),
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification
                                          is ScrollUpdateNotification &&
                                      notification.dragDetails != null) {
                                    _readerWasDragged = true;
                                    context
                                        .read<JourneyProvider>()
                                        .readerInteraction();
                                  }
                                  if (notification is ScrollEndNotification) {
                                    final reachedEnd = _readerWasDragged &&
                                        notification.metrics.extentAfter <= 32;
                                    _readerWasDragged = false;
                                    final location =
                                        '${bibleProvider.currentVersion}:'
                                        '${selectedBook?.id}:'
                                        '${bibleProvider.selectedChapter}';
                                    if (reachedEnd &&
                                        selectedBook != null &&
                                        _completionRecordedFor != location) {
                                      _completionRecordedFor = location;
                                      unawaited(
                                        context
                                            .read<JourneyProvider>()
                                            .recordChapterCompleted(
                                              bookId: selectedBook.id,
                                              bookName: selectedBook.name,
                                              chapter:
                                                  bibleProvider.selectedChapter,
                                            ),
                                      );
                                    }
                                  }
                                  return false;
                                },
                                child: ListView.builder(
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
                                        audioState.$3 == verse.verse;
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
                                            accentColor:
                                                readerTheme.accentColor,
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
                                              padding: const EdgeInsets.only(
                                                  left: 18),
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
                              ),
                            ),
                            if (selectedBook != null && !focusMode)
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
                            if (_selectedVerse != null && !focusMode)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _dismissVersePopup,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            if (!focusMode &&
                                _selectedVerse != null &&
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
                            if (focusMode)
                              Positioned(
                                top: 8,
                                right: 12,
                                child: BpReaderFocusToggle(
                                  theme: readerTheme,
                                  active: true,
                                  onChanged: _setFocusMode,
                                ),
                              ),
                            if (bibleProvider.isLoading)
                              const Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                          ],
                        ),
                ),
              ],
            ),
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
    context.read<JourneyProvider>().readerInteraction(verse: verseNum);
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
    if (_audioToggleInProgress) return;
    _audioToggleInProgress = true;
    try {
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
    } finally {
      _audioToggleInProgress = false;
    }
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
