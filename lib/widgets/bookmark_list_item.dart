import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bookmark.dart';
import '../providers/study_provider.dart';
import '../utils/app_theme.dart';
import 'design/bp_widgets.dart';

class BookmarkListItem extends StatelessWidget {
  final Bookmark bookmark;

  const BookmarkListItem({
    super.key,
    required this.bookmark,
  });

  @override
  Widget build(BuildContext context) {
    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final inkSoft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    return BpCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: AppTheme.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bookmark.verseReference,
                  style: AppTheme.brandTitle(
                    fontSize: 15,
                    weight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              BpIconButton(
                icon: Icons.bookmark_remove_rounded,
                tooltip: 'Remove bookmark',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Remove Bookmark',
                        style: AppTheme.brandTitle(fontSize: 17),
                      ),
                      content: const Text(
                        'Are you sure you want to remove this bookmark?',
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
                    await studyProvider.removeBookmark(
                      bookmark.verseReference,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bookmark.text,
            style: AppTheme.scripture(
              fontSize: 15,
              height: 1.65,
              color: inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
