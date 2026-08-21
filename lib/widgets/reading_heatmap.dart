import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// GitHub-style contribution heatmap of reading days. Works on every
/// platform (web, desktop, mobile) because it is pure Flutter UI.
class ReadingHeatmap extends StatelessWidget {
  const ReadingHeatmap({
    super.key,
    required this.readingDays,
    this.weeksToShow = 14,
    this.squareSize = 12,
    this.gap = 4,
  });

  final Set<String> readingDays;
  final int weeksToShow;
  final double squareSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final endOfWeek = todayOnly.add(Duration(days: 6 - todayOnly.weekday % 7));
    final totalDays = weeksToShow * 7;
    final start = endOfWeek.subtract(Duration(days: totalDays - 1));

    final cells = <_HeatCell>[];
    for (var i = 0; i < totalDays; i++) {
      final date = start.add(Duration(days: i));
      final isFuture = date.isAfter(todayOnly);
      final key = _key(date);
      cells.add(
        _HeatCell(
          date: date,
          read: !isFuture && readingDays.contains(key),
          isFuture: isFuture,
        ),
      );
    }

    final columns = List.generate(weeksToShow, (week) {
      return List.generate(7, (day) => cells[week * 7 + day]);
    });

    final emptyColor =
        isDark ? const Color(0xFF2B3553) : const Color(0xFFE8DEC1);
    final activeColor =
        isDark ? const Color(0xFFD9A64B) : const Color(0xFFB5862F);
    final softActiveColor =
        isDark ? const Color(0xFF8F6B2A) : const Color(0xFFD4AF6A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading rhythm',
          style: AppTheme.ui(
            fontSize: 13,
            weight: FontWeight.w700,
            color: t.ink,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final column in columns)
                    Padding(
                      padding: EdgeInsets.only(right: gap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final cell in column)
                            Padding(
                              padding: EdgeInsets.only(bottom: gap),
                              child: Tooltip(
                                message: cell.isFuture
                                    ? ''
                                    : '${_label(cell.date)} · ${cell.read ? 'Read' : 'No reading'}',
                                child: Container(
                                  width: squareSize,
                                  height: squareSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: cell.isFuture
                                        ? Colors.transparent
                                        : cell.read
                                            ? activeColor
                                            : emptyColor,
                                    boxShadow: cell.read
                                        ? [
                                            BoxShadow(
                                              color: activeColor.withValues(
                                                  alpha: 0.4),
                                              blurRadius: 4,
                                              spreadRadius: 0.6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Less',
              style: AppTheme.ui(fontSize: 10, color: t.inkFaint),
            ),
            const SizedBox(width: 6),
            _swatch(emptyColor),
            const SizedBox(width: 3),
            _swatch(softActiveColor),
            const SizedBox(width: 3),
            _swatch(activeColor),
            const SizedBox(width: 6),
            Text(
              'More',
              style: AppTheme.ui(fontSize: 10, color: t.inkFaint),
            ),
          ],
        ),
      ],
    );
  }

  Widget _swatch(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  String _key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _label(DateTime d) => '${_month(d.month)} ${d.day}';

  String _month(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];
}

class _HeatCell {
  const _HeatCell({
    required this.date,
    required this.read,
    required this.isFuture,
  });

  final DateTime date;
  final bool read;
  final bool isFuture;
}
