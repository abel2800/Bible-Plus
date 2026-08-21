import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
import '../widgets/design/bp_illuminated.dart';
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
                if (dailyVerse != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _VerseOfDayCard(
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                      child: ReadingHeatmap(
                        readingDays: engagement.readingDays,
                      ),
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
                              color: AppTheme.indigo,
                              border: Border.all(color: AppTheme.gold),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppTheme.goldSoft,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppTheme.inkDark : AppTheme.ink;
    final cardBg = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final activeCell = isDark ? AppTheme.goldSoft : AppTheme.gold;
    final inactiveCell = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;

    final cells = List.generate(7, (index) {
      final active = index < (streak > 0 ? streak.clamp(0, 7) : 0);
      return Container(
        width: 11,
        height: 11,
        margin: EdgeInsets.only(right: index < 6 ? 4 : 0),
        decoration: BoxDecoration(
          color: active ? activeCell : inactiveCell,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: active ? activeCell : borderColor,
            width: active ? 0 : 1,
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F7A5C1D),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STREAK',
                  style: AppTheme.ui(
                    fontSize: 11,
                    weight: FontWeight.w700,
                    color: AppTheme.gold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak > 0 ? '$streak days' : '1 day',
                  style: AppTheme.brandTitle(
                    fontSize: 20,
                    weight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: cells),
              ],
            ),
          ),
          if (readToday)
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppTheme.success,
            )
          else
            const Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: AppTheme.gold,
            ),
        ],
      ),
    );
  }
}

class _VerseOfDayCard extends StatelessWidget {
  const _VerseOfDayCard({
    required this.verse,
    required this.reference,
    required this.versionId,
    required this.onOpen,
  });

  final String verse;
  final String reference;
  final String versionId;
  final VoidCallback onOpen;

  Future<void> _share(BuildContext context) async {
    const downloadLine = 'Get BiblePulse — link coming soon';
    final text = '"$verse"\n— $reference ($versionId)\n\n$downloadLine';
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      await Share.share(text, sharePositionOrigin: origin);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied — sharing isn\u2019t available here',
            style: AppTheme.ui(color: Colors.white),
          ),
          backgroundColor: AppTheme.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementProvider>();
    final study = context.watch<StudyProvider>();
    final liked = engagement.isVerseLiked(reference, versionId: versionId);
    final saved = study.isBookmarked(reference, versionId: versionId);
    return BpIlluminatedCard(
      tag: 'Verse of the day',
      text: verse,
      reference: reference,
      onTap: onOpen,
      actions: [
        BpIlluminatedAction(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          label: liked ? 'Liked' : 'Like',
          color: liked ? const Color(0xFFE0705A) : null,
          onTap: () => engagement.toggleVerseLike(
            reference,
            versionId: versionId,
          ),
        ),
        BpIlluminatedAction(
          icon: Icons.ios_share_rounded,
          label: 'Share',
          onTap: () => _share(context),
        ),
        BpIlluminatedAction(
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          label: saved ? 'Saved' : 'Save',
          onTap: () {
            if (saved) {
              study.removeBookmark(reference, versionId: versionId);
            } else {
              study.addBookmark(reference, verse, versionId: versionId);
            }
          },
        ),
      ],
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
          BpMedallion(
            size: 44,
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
          BpMedallion(
            size: 32,
            ringColor: AppTheme.gold,
            child: Icon(icon, color: AppTheme.gold, size: 16),
          ),
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
