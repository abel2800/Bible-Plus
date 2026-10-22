import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/journey_session.dart';
import '../providers/journey_provider.dart';
import '../providers/study_provider.dart';
import '../services/journey_calculator.dart';
import '../utils/app_theme.dart';

class BibleJourneyScreen extends StatefulWidget {
  const BibleJourneyScreen({super.key});

  @override
  State<BibleJourneyScreen> createState() => _BibleJourneyScreenState();
}

class _BibleJourneyScreenState extends State<BibleJourneyScreen> {
  late int _year;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _year = today.year;
    _selectedDay = DateTime(today.year, today.month, today.day);
  }

  @override
  Widget build(BuildContext context) {
    final journey = context.watch<JourneyProvider>();
    final colors = context.colors;
    final today = DateTime.now();
    final selected = journey.day(_selectedDay);
    final historicalGoal = journey.goalForDate(_selectedDay);
    final study = context.watch<StudyProvider>();
    final selectedNotes = study.notes.where((item) {
      final date = item.createdAt.toLocal();
      return date.year == _selectedDay.year &&
          date.month == _selectedDay.month &&
          date.day == _selectedDay.day;
    }).toList();
    final selectedHighlights = study.highlights.where((item) {
      final date = item.createdAt.toLocal();
      return date.year == _selectedDay.year &&
          date.month == _selectedDay.month &&
          date.day == _selectedDay.day;
    }).toList();
    final sessions = [...selected.sessions]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    return Scaffold(
      backgroundColor: colors.appBg,
      appBar: AppBar(
        title: Text('Bible Journey',
            style: AppTheme.brandTitle(color: colors.ink)),
        backgroundColor: colors.appBg,
        actions: [
          if (journey.syncPending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: journey.isLoading
          ? const Center(child: CircularProgressIndicator())
          : journey.error != null && journey.sessions.isEmpty
              ? _ErrorState(onRetry: journey.initialize)
              : SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                          children: [
                            _GoalPanel(
                              journey: journey,
                              onEdit: () => _editGoal(context, journey),
                            ),
                            const SizedBox(height: 18),
                            _StatisticsRow(journey: journey),
                            const SizedBox(height: 24),
                            _YearHeatmap(
                              year: _year,
                              today: today,
                              selectedDay: _selectedDay,
                              dayFor: journey.day,
                              onYearChanged: (value) => setState(() {
                                _year = value;
                                final lastDay = DateTime(
                                  value,
                                  _selectedDay.month + 1,
                                  0,
                                ).day;
                                _selectedDay = DateTime(
                                  value,
                                  _selectedDay.month,
                                  _selectedDay.day.clamp(1, lastDay),
                                );
                              }),
                              onDaySelected: (value) => setState(() {
                                _selectedDay = value;
                                _year = value.year;
                              }),
                            ),
                            const SizedBox(height: 20),
                            _DayDetails(
                              day: selected,
                              selectedDate: _selectedDay,
                              sessions: sessions,
                              notes: selectedNotes
                                  .map((item) => item.verseReference)
                                  .toList(),
                              highlights: selectedHighlights
                                  .map((item) => item.verseReference)
                                  .toList(),
                              goalType: historicalGoal.type,
                              goalTarget: historicalGoal.target,
                              historicalGoalKnown: historicalGoal.known,
                              onPrevious: () => setState(() {
                                _selectedDay = _selectedDay
                                    .subtract(const Duration(days: 1));
                                _year = _selectedDay.year;
                              }),
                              onNext: _selectedDay.isBefore(
                                DateTime(today.year, today.month, today.day),
                              )
                                  ? () => setState(() {
                                        _selectedDay = _selectedDay
                                            .add(const Duration(days: 1));
                                        _year = _selectedDay.year;
                                      })
                                  : null,
                            ),
                            if (journey.error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Offline: saved journey data is available on this device. Sync will retry when available.',
                                style: TextStyle(color: colors.inkSoft),
                              ),
                            ],
                            if (constraints.maxWidth > 700)
                              const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<void> _editGoal(BuildContext context, JourneyProvider journey) async {
    final targetController = TextEditingController(
      text: journey.goalTarget.toString(),
    );
    var type = journey.goalType;
    var target = journey.goalTarget;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Daily goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<JourneyGoalType>(
                segments: const [
                  ButtonSegment(
                    value: JourneyGoalType.minutes,
                    label: Text('Minutes'),
                    icon: Icon(Icons.schedule_rounded),
                  ),
                  ButtonSegment(
                    value: JourneyGoalType.chapters,
                    label: Text('Chapters'),
                    icon: Icon(Icons.menu_book_rounded),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (selection) => setDialogState(() {
                  type = selection.first;
                  target = type == JourneyGoalType.minutes ? 20 : 1;
                  targetController.text = target.toString();
                }),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: (type == JourneyGoalType.minutes
                        ? [10, 20, 30, 45]
                        : [1, 2, 3, 5])
                    .map(
                      (value) => ChoiceChip(
                        label: Text('$value'),
                        selected: target == value,
                        onSelected: (_) => setDialogState(() {
                          target = value;
                          targetController.text = value.toString();
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      'Custom ${type == JourneyGoalType.minutes ? 'minutes' : 'chapters'}',
                  suffixText: type == JourneyGoalType.minutes ? 'min' : 'ch',
                ),
                onChanged: (value) => target = int.tryParse(value) ?? target,
              ),
              const SizedBox(height: 8),
              Text(
                'Past days keep their recorded activity. This goal setting applies from today onward.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
    targetController.dispose();
    if (saved == true) await journey.setGoal(type: type, target: target);
  }
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({required this.journey, required this.onEdit});

  final JourneyProvider journey;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = journey.goalProgress();
    final amount = journey.goalAmount();
    final unit =
        journey.goalType == JourneyGoalType.minutes ? 'min' : 'chapters';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today’s goal',
                  style: AppTheme.brandTitle(fontSize: 18, color: colors.ink),
                ),
              ),
              IconButton(
                tooltip: 'Change daily goal',
                onPressed: onEdit,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          Text(
            progress >= 1
                ? 'Goal complete. Thank you for making time for Scripture.'
                : '$amount of ${journey.goalTarget} $unit',
            style: TextStyle(color: colors.inkSoft),
          ),
          const SizedBox(height: 12),
          Semantics(
            label:
                'Daily ${journey.goalType.name} goal: $amount of ${journey.goalTarget} $unit',
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: colors.border,
              color: AppTheme.primaryGold(Theme.of(context).brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow({required this.journey});

  final JourneyProvider journey;

  @override
  Widget build(BuildContext context) {
    final summary = journey.summary;
    final hours = summary.totalSeconds ~/ 3600;
    final minutes = (summary.totalSeconds % 3600) ~/ 60;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Stat(label: 'Active days', value: '${summary.activeDays}'),
        _Stat(label: 'Current streak', value: '${summary.currentStreak} days'),
        _Stat(label: 'Longest streak', value: '${summary.longestStreak} days'),
        _Stat(label: 'Time in Scripture', value: '${hours}h ${minutes}m'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTheme.brandTitle(fontSize: 17, color: colors.ink)),
          Text(label, style: TextStyle(fontSize: 12, color: colors.inkSoft)),
        ],
      ),
    );
  }
}

class _YearHeatmap extends StatelessWidget {
  const _YearHeatmap({
    required this.year,
    required this.today,
    required this.selectedDay,
    required this.dayFor,
    required this.onYearChanged,
    required this.onDaySelected,
  });

  final int year;
  final DateTime today;
  final DateTime selectedDay;
  final JourneyDay Function(DateTime) dayFor;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final first = DateTime(year, 1, 1);
    final dayCount = DateTime(year + 1, 1, 1).difference(first).inDays;
    final leading = first.weekday % 7;
    final weeks = ((leading + dayCount) / 7).ceil();
    final dates = List<DateTime?>.generate(weeks * 7, (index) {
      final offset = index - leading;
      if (offset < 0 || offset >= dayCount) return null;
      return first.add(Duration(days: offset));
    });
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Reading history',
                    style:
                        AppTheme.brandTitle(fontSize: 17, color: colors.ink)),
              ),
              IconButton(
                tooltip: 'Previous year',
                onPressed: () => onYearChanged(year - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text('$year', style: TextStyle(color: colors.ink)),
              IconButton(
                tooltip: 'Next year',
                onPressed:
                    year < today.year ? () => onYearChanged(year + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    for (final label in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                      SizedBox(
                        height: 24,
                        child: Center(
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 10, color: colors.inkSoft)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: weeks * 24.0,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (var month = 1; month <= 12; month++)
                                Positioned(
                                  left: ((DateTime(year, month, 1)
                                                  .difference(first)
                                                  .inDays +
                                              leading) /
                                          7) *
                                      24,
                                  child: Text(
                                    DateFormat('MMM')
                                        .format(DateTime(year, month)),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.inkSoft,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var week = 0; week < weeks; week++)
                              SizedBox(
                                width: 24,
                                child: Column(
                                  children: [
                                    for (var weekday = 0;
                                        weekday < 7;
                                        weekday++)
                                      _HeatCell(
                                        date: dates[week * 7 + weekday],
                                        today: today,
                                        selected:
                                            dates[week * 7 + weekday] != null &&
                                                JourneyCalculator.dateKey(dates[
                                                        week * 7 + weekday]!) ==
                                                    JourneyCalculator.dateKey(
                                                        selectedDay),
                                        level: dates[week * 7 + weekday] ==
                                                    null ||
                                                dates[week * 7 + weekday]!
                                                    .isAfter(
                                                  DateTime(today.year,
                                                      today.month, today.day),
                                                )
                                            ? 0
                                            : JourneyCalculator.activityLevel(
                                                dayFor(
                                                    dates[week * 7 + weekday]!),
                                              ),
                                        onTap: onDaySelected,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Less',
                  style: TextStyle(fontSize: 11, color: colors.inkSoft)),
              for (var level = 0; level <= 4; level++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: _activityColor(context, level),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text('$level',
                        style: TextStyle(fontSize: 10, color: colors.inkSoft)),
                  ],
                ),
              Text('More',
                  style: TextStyle(fontSize: 11, color: colors.inkSoft)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
              'Levels: 0 none, 1 under 5 min, 2 under 15 min, 3 under 30 min, 4 30+ min.',
              style: TextStyle(fontSize: 11, color: colors.inkSoft)),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.date,
    required this.today,
    required this.selected,
    required this.level,
    required this.onTap,
  });

  final DateTime? date;
  final DateTime today;
  final bool selected;
  final int level;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox(height: 24);
    final future = date!.isAfter(DateTime(today.year, today.month, today.day));
    final label = '${DateFormat('EEEE, MMMM d, y').format(date!)}: '
        '${future ? 'future date' : 'activity level $level'}';
    return SizedBox(
      width: 24,
      height: 24,
      child: Semantics(
        button: !future,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: future ? null : () => onTap(date!),
            customBorder: const CircleBorder(),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _activityColor(context, future ? 0 : level),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryGold(Theme.of(context).brightness)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _activityColor(BuildContext context, int level) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (level) {
    0 => dark ? const Color(0xFF292722) : const Color(0xFFEAE7DF),
    1 => const Color(0xFF86703F),
    2 => const Color(0xFF9C873F),
    3 => const Color(0xFFB79A43),
    _ => const Color(0xFFD0B65F),
  };
}

class _DayDetails extends StatelessWidget {
  const _DayDetails({
    required this.day,
    required this.selectedDate,
    required this.sessions,
    required this.notes,
    required this.highlights,
    required this.goalType,
    required this.goalTarget,
    required this.historicalGoalKnown,
    required this.onPrevious,
    required this.onNext,
  });

  final JourneyDay day;
  final DateTime selectedDate;
  final List<JourneySession> sessions;
  final List<String> notes;
  final List<String> highlights;
  final JourneyGoalType goalType;
  final int goalTarget;
  final bool historicalGoalKnown;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = goalType == JourneyGoalType.minutes
        ? day.totalMinutes
        : day.completedChapters;
    final today = DateTime.now();
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
    final goalMet = isToday && amount >= goalTarget;
    final dateLabel = DateFormat('EEEE, MMMM d, y').format(selectedDate);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(dateLabel,
                    style:
                        AppTheme.brandTitle(fontSize: 16, color: colors.ink)),
              ),
              IconButton(
                tooltip: 'Previous day',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Text(
            day.isActive
                ? '${day.totalMinutes} minutes • ${day.completedChapters} completed chapters'
                : 'No reading or listening recorded for this day.',
            style: TextStyle(color: colors.inkSoft),
          ),
          const SizedBox(height: 6),
          Text(
            'Reading ${day.readingSeconds ~/ 60} min · Listening ${day.listeningSeconds ~/ 60} min · ${isToday ? 'Today’s goal ${goalMet ? 'met' : '$amount of $goalTarget'}' : historicalGoalKnown ? 'Goal at the time: ${goalMet ? 'met' : 'not met'} ($amount of $goalTarget)' : 'Goal history unavailable for this date'}',
            style: TextStyle(color: colors.inkSoft, fontSize: 12),
          ),
          if (sessions.isNotEmpty) ...[
            const Divider(height: 24),
            for (final session in sessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                leading: Icon(
                  session.type == JourneySessionType.listening
                      ? Icons.headphones_rounded
                      : Icons.menu_book_rounded,
                  color: AppTheme.primaryGold(Theme.of(context).brightness),
                ),
                title: Text(
                  session.bookName == null || session.chapter == null
                      ? (session.type == JourneySessionType.listening
                          ? 'Listening session'
                          : 'Reading session')
                      : '${session.bookName} ${session.chapter}',
                ),
                subtitle: Text(
                  '${session.durationSeconds ~/ 60} min${session.completedChapters > 0 ? ' · ${session.completedChapters} chapter completed' : ''}${session.startVerse != null ? ' · verse ${session.startVerse}${session.endVerse == null || session.endVerse == session.startVerse ? '' : '-${session.endVerse}'}' : ''}',
                ),
              ),
          ],
          if (notes.isNotEmpty || highlights.isNotEmpty) ...[
            const Divider(height: 24),
            if (notes.isNotEmpty)
              Text('Notes saved: ${notes.join(', ')}',
                  style: TextStyle(color: colors.inkSoft)),
            if (highlights.isNotEmpty)
              Text('Verses highlighted: ${highlights.join(', ')}',
                  style: TextStyle(color: colors.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 36),
            const SizedBox(height: 12),
            const Text('Journey history could not be loaded.'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
}
