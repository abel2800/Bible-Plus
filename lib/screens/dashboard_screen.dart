import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/app_capabilities.dart';
import '../l10n/app_localizations.dart';
import '../models/reading_plan.dart';
import '../providers/audio_store_provider.dart';
import '../providers/bible_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/study_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/color_theme_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/home_widget_service.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';
import '../providers/reading_plan_provider.dart';
import '../utils/user_display_name.dart';
import '../widgets/design/bp_plus_background.dart';
import '../widgets/design/bp_gold_button.dart';
import '../widgets/app_drawer.dart';
import '../widgets/design/bp_widgets.dart';
import '../widgets/reading_heatmap.dart';
import 'audio_now_playing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _startListening(BuildContext context) async {
    final bible = context.read<BibleProvider>();
    final audio = context.read<AudioService>();
    final audioStore = context.read<AudioStoreProvider>();
    final prefs = context.read<UserPreferencesProvider>();
    final book = bible.selectedBook;
    if (book == null) {
      context.read<NavigationProvider>().setIndex(1);
      return;
    }
    if (!audio.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is not available in this build.')),
      );
      return;
    }
    final audioPackage = audioStore.bestPackageForTextVersion(
      bible.currentVersion,
      preferredPackageId: prefs.preferredAudioPackageId,
    );
    if (audioPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No audio for ${bible.currentVersion}. Open Bible Store → Audio Bibles.',
          ),
        ),
      );
      return;
    }
    await audio.playChapter(
      bible.currentVersion,
      book.id,
      bible.selectedChapter,
      bookName: book.name,
      bookChapterCount: book.chapters,
      audioPackageId: audioPackage.id,
      verseCharWeights: [
        for (final verse in bible.currentChapter)
          verse.text.length.clamp(1, 10000),
      ],
      bookCatalog: [
        for (final b in bible.books)
          (id: b.id, name: b.name, chapters: b.chapters),
      ],
    );
    if (!context.mounted) return;
    if (audio.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(audio.lastError!)),
      );
      return;
    }
    await AudioNowPlayingScreen.open(context);
  }

  Future<void> _continueListening(BuildContext context) async {
    final bible = context.read<BibleProvider>();
    final audio = context.read<AudioService>();
    if (!audio.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is not available in this build.')),
      );
      return;
    }

    if (audio.hasActiveSession) {
      if (!audio.isPlaying) {
        await audio.play();
      }
      if (context.mounted) {
        await AudioNowPlayingScreen.open(context);
      }
      return;
    }

    final version = audio.lastListenVersion ?? bible.currentVersion;
    final bookId = audio.lastListenBookId ?? bible.selectedBook?.id;
    final chapter = audio.lastListenChapter ?? bible.selectedChapter;
    if (bookId == null) {
      context.read<NavigationProvider>().setIndex(1);
      return;
    }

    final match = bible.books.where((b) => b.id == bookId).toList();
    final bookName = audio.lastListenBookName ??
        (match.isNotEmpty ? match.first.name : 'Chapter $chapter');
    final chapterCount = match.isNotEmpty ? match.first.chapters : chapter;

    await audio.playChapter(
      version,
      bookId,
      chapter,
      bookName: bookName,
      bookChapterCount: chapterCount,
      bookCatalog: [
        for (final b in bible.books)
          (id: b.id, name: b.name, chapters: b.chapters),
      ],
    );
    if (!context.mounted) return;
    if (audio.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(audio.lastError!)),
      );
      return;
    }
    await AudioNowPlayingScreen.open(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<BibleProvider>().refreshVerseOfTheDay();
      if (!mounted) return;
      final engagement = context.read<EngagementProvider>();
      await context.read<ReminderProvider>().refreshStreakNotifications(
            streak: engagement.streakWithGrace(),
            readToday: engagement.hasReadToday(),
          );
      if (!mounted) return;
      await context.read<ReminderProvider>().refreshDailyPrayerNotification();
      if (!mounted) return;
      final capabilities = context.read<AppCapabilities>();
      if (capabilities.readingPlans) {
        unawaited(context.read<ReadingPlanProvider>().loadPlans());
      }
      if (!mounted) return;

      final bible = context.read<BibleProvider>();
      final verse = bible.verseOfTheDay;
      unawaited(
        HomeWidgetService.sync(
          verseOfDay: verse,
          verseReference: verse == null
              ? ''
              : '${bible.getVerseReference(verse)} · ${bible.currentVersion}',
          streak: engagement.streakWithGrace(),
          readToday: engagement.hasReadToday(),
        ),
      );
    });
  }

  double _chapterProgress(BibleProvider bible) {
    if (bible.currentChapter.isEmpty || bible.selectedBook == null) return 0;
    final last = bible.lastReadVerse;
    if (last == null ||
        last.book != bible.selectedBook!.id ||
        last.chapter != bible.selectedChapter) {
      return 0;
    }
    final index = bible.currentChapter.indexWhere((v) => v.verse == last.verse);
    if (index < 0) return 0;
    return (index + 1) / bible.currentChapter.length;
  }

  ({UserReadingPlan? userPlan, ReadingPlan? activePlan}) _readingPlanSnapshot(
    BuildContext context,
    AppCapabilities capabilities,
  ) {
    if (!capabilities.readingPlans) {
      return (userPlan: null, activePlan: null);
    }
    final plans = context.watch<ReadingPlanProvider>();
    if (plans.userPlans.isEmpty) {
      return (userPlan: null, activePlan: null);
    }
    final userPlan = plans.userPlans.firstWhere(
      (p) => !p.isCompleted,
      orElse: () => plans.userPlans.first,
    );
    return (
      userPlan: userPlan,
      activePlan: plans.getPlanById(userPlan.planId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    final bible = context.watch<BibleProvider>();
    final audio = context.watch<AudioService>();
    final dailyVerse = bible.verseOfTheDay;
    final theme = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context);
    final capabilities = context.watch<AppCapabilities>();
    final engagement = context.watch<EngagementProvider>();
    final study = context.watch<StudyProvider>();
    final planSnapshot = _readingPlanSnapshot(context, capabilities);
    final userPlan = planSnapshot.userPlan;
    final activePlan = planSnapshot.activePlan;
    final streak = engagement.streakWithGrace();
    final greeting = UserDisplayName.greeting(l10n, context);
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final chapterProgress = _chapterProgress(bible);
    final daysRead = engagement.readingDays.length;
    final highlightCount = study.highlights.length;
    final recentHighlights = [...study.highlights]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final today = DateTime.now();
    final todayPrayer = engagement.prayers.where((p) {
      final d = p.createdAt.toLocal();
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();

    return Scaffold(
      backgroundColor: t.appBg,
      drawer: const AppDrawer(),
      body: BpPlusBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          BpIconButton(
                            icon: Icons.menu_rounded,
                            tooltip: 'Open menu',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                          const Spacer(),
                          BpIconButton(
                            icon: Icons.search_rounded,
                            tooltip: l10n.searchScripture,
                            onPressed: () =>
                                context.read<NavigationProvider>().setIndex(3),
                          ),
                          const SizedBox(width: 4),
                          BpIconButton(
                            icon: theme.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            tooltip: theme.isDarkMode
                                ? 'Use light mode'
                                : 'Use dark mode',
                            onPressed: () async {
                              final nextDark = !theme.isDarkMode;
                              await theme.setThemeMode(
                                nextDark ? ThemeMode.dark : ThemeMode.light,
                              );
                              if (!context.mounted) return;
                              await context
                                  .read<ColorThemeProvider>()
                                  .syncWithAppBrightness(nextDark);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateLabel,
                                  style: AppTheme.ui(
                                    fontSize: 10.5,
                                    color: t.inkFaint,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  greeting,
                                  style: AppTheme.brandTitle(
                                    fontSize: 18,
                                    weight: FontWeight.w500,
                                    color: t.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BpIconButton(
                            icon: Icons.settings_outlined,
                            tooltip: l10n.settings,
                            onPressed: () =>
                                context.read<NavigationProvider>().setIndex(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (dailyVerse != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: _WordTodayCard(
                          verse: dailyVerse.text,
                          reference: bible.getVerseReference(dailyVerse),
                          versionId: bible.currentVersion,
                          onOpen: () async {
                            await bible.goToVerse(
                              dailyVerse.book,
                              dailyVerse.chapter,
                              dailyVerse.verse,
                            );
                            if (context.mounted) {
                              context.read<NavigationProvider>().setIndex(1);
                            }
                          },
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _ContinueReadingCard(
                        title: bible.selectedBook == null
                            ? l10n.chooseBookToRead
                            : '${bible.selectedBook!.name} ${bible.selectedChapter}',
                        progress: chapterProgress,
                        buttonLabel: l10n.continueReading,
                        onContinue: () =>
                            context.read<NavigationProvider>().setIndex(1),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: BpStatPill(
                              value: '$streak',
                              label: 'Day streak',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BpStatPill(
                              value: '$daysRead',
                              label: 'Days read',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BpStatPill(
                              value: '$highlightCount',
                              label: 'Highlights',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (userPlan != null && activePlan != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S PLAN",
                              style: AppTheme.ui(
                                fontSize: 12.5,
                                weight: FontWeight.w600,
                                color: AppTheme.gold,
                                letterSpacing: 0.02,
                              ),
                            ),
                            const SizedBox(height: 8),
                            BpCard(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/reading_plans',
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  _PlanRing(
                                    progress: userPlan.progress.clamp(0.0, 1.0),
                                    label:
                                        '${(userPlan.progress * 100).round()}%',
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activePlan.title['en'] ??
                                              activePlan.name,
                                          style: AppTheme.ui(
                                            fontSize: 13,
                                            weight: FontWeight.w600,
                                            color: t.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Day ${userPlan.currentDay} of ${activePlan.duration}',
                                          style: AppTheme.ui(
                                            fontSize: 10.5,
                                            color: t.inkFaint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (todayPrayer.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRAYER',
                              style: AppTheme.ui(
                                fontSize: 12.5,
                                weight: FontWeight.w600,
                                color: AppTheme.gold,
                                letterSpacing: 0.02,
                              ),
                            ),
                            const SizedBox(height: 8),
                            BpCard(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/prayer_journal',
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l10n.dailyPrayer,
                                        style: AppTheme.ui(
                                          fontSize: 12.5,
                                          weight: FontWeight.w500,
                                          color: t.ink,
                                        ),
                                      ),
                                      Text(
                                        'Today',
                                        style: AppTheme.ui(
                                          fontSize: 10,
                                          color: t.inkFaint,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    todayPrayer.first.text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.ui(
                                      fontSize: 12.5,
                                      color: t.inkSoft,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (recentHighlights.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RECENT HIGHLIGHTS',
                              style: AppTheme.ui(
                                fontSize: 12.5,
                                weight: FontWeight.w600,
                                color: AppTheme.gold,
                                letterSpacing: 0.02,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 42,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: recentHighlights.length.clamp(0, 8),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 9),
                                itemBuilder: (context, index) {
                                  final item = recentHighlights[index];
                                  return ActionChip(
                                    label: Text(item.verseReference),
                                    onPressed: () {
                                      context
                                          .read<NavigationProvider>()
                                          .setIndex(2);
                                    },
                                    backgroundColor: t.surface,
                                    side: BorderSide(
                                      color: t.border.withValues(alpha: 0.55),
                                    ),
                                    labelStyle: AppTheme.ui(
                                      fontSize: 11.5,
                                      color: t.inkSoft,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _StreakEncouragementCard(
                        streak: streak,
                        readToday: engagement.hasReadToday(),
                        title: engagement.streakTitle(),
                        encouragement: engagement.streakEncouragement(),
                        progress: engagement.progressToNextMilestone(),
                        nextMilestone: engagement.nextMilestone,
                        longest: engagement.longestStreak,
                        onKeepAlive: () =>
                            context.read<NavigationProvider>().setIndex(1),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: BpCard(
                        padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                        child: ReadingHeatmap(
                          readingDays: engagement.readingDays,
                          readingCounts: engagement.readingCounts,
                        ),
                      ),
                    ),
                  ),
                  if (capabilities.audio)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _GuidedRow(
                          icon: Icons.headphones_rounded,
                          eyebrow: l10n.continueListening,
                          title: audio.hasActiveSession
                              ? audio.activeTitle
                              : (audio.hasLastListen
                                  ? audio.lastListenLabel
                                  : (bible.selectedBook == null
                                      ? l10n.chapterAudio
                                      : '${bible.selectedBook!.name} ${bible.selectedChapter}')),
                          trailingLabel: l10n.listen,
                          onTap: () => _continueListening(context),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _GuidedRow(
                        icon: Icons.edit_note_rounded,
                        eyebrow: l10n.myStudy,
                        title: study.notes.isEmpty
                            ? l10n.noNotes
                            : '${study.notes.length} ${l10n.notes}',
                        trailingLabel: l10n.seeAll,
                        onTap: () =>
                            context.read<NavigationProvider>().setIndex(2),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                      child: Text(
                        l10n.quickActions,
                        style: AppTheme.ui(
                          fontSize: 15,
                          weight: FontWeight.w700,
                          color: t.ink,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: [
                          _QuickCard(
                            icon: Icons.menu_book_rounded,
                            title: l10n.readBible,
                            subtitle: l10n.browseBooks,
                            onTap: () =>
                                context.read<NavigationProvider>().setIndex(1),
                          ),
                          _QuickCard(
                            icon: Icons.headphones_rounded,
                            title: l10n.listen,
                            subtitle: capabilities.audio
                                ? l10n.chapterAudio
                                : l10n.audioGated,
                            onTap: () {
                              if (capabilities.audio) {
                                _startListening(context);
                              } else {
                                context.read<NavigationProvider>().setIndex(1);
                              }
                            },
                          ),
                          _QuickCard(
                            icon: Icons.favorite_border_rounded,
                            title: l10n.dailyPrayer,
                            subtitle: l10n.prayerJournal,
                            onTap: () =>
                                Navigator.pushNamed(context, '/prayer_journal'),
                          ),
                          if (capabilities.readingPlans)
                            _QuickCard(
                              icon: Icons.checklist_rounded,
                              title: l10n.readingPlans,
                              subtitle: l10n.seeAll,
                              onTap: () => Navigator.pushNamed(
                                  context, '/reading_plans'),
                            )
                          else
                            _QuickCard(
                              icon: Icons.bookmark_border_rounded,
                              title: l10n.bookmarks,
                              subtitle: l10n.seeAll,
                              onTap: () => context
                                  .read<NavigationProvider>()
                                  .setIndex(2),
                            ),
                          _QuickCard(
                            icon: Icons.auto_awesome_rounded,
                            title: l10n.createWallpaper,
                            subtitle: l10n.verseWallpaper,
                            onTap: () =>
                                Navigator.pushNamed(context, '/wallpaper'),
                          ),
                          _QuickCard(
                            icon: Icons.storefront_rounded,
                            title: l10n.bibleStore,
                            subtitle: l10n.browseBibles,
                            onTap: () =>
                                Navigator.pushNamed(context, '/bible_store'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordTodayCard extends StatelessWidget {
  const _WordTodayCard({
    required this.verse,
    required this.reference,
    required this.versionId,
    required this.onOpen,
  });

  final String verse;
  final String reference;
  final String versionId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    final trimmed = verse.trimLeft();
    final drop = trimmed.isNotEmpty ? trimmed.characters.first : '';
    final body = trimmed.length > 1 ? trimmed.substring(drop.length) : trimmed;

    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.border.withValues(alpha: 0.65)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -30,
                child: Container(
                  width: 160,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.gold.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR WORD FOR TODAY',
                    style: AppTheme.ui(
                      fontSize: 10.5,
                      weight: FontWeight.w600,
                      color: AppTheme.gold,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (drop.isNotEmpty)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: drop,
                            style: AppTheme.brandTitle(
                              fontSize: 40,
                              weight: FontWeight.w500,
                              color: AppTheme.gold,
                            ).copyWith(
                              fontFamily: 'Cormorant Garamond',
                              height: 0.85,
                            ),
                          ),
                          TextSpan(
                            text: body,
                            style: AppTheme.scripture(
                              fontSize: 16,
                              color: t.ink,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      verse,
                      style: AppTheme.scripture(
                        fontSize: 16,
                        color: t.ink,
                        height: 1.55,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    reference.toUpperCase(),
                    style: AppTheme.ui(
                      fontSize: 11.5,
                      color: t.inkSoft,
                      letterSpacing: 0.04,
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
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.title,
    required this.progress,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final double progress;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return BpCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE READING',
            style: AppTheme.ui(
              fontSize: 10.5,
              weight: FontWeight.w600,
              color: AppTheme.gold,
              letterSpacing: 0.03,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.brandTitle(
              fontSize: 19,
              weight: FontWeight.w500,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: BpGoldProgressTrack(progress: progress)),
              const SizedBox(width: 10),
              Text(
                progress <= 0 ? '0%' : '${(progress * 100).round()}%',
                style: AppTheme.ui(fontSize: 10.5, color: t.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BpGoldButton(
            label: buttonLabel,
            expanded: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _PlanRing extends StatelessWidget {
  const _PlanRing({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: t.border.withValues(alpha: 0.45),
            color: AppTheme.gold,
          ),
          Text(
            label,
            style: AppTheme.ui(
              fontSize: 9.5,
              weight: FontWeight.w600,
              color: t.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakEncouragementCard extends StatelessWidget {
  const _StreakEncouragementCard({
    required this.streak,
    required this.readToday,
    required this.title,
    required this.encouragement,
    required this.progress,
    required this.nextMilestone,
    required this.longest,
    required this.onKeepAlive,
  });

  final int streak;
  final bool readToday;
  final String title;
  final String encouragement;
  final double progress;
  final int? nextMilestone;
  final int longest;
  final VoidCallback onKeepAlive;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return BpCard(
      onTap: onKeepAlive,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                readToday
                    ? Icons.check_circle_rounded
                    : Icons.local_fire_department_rounded,
                size: 18,
                color: readToday ? AppTheme.success : AppTheme.gold,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.ui(
                  fontSize: 14,
                  weight: FontWeight.w700,
                  color: t.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            encouragement,
            style: AppTheme.ui(fontSize: 12.5, color: t.inkSoft, height: 1.45),
          ),
          if (nextMilestone != null) ...[
            const SizedBox(height: 12),
            BpGoldProgressTrack(progress: progress),
            const SizedBox(height: 4),
            Text(
              'Next milestone: $nextMilestone days · Best: $longest',
              style: AppTheme.ui(fontSize: 10, color: t.inkFaint),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuidedRow extends StatelessWidget {
  const _GuidedRow({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.trailingLabel,
    required this.onTap,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String trailingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return BpCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withValues(alpha: 0.12),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: AppTheme.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppTheme.ui(fontSize: 12, color: t.inkFaint),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(
                    fontSize: 15,
                    weight: FontWeight.w700,
                    color: t.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BpPill(label: trailingLabel),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return BpCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  border:
                      Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: AppTheme.gold, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(
                    fontSize: 13,
                    weight: FontWeight.w700,
                    color: t.ink,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(fontSize: 11, color: t.inkFaint, height: 1.2),
          ),
        ],
      ),
    );
  }
}
