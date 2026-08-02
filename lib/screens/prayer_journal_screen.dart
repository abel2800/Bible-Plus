import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/engagement_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/daily_prayer_service.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class PrayerJournalScreen extends StatefulWidget {
  const PrayerJournalScreen({super.key, this.initialVerseReference});

  final String? initialVerseReference;

  @override
  State<PrayerJournalScreen> createState() => _PrayerJournalScreenState();
}

class _PrayerJournalScreenState extends State<PrayerJournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReminderProvider>().refreshDailyPrayerNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;
    final daily = DailyPrayerService.forToday();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPrayer(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New prayer',
          style: AppTheme.ui(fontSize: 13, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  BpIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daily prayer',
                    style: AppTheme.brandTitle(fontSize: 22, color: ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                children: [
                  _DailyPrayerCard(prayer: daily),
                  const SizedBox(height: 22),
                  Text(
                    'Your prayer journal',
                    style: AppTheme.ui(
                      fontSize: 15,
                      weight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Save private prayers on this device. Mark them answered '
                    'when God responds.',
                    style: AppTheme.ui(fontSize: 12.5, color: soft),
                  ),
                  const SizedBox(height: 14),
                  if (engagement.prayers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.surface2Dark
                                  : AppTheme.surface2Light,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight,
                              ),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              size: 30,
                              color: AppTheme.gold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved prayers yet',
                            style:
                                AppTheme.brandTitle(fontSize: 18, color: ink),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap “New prayer” to write your own. Today’s guided '
                            'prayer is above.',
                            textAlign: TextAlign.center,
                            style: AppTheme.ui(
                              fontSize: 13.5,
                              color: soft,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final prayer in engagement.prayers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BpCard(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                tooltip: prayer.isAnswered
                                    ? 'Mark active'
                                    : 'Mark answered',
                                onPressed: () =>
                                    engagement.toggleAnswered(prayer.id),
                                icon: Icon(
                                  prayer.isAnswered
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color:
                                      prayer.isAnswered ? AppTheme.teal : faint,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prayer.text,
                                      style: AppTheme.scripture(
                                        fontSize: 15,
                                        height: 1.55,
                                        color: ink,
                                      ).copyWith(
                                        decoration: prayer.isAnswered
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: soft,
                                      ),
                                    ),
                                    if (prayer.verseReference != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        prayer.verseReference!.toUpperCase(),
                                        style: AppTheme.ui(
                                          fontSize: 11,
                                          weight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: AppTheme.gold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete prayer',
                                onPressed: () =>
                                    engagement.deletePrayer(prayer.id),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.vermilion,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPrayer(BuildContext context) async {
    final controller = TextEditingController();
    final referenceController =
        TextEditingController(text: widget.initialVerseReference);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'New prayer',
          style: AppTheme.brandTitle(fontSize: 18, color: ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              style: AppTheme.scripture(fontSize: 15, color: ink),
              decoration: const InputDecoration(labelText: 'Prayer'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              style: AppTheme.ui(fontSize: 14, color: ink),
              decoration: const InputDecoration(
                labelText: 'Verse reference (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTheme.ui(fontSize: 13, weight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      await context.read<EngagementProvider>().addPrayer(
            controller.text,
            verseReference: referenceController.text.trim().isEmpty
                ? null
                : referenceController.text.trim(),
          );
    }
    controller.dispose();
    referenceController.dispose();
  }
}

class _DailyPrayerCard extends StatelessWidget {
  const _DailyPrayerCard({required this.prayer});

  final DailyPrayer prayer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    return BpCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TODAY\'S PRAYER',
                style: AppTheme.ui(
                  fontSize: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.gold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  prayer.focus,
                  style: AppTheme.ui(
                    fontSize: 11,
                    weight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prayer.title,
            style: AppTheme.brandTitle(fontSize: 20, color: ink),
          ),
          const SizedBox(height: 10),
          Text(
            prayer.body,
            style: AppTheme.scripture(
              fontSize: 16,
              height: 1.55,
              color: soft,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'A new guided prayer appears each day. Turn on Daily prayer '
            'reminders in Settings to get a notification.',
            style: AppTheme.ui(fontSize: 12, color: soft, height: 1.4),
          ),
        ],
      ),
    );
  }
}
