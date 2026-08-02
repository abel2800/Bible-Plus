import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/audio_download_provider.dart';
import '../services/audio_service.dart';
import '../services/audio_share_link.dart';
import '../utils/app_theme.dart';
import '../widgets/audio_queue_sheet.dart';
import '../widgets/audio_sleep_timer_sheet.dart';
import '../widgets/book_selector_bottom_sheet.dart';

class AudioNowPlayingScreen extends StatelessWidget {
  const AudioNowPlayingScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AudioNowPlayingScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final downloads = context.watch<AudioDownloadProvider>();
    final theme = audio.artworkTheme;
    final palette = theme?.palette ??
        const [Color(0xFF1F3A5F), Color(0xFF466C96), Color(0xFFE0B766)];
    final title = audio.activeTitle;
    final subtitle =
        audio.activeSubtitle.isEmpty ? 'Bible audio' : audio.activeSubtitle;
    final item = audio.currentQueueItem;
    final cacheKey = item == null
        ? null
        : '${item.versionId}/${item.bookId}/${item.chapter}';

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.first,
              palette.length > 1 ? palette[1] : palette.first,
              const Color(0xFF0B1020),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              return Padding(
                padding: EdgeInsets.fromLTRB(20, compact ? 4 : 12, 20, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Now Playing',
                                style: AppTheme.ui(
                                  fontSize: 12,
                                  weight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.ui(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Browse books & chapters',
                          onPressed: () => _openChapterPicker(context),
                          icon: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Queue',
                          onPressed: () => _openQueue(context),
                          icon: const Icon(
                            Icons.queue_music_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 8 : 16),
                    Flexible(
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                            maxHeight:
                                constraints.maxHeight * (compact ? 0.38 : 0.44),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _ArtworkCard(
                              palette: palette,
                              icon: theme?.icon ?? Icons.auto_stories_rounded,
                              compact: compact,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => _openChapterPicker(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.brandTitle(
                                    fontSize: compact ? 24 : 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.expand_more_rounded,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.ui(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 14),
                    _ProgressSection(audio: audio),
                    SizedBox(height: compact ? 8 : 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TransportButton(
                          icon: Icons.skip_previous_rounded,
                          onTap: audio.hasPreviousQueueItem ||
                                  audio.position > const Duration(seconds: 5)
                              ? () => _skip(context, previous: true)
                              : null,
                        ),
                        _PlayButton(audio: audio, compact: compact),
                        _TransportButton(
                          icon: Icons.skip_next_rounded,
                          onTap: () => _skip(context, previous: false),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 14 : 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ToolButton(
                          icon: Icons.speed_rounded,
                          label:
                              '${audio.speed.toStringAsFixed(audio.speed % 1 == 0 ? 0 : 2)}x',
                          onTap: () => audio.cycleSpeed(),
                        ),
                        _ToolButton(
                          icon: Icons.bedtime_rounded,
                          label: audio.hasSleepTimer ? 'Timer' : 'Sleep',
                          active: audio.hasSleepTimer,
                          onTap: () => _openSleepTimer(context),
                        ),
                        _DownloadToolButton(
                          cacheKey: cacheKey,
                          downloading: downloads.downloading,
                          onTap: () => _downloadCurrent(context),
                        ),
                        _ToolButton(
                          icon: Icons.ios_share_rounded,
                          label: 'Share',
                          onTap: () => _shareCurrent(context),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _skip(BuildContext context, {required bool previous}) async {
    final audio = context.read<AudioService>();
    if (previous) {
      await audio.playPreviousInQueue();
    } else {
      await audio.playNextInQueue();
    }
  }

  void _openChapterPicker(BuildContext context) {
    showBookSelector(context, forcePlayAudio: true);
  }

  void _openQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AudioQueueSheet(),
    );
  }

  void _openSleepTimer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AudioSleepTimerSheet(),
    );
  }

  Future<void> _downloadCurrent(BuildContext context) async {
    final downloads = context.read<AudioDownloadProvider>();
    final audio = context.read<AudioService>();
    final item = audio.currentQueueItem;
    if (item == null) return;
    final cacheKey = '${item.versionId}/${item.bookId}/${item.chapter}';
    if (await audio.cache.has(cacheKey)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already saved for offline listening.')),
      );
      return;
    }
    await downloads.downloadChapters(
      versionId: item.versionId,
      chapters: [(bookId: item.bookId, chapter: item.chapter)],
    );
    if (!context.mounted) return;
    if (downloads.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(downloads.error!)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved for offline listening.')),
    );
  }

  Future<void> _shareCurrent(BuildContext context) async {
    final audio = context.read<AudioService>();
    final item = audio.currentQueueItem;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing is playing to share yet.')),
      );
      return;
    }

    final message = AudioShareLink.shareMessage(item);
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    try {
      await Share.share(
        message,
        subject: 'Listen to ${item.title} on BiblePulse',
        sharePositionOrigin: origin,
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: message));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied — sharing isn’t available here'),
        ),
      );
    }
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.palette,
    required this.icon,
    this.compact = false,
  });

