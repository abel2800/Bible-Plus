import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/highlight.dart';
import '../providers/study_provider.dart';
import '../utils/app_theme.dart';
import 'design/bp_widgets.dart';

class HighlightListItem extends StatelessWidget {
  final Highlight highlight;

  const HighlightListItem({
    super.key,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final highlightColor = Color(highlight.color);

    return BpCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: highlightColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: highlightColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  highlight.verseReference,
                  style: AppTheme.brandTitle(
                    fontSize: 15,
                    weight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              BpIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Remove highlight',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Remove Highlight',
                        style: AppTheme.brandTitle(fontSize: 17),
                      ),
                      content: const Text(
                        'Are you sure you want to remove this highlight?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Remove',
                            style: TextStyle(color: AppTheme.vermilion),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await studyProvider.removeHighlight(
                      highlight.verseReference,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: highlightColor.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              highlight.text,
              style: AppTheme.scripture(
                fontSize: 15,
                height: 1.65,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
