import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../utils/app_theme.dart';

class AudioSleepTimerSheet extends StatelessWidget {
  const AudioSleepTimerSheet({super.key});

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
                  'Sleep timer',
                  style: AppTheme.brandTitle(fontSize: 20, color: ink),
                ),
                const SizedBox(height: 4),
                Text(
                  audio.sleepMode == AudioSleepMode.duration &&
                          audio.sleepUntil != null
                      ? 'Stops at ${TimeOfDay.fromDateTime(audio.sleepUntil!).format(context)}'
                      : 'Choose when playback should stop.',
                  style: AppTheme.ui(fontSize: 13, color: soft),
                ),
                const SizedBox(height: 12),
                for (final option in const [
                  (label: '5 minutes', duration: Duration(minutes: 5)),
                  (label: '10 minutes', duration: Duration(minutes: 10)),
                  (label: '15 minutes', duration: Duration(minutes: 15)),
                  (label: '30 minutes', duration: Duration(minutes: 30)),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label, style: AppTheme.ui(color: ink)),
                    onTap: () {
                      context
                          .read<AudioService>()
                          .startSleepTimer(option.duration);
                      Navigator.pop(context);
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('End of chapter', style: AppTheme.ui(color: ink)),
                  onTap: () {
                    context.read<AudioService>().stopAtEndOfChapter();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('End of queue', style: AppTheme.ui(color: ink)),
                  onTap: () {
                    context.read<AudioService>().stopAtEndOfBook();
                    Navigator.pop(context);
                  },
                ),
                if (audio.hasSleepTimer)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<AudioService>().clearSleepTimer();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear timer'),
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
