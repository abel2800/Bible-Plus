import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/app_capabilities.dart';
import '../l10n/app_localizations.dart';
import '../providers/bible_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/study_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/color_theme_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/home_widget_service.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';
import '../utils/time_of_day_greeting.dart';
import '../utils/streak_copy.dart';
import '../widgets/app_drawer.dart';
import '../widgets/design/bp_widgets.dart';
import '../widgets/reading_heatmap.dart';
import 'audio_now_playing_screen.dart';

const _staggerStep = Duration(milliseconds: 70);
const _entranceDuration = Duration(milliseconds: 320);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _startListening(BuildContext context) async {
    final bible = context.read<BibleProvider>();
    final audio = context.read<AudioService>();
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
    await audio.playChapter(
      bible.currentVersion,
      book.id,
      bible.selectedChapter,
      bookName: book.name,
      bookChapterCount: book.chapters,
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
    final streak = engagement.streakWithGrace();
    final notesCount = context.watch<StudyProvider>().notes.length;
    final greeting = TimeOfDayGreeting.now(l10n);

    return Scaffold(
      backgroundColor: t.appBg,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                    child: Builder(
                      builder: (context) => Row(
                        children: [
                          BpIconButton(
                            icon: Icons.menu_rounded,
                            tooltip: 'Open menu',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                          const Spacer(),
                          if (streak > 0) ...[
                            BpPill(
                              icon: Icons.local_fire_department_rounded,
                              label: '$streak',
                            ),
                            const SizedBox(width: 8),
                          ],
                          BpIconButton(
                            icon: Icons.search_rounded,
                            tooltip: l10n.searchScripture,
                            onPressed: () =>
                                context.read<NavigationProvider>().setIndex(3),
                          ),
                          const SizedBox(width: 8),
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
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: Text(
                      greeting,
                      style: AppTheme.brandTitle(fontSize: 26, color: t.ink),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: _StreakCard(
                      streak: streak,
                      readToday: engagement.hasReadToday(),
                      title: engagement.streakTitle(),
                      encouragement: engagement.streakEncouragement(),
                      progress: engagement.progressToNextMilestone(),
                      nextMilestone: engagement.nextMilestone,
                      longest: engagement.longestStreak,
                      onKeepAlive: () =>
                          context.read<NavigationProvider>().setIndex(1),
                    ).animate().fadeIn(duration: _entranceDuration).slideY(
                          begin: 0.08,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: BpCard(
                      child: ReadingHeatmap(
                        readingDays: engagement.readingDays,
                      ),
                    )
                        .animate(delay: _staggerStep)
                        .fadeIn(duration: _entranceDuration)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                ),
                if (dailyVerse != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _VerseOfDayCard(
                        verse: dailyVerse.text,
                        reference:
                            '${bible.getVerseReference(dailyVerse)} · ${bible.currentVersion}',
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
                      )
                          .animate(delay: _staggerStep * 2)
                          .fadeIn(duration: _entranceDuration)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _GuidedRow(
                      icon: Icons.menu_book_rounded,
                      eyebrow: l10n.continueReading,
                      title: bible.selectedBook == null
                          ? l10n.chooseBookToRead
                          : '${bible.selectedBook!.name} ${bible.selectedChapter}',
                      trailingLabel: l10n.readBible,
                      onTap: () {
                        context.read<NavigationProvider>().setIndex(1);
                      },
                    ),
                  ),
                ),
                if (capabilities.audio)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                      title: notesCount == 0
                          ? l10n.noNotes
                          : '$notesCount ${l10n.notes}',
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
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
                            onTap: () =>
                                Navigator.pushNamed(context, '/reading_plans'),
                          )
                        else
                          _QuickCard(
                            icon: Icons.bookmark_border_rounded,
                            title: l10n.bookmarks,
                            subtitle: l10n.seeAll,
                            onTap: () =>
                                context.read<NavigationProvider>().setIndex(2),
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
                      ]
                          .asMap()
                          .entries
                          .map(
                            (entry) => entry.value
                                .animate(
                                  delay: _staggerStep * (3 + entry.key),
                                )
                                .fadeIn(duration: _entranceDuration)
                                .slideY(
                                  begin: 0.12,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    child: BpCard(
                      onTap: () =>
                          context.read<NavigationProvider>().setIndex(1),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tapBookName,
                                  style: AppTheme.ui(
                                    fontSize: 14,
                                    color: t.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => context
                                      .read<NavigationProvider>()
                                      .setIndex(1),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.gold,
                                    foregroundColor: AppTheme.onGold,
                                  ),
                                  child: Text(l10n.readBible),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.goldSoft, AppTheme.gold],
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppTheme.onGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
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
    final milestoneHit = StreakCopy.isMilestone(streak) && readToday;

    return BpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  readToday
                      ? Icons.local_fire_department_rounded
                      : Icons.local_fire_department_outlined,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak <= 0 ? 'Start a streak' : '$streak-day streak',
                      style: AppTheme.ui(
                        fontSize: 16,
                        weight: FontWeight.w700,
                        color: t.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTheme.ui(
                        fontSize: 12.5,
                        weight: FontWeight.w600,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
              if (longest > 0)
                Text(
                  'Best $longest',
                  style: AppTheme.ui(fontSize: 11, color: t.inkSoft),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            encouragement,
            style: AppTheme.ui(fontSize: 13, color: t.inkSoft, height: 1.4),
          ),
          if (nextMilestone != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: t.border,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              milestoneHit
                  ? 'Milestone reached — next goal $nextMilestone days'
                  : 'Next badge at $nextMilestone days',
              style: AppTheme.ui(fontSize: 11, color: t.inkFaint),
            ),
          ],
          if (!readToday) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onKeepAlive,
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: Text(
                  streak <= 0
                      ? 'Read to light your flame'
                      : 'Keep the flame alive',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.onGold,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppTheme.teal,
                ),
                const SizedBox(width: 6),
                Text(
                  'Today’s reading counts',
                  style: AppTheme.ui(
                    fontSize: 12,
                    weight: FontWeight.w600,
                    color: AppTheme.teal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VerseOfDayCard extends StatelessWidget {
  const _VerseOfDayCard({
    required this.verse,
    required this.reference,
    required this.onOpen,
  });

  final String verse;
  final String reference;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [AppTheme.surface2Dark, AppTheme.appBgDark]
                  : const [AppTheme.surface2Light, AppTheme.appBgLight],
            ),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 14, color: AppTheme.gold),
                    const SizedBox(width: 6),
                    Text(
                      'Verse of the Day',
                      style: AppTheme.ui(
                        fontSize: 12,
                        weight: FontWeight.w700,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reference,
                  style: AppTheme.ui(
                    fontSize: 12,
                    weight: FontWeight.w600,
                    color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  verse,
                  style: AppTheme.scripture(
                    fontSize: 19,
                    color: isDark ? AppTheme.inkDark : AppTheme.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
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
              color: t.surface2,
              borderRadius: BorderRadius.circular(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.gold, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(
              fontSize: 14,
              weight: FontWeight.w700,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(fontSize: 12, color: t.inkFaint),
          ),
        ],
      ),
    );
  }
}