  final List<Color> palette;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.25),
          radius: 1.15,
          colors: [
            palette.length > 2 ? palette[2] : Colors.white24,
            palette.length > 1 ? palette[1] : palette.first,
            palette.first,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: compact ? 84 : 120,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _ProgressSection extends StatefulWidget {
  const _ProgressSection({required this.audio});

  final AudioService audio;

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final audio = widget.audio;
    final duration = audio.duration;
    final max =
        duration.inMilliseconds <= 0 ? 1.0 : duration.inMilliseconds.toDouble();
    final value = (_dragValue ?? audio.position.inMilliseconds.toDouble())
        .clamp(0.0, max);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white12,
          ),
          child: Slider(
            value: value,
            max: max,
            onChangeStart: (v) => setState(() => _dragValue = v),
            onChanged: (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) async {
              await audio.seek(Duration(milliseconds: v.round()));
              if (mounted) {
                setState(() => _dragValue = null);
              }
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(Duration(milliseconds: value.round())),
              style: AppTheme.ui(fontSize: 12, color: Colors.white70),
            ),
            Text(
              _format(duration),
              style: AppTheme.ui(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  static String _format(Duration value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(value.inMinutes.remainder(60));
    final seconds = two(value.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.audio, this.compact = false});

  final AudioService audio;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 72.0 : 86.0;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: audio.isLoading
            ? null
            : () {
                if (audio.isPlaying) {
                  audio.pause();
                } else {
                  audio.play();
                }
              },
        child: SizedBox(
          width: size,
          height: size,
          child: audio.isLoading
              ? Padding(
                  padding: EdgeInsets.all(size * 0.3),
                  child: const CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(
                  audio.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: size * 0.48,
                  color: Colors.black87,
                ),
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({required this.icon, this.onTap});

  final IconData icon;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap == null ? null : () => onTap!.call(),
      iconSize: 36,
      color: Colors.white,
      disabledColor: Colors.white30,
      icon: Icon(icon),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.gold : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.ui(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadToolButton extends StatelessWidget {
  const _DownloadToolButton({
    required this.cacheKey,
    required this.downloading,
    required this.onTap,
  });

  final String? cacheKey;
  final bool downloading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: cacheKey == null
          ? Future.value(false)
          : context.read<AudioService>().cache.has(cacheKey!),
      builder: (context, snapshot) {
        final saved = snapshot.data == true;
        return _ToolButton(
          icon: downloading
              ? Icons.downloading_rounded
              : (saved ? Icons.download_done_rounded : Icons.download_rounded),
          label: saved ? 'Saved' : 'Download',
          active: saved,
          onTap: downloading ? () {} : onTap,
        );
      },
    );
  }
}
