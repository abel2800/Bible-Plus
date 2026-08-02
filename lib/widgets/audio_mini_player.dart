import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/audio_now_playing_screen.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';

class AudioMiniPlayer extends StatelessWidget {
  const AudioMiniPlayer({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    if (!audio.showMiniPlayer) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = audio.artworkTheme;
    final accent = theme?.accentColor ?? AppTheme.gold;
    final progressMax = audio.duration.inMilliseconds <= 0
        ? 1.0
        : audio.duration.inMilliseconds.toDouble();
    final progress = (audio.position.inMilliseconds.toDouble() / progressMax)
        .clamp(0.0, 1.0);

    return Padding(
      padding: margin ?? const EdgeInsets.all(12),
      child: Material(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => AudioNowPlayingScreen.open(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
              boxShadow: AppTheme.cardShadow(isDark),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: theme?.palette ??
                              const [Color(0xFF1F3A5F), Color(0xFF466C96)],
                        ),
                      ),
                      child: Icon(
                        theme?.icon ?? Icons.auto_stories_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audio.activeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.ui(
                              fontSize: 14,
                              weight: FontWeight.w700,
                              color: isDark ? AppTheme.inkDark : AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            audio.activeSubtitle.isEmpty
                                ? 'Tap for player'
                                : audio.activeSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.ui(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.inkSoftDark
                                  : AppTheme.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: audio.hasPreviousQueueItem ||
                              audio.position > const Duration(seconds: 5)
                          ? () => audio.playPreviousInQueue()
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    IconButton(
                      onPressed: audio.isLoading
                          ? null
                          : () {
                              if (audio.isPlaying) {
                                audio.pause();
                              } else {
                                audio.play();
                              }
                            },
                      icon: audio.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              audio.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                    ),
                    IconButton(
                      onPressed: () => audio.playNextInQueue(),
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: accent.withValues(alpha: 0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
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
