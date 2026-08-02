import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../utils/app_theme.dart';

class AudioQueueSheet extends StatelessWidget {
  const AudioQueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final bg = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Material(
      color: bg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Queue',
                  style: AppTheme.brandTitle(fontSize: 20, color: ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a chapter to jump. Drag to reorder.',
                  style: AppTheme.ui(fontSize: 13, color: soft),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: audio.queue.length,
                    onReorderItem: (oldIndex, newIndex) {
                      context
                          .read<AudioService>()
                          .reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = audio.queue[index];
                      final active = index == audio.queueIndex;
                      return Material(
                        key: ValueKey(
                          '${item.bookId}-${item.chapter}-${item.versionId}',
                        ),
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: active
                                ? AppTheme.gold.withValues(alpha: 0.18)
                                : (isDark
                                    ? AppTheme.surface2Dark
                                    : AppTheme.surface2Light),
                            child: Text(
                              '${index + 1}',
                              style: AppTheme.ui(
                                fontSize: 12,
                                weight: FontWeight.w700,
                                color: active ? AppTheme.gold : ink,
                              ),
                            ),
                          ),
                          title:
                              Text(item.title, style: AppTheme.ui(color: ink)),
                          subtitle: Text(
                            item.versionId,
                            style: AppTheme.ui(fontSize: 12, color: soft),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: audio.queue.length <= 1
                                ? null
                                : () => context
                                    .read<AudioService>()
                                    .removeQueueItem(index),
                          ),
                          onTap: () async {
                            await context
                                .read<AudioService>()
                                .playQueueItem(index);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    },
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
