import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_capabilities.dart';
import '../providers/bible_provider.dart';
import '../providers/color_theme_provider.dart';
import '../providers/font_settings_provider.dart';
import '../models/font_settings.dart';
import '../providers/study_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/parallel_reading_provider.dart';
import '../providers/reminder_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/book_selector_bottom_sheet.dart';
import '../widgets/version_selector_bottom_sheet.dart';
import '../widgets/design/bp_widgets.dart';
import '../widgets/reader_playback_controls.dart';
import '../services/audio_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/verse_card.dart';
import 'audio_now_playing_screen.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  int? _parallelBook;
  int? _parallelChapter;
  int? _lastAudioVerse;
  String? _streakDayRecorded;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bibleProvider = Provider.of<BibleProvider>(context);
    final studyProvider = Provider.of<StudyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final fontSettings = context.watch<FontSettingsProvider>().fontSettings;
    final capabilities = context.watch<AppCapabilities>();
    final audioService = context.watch<AudioService>();
    final parallel = context.watch<ParallelReadingProvider>();
    final l10n = AppLocalizations.of(context);
    final showAudioBar = audioService.isPlaying ||
        audioService.isLoading ||
        audioService.hasActiveSession;

    if (bibleProvider.currentChapter.isNotEmpty) {
      final todayKey =
          '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
      if (_streakDayRecorded != todayKey) {
        _streakDayRecorded = todayKey;
        final engagement = context.read<EngagementProvider>();
        final reminders = context.read<ReminderProvider>();
        final messenger = ScaffoldMessenger.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final celebration = await engagement.recordReading();
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
    final audioMatchesReader = audioService.hasActiveSession &&
        bibleProvider.selectedBook?.id == audioService.activeBookId &&
        bibleProvider.selectedChapter == audioService.activeChapter;

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

    return Scaffold(
      backgroundColor: readerTheme.backgroundColor,
      body: ColoredBox(
        color: readerTheme.backgroundColor,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        if (bibleProvider.selectedBook != null) ...[
                          _ReaderChip(
                            label:
                                '${bibleProvider.selectedBook!.name} ${bibleProvider.selectedChapter}',
                            isDark: readerTheme.isDark,
                            onTap: () => _showBookSelector(context),
                          ),
                          const SizedBox(width: 8),
                          _ReaderChip(
                            label: bibleProvider.currentVersion,
                            isDark: readerTheme.isDark,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    const VersionSelectorBottomSheet(),
                              );
                            },
                          ),
                        ] else
                          _ReaderChip(
                            label: l10n.selectBook,
                            isDark: readerTheme.isDark,
                            onTap: () => _showBookSelector(context),
                          ),
                        const Spacer(),
                        if (parallel.available)
                          BpIconButton(
                            icon: parallel.enabled
                                ? Icons.view_column_rounded
                                : Icons.view_column_outlined,
                            tooltip: parallel.enabled
                                ? 'Disable Amharic parallel reading'
                                : 'Enable Amharic parallel reading',
                            onPressed: () =>
                                parallel.setEnabled(!parallel.enabled),
                          ),
                        if (capabilities.audio) ...[
                          const SizedBox(width: 4),
                          const ReaderSpeedChip(),
                          const SizedBox(width: 4),
                          BpIconButton(
                            icon: Icons.volume_up_rounded,
                            tooltip: 'Play chapter audio',
                            onPressed: () =>
                                _playChapterAudio(context, bibleProvider),
                          ),
                        ],
                        const SizedBox(width: 4),
                        BpIconButton(
                          icon: Icons.search_rounded,
                          tooltip: 'Search',
                          onPressed: () =>
                              context.read<NavigationProvider>().setIndex(3),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          tooltip: 'More',
                          offset: const Offset(0, 40),
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: readerTheme.headerColor,
                          ),
                          onSelected: (value) async {
                            if (value == 'appearance') {
                              await _showReadingAppearance(context);
                            } else if (value == 'am') {
                              await themeProvider
                                  .setLocale(const Locale('am', ''));
                            } else if (value == 'en') {
                              await themeProvider
                                  .setLocale(const Locale('en', ''));
                            } else if (value == 'books') {
                              _showBookSelector(context);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'books',
                              child: Text('Browse books'),
                            ),
                            PopupMenuItem(
                              value: 'appearance',
                              child: Text('Reading appearance'),
                            ),
                            PopupMenuItem(
                              value: 'en',
                              child: Text('English UI'),
                            ),
                            PopupMenuItem(
                              value: 'am',
                              child: Text('Amharic UI'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: bibleProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : bibleProvider.currentChapter.isEmpty
                            ? _buildEmptyState(context, bibleProvider, l10n)
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  22,
                                  8,
                                  22,
                                  showAudioBar ? 140 : 100,
                                ),
                                itemCount: bibleProvider.currentChapter.length,
                                itemBuilder: (context, index) {
                                  final verse =
                                      bibleProvider.currentChapter[index];
                                  final reference =
                                      bibleProvider.getVerseReference(verse);
                                  final isHighlighted =
                                      studyProvider.isHighlighted(reference);
                                  final highlightColor = studyProvider
                                      .getHighlightColor(reference);
                                  final isSpoken = audioMatchesReader &&
                                      audioService.currentVerse == verse.verse;
                                  final secondary = parallel.enabled
                                      ? parallel.verse(verse.verse)
                                      : null;

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
                                          isHighlighted: isHighlighted,
                                          highlightColor: highlightColor,
                                          isBookmarked: studyProvider
                                              .isBookmarked(reference),
                                          hasNote: studyProvider
                                                  .getNoteForVerse(reference) !=
                                              null,
                                          isAudioActive: isSpoken,
                                          textColor: readerTheme.textColor,
                                          verseNumberColor:
                                              readerTheme.verseNumberColor,
                                          fontSize: fontSettings.fontSize,
                                          lineHeight: fontSettings.lineHeight,
                                          fontFamily: fontSettings.fontFamily,
                                          useSystemFont:
                                              fontSettings.useSystemFont,
                                        ),
                                        if (secondary != null) ...[
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 26),
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
                                        if (index <
                                            bibleProvider
                                                    .currentChapter.length -
                                                1)
                                          const SizedBox(height: 4),
                                      ],
                                    ),
                                  );
                                },
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

  Future<void> _playChapterAudio(
    BuildContext context,
    BibleProvider bibleProvider, {
    bool openPlayer = true,
  }) async {
    if (bibleProvider.selectedBook == null) return;

    final audioService = Provider.of<AudioService>(context, listen: false);
    final book = bibleProvider.selectedBook!;
    await audioService.playChapter(
      bibleProvider.currentVersion,
      book.id,
      bibleProvider.selectedChapter,
      bookName: book.name,
      bookChapterCount: book.chapters,
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
      await AudioNowPlayingScreen.open(context);
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

  Future<void> _showReadingAppearance(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reading appearance',
                    style: AppTheme.brandTitle(
                      fontSize: 19,
                      weight: FontWeight.w600,
                      color: isDark ? AppTheme.inkDark : AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<ColorThemeProvider>(
                    builder: (context, provider, _) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: provider.availableThemes
                          .map(
                            (theme) => ChoiceChip(
                              selected: provider.currentTheme.id == theme.id,
                              avatar: CircleAvatar(
                                backgroundColor: theme.backgroundColor,
                              ),
                              label: Text(theme.name),
                              onSelected: (_) => provider.setTheme(theme.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer<FontSettingsProvider>(
                    builder: (context, provider, _) {
                      final selectedFontId = provider.fontSettings.useSystemFont
                          ? 'system'
                          : AvailableFont.defaultFonts
                                  .where(
                                    (f) =>
                                        f.fontFamily == provider.fontFamily &&
                                        f.id != 'system',
                                  )
                                  .map((f) => f.id)
                                  .firstOrNull ??
                              'merriweather';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Font style',
                            style: AppTheme.ui(
                              fontSize: 14,
                              weight: FontWeight.w600,
                              color: isDark ? AppTheme.inkDark : AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: selectedFontId,
                            isExpanded: true,
                            items: [
                              for (final font in AvailableFont.defaultFonts)
                                DropdownMenuItem(
                                  value: font.id,
                                  child: Text(font.name),
                                ),
                            ],
                            onChanged: (id) async {
                              if (id == null) return;
                              final font = AvailableFont.defaultFonts
                                  .firstWhere((f) => f.id == id);
                              await provider.setAvailableFont(font);
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Text size · ${provider.fontSize.round()}',
                            style: AppTheme.ui(
                              fontSize: 14,
                              weight: FontWeight.w600,
                              color: isDark ? AppTheme.inkDark : AppTheme.ink,
                            ),
                          ),
                          Slider(
                            min: 14,
                            max: 30,
                            divisions: 16,
                            activeColor: AppTheme.gold,
                            value: provider.fontSize.clamp(14, 30).toDouble(),
                            label: provider.fontSize.round().toString(),
                            onChanged: provider.setFontSize,
                          ),
                          Text(
                            'Line spacing · ${provider.lineHeight.toStringAsFixed(1)}',
                            style: AppTheme.ui(
                              fontSize: 14,
                              weight: FontWeight.w600,
                              color: isDark ? AppTheme.inkDark : AppTheme.ink,
                            ),
                          ),
                          Slider(
                            min: 1.2,
                            max: 2,
                            divisions: 8,
                            activeColor: AppTheme.gold,
                            value: provider.lineHeight.clamp(1.2, 2).toDouble(),
                            onChanged: provider.setLineHeight,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    BibleProvider bibleProvider,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              l10n.chooseBookToRead,
              textAlign: TextAlign.center,
              style: AppTheme.brandTitle(
                fontSize: 22,
                weight: FontWeight.w700,
                color: isDark ? AppTheme.inkDark : AppTheme.ink,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
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

class _ReaderChip extends StatelessWidget {
  const _ReaderChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: AppTheme.ui(
              fontSize: 13,
              weight: FontWeight.w600,
              color: isDark ? AppTheme.inkDark : AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
