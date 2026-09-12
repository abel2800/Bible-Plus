import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/color_theme.dart';
import '../../providers/navigation_provider.dart';
import '../../services/audio_service.dart';
import '../../utils/app_theme.dart';

/// Atmospheric reader backdrop — gold glow or glass navy gradients.
class BpReaderBackground extends StatelessWidget {
  const BpReaderBackground(
      {super.key, required this.theme, required this.child});

  final ReaderColorTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (theme.isGlass) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1526), Color(0xFF050910)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.9),
                  radius: 1.2,
                  colors: [
                    theme.accentColor.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, 1.0),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF3C5AA0).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            child,
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.85),
          radius: 1.35,
          colors: [
            theme.accentColor.withValues(alpha: 0.13),
            theme.backgroundColor,
          ],
          stops: const [0.0, 0.58],
        ),
      ),
      child: child,
    );
  }
}

class BpReaderGlassPanel extends StatelessWidget {
  const BpReaderGlassPanel({
    super.key,
    required this.theme,
    required this.child,
    this.borderRadius = 20,
    this.padding,
  });

  final ReaderColorTheme theme;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final borderColor = theme.isGlass
        ? Colors.white.withValues(alpha: 0.14)
        : (theme.isDark ? AppTheme.borderDark : AppTheme.borderLight);

    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: theme.isGlass ? null : theme.surfaceColor,
        gradient: theme.isGlass
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.02),
                ],
              )
            : null,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isGlass ? 0.35 : 0.25),
            blurRadius: theme.isGlass ? 24 : 18,
            offset: const Offset(0, 8),
          ),
          if (theme.isGlass)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.06),
              blurRadius: 0,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
        ],
      ),
      child: child,
    );

    if (theme.isGlass) {
      panel = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: panel,
        ),
      );
    }

    return panel;
  }
}

BoxDecoration _readerCardDecoration(ReaderColorTheme theme) {
  final borderColor = theme.isGlass
      ? Colors.white.withValues(alpha: 0.14)
      : (theme.isDark ? AppTheme.borderDark : AppTheme.borderLight);
  return BoxDecoration(
    color: theme.isGlass
        ? theme.surfaceColor.withValues(alpha: 0.72)
        : theme.surfaceColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: theme.isDark ? 0.35 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

/// Top bar: translation pill · book title · settings (HTML v2 layout).
class BpReaderTopBar extends StatelessWidget {
  const BpReaderTopBar({
    super.key,
    required this.theme,
    required this.bookName,
    required this.chapter,
    required this.version,
    required this.onTitleTap,
    required this.onTranslationTap,
    required this.onSettingsTap,
  });

  final ReaderColorTheme theme;
  final String bookName;
  final int chapter;
  final String version;
  final VoidCallback onTitleTap;
  final VoidCallback onTranslationTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final card2 =
        theme.isDark ? const Color(0xFF1B1916) : const Color(0xFFF3F1EA);
    final borderFlat = theme.isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: _readerCardDecoration(theme),
      child: Row(
        children: [
          Material(
            color: card2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTranslationTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderFlat),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      version,
                      style: AppTheme.ui(
                        fontSize: 11.5,
                        weight: FontWeight.w700,
                        color: theme.headerColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: theme.verseNumberColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text.rich(
                  TextSpan(
                    style: AppTheme.ui(
                      fontSize: 13.5,
                      weight: FontWeight.w600,
                      color: theme.headerColor,
                    ),
                    children: [
                      TextSpan(text: bookName),
                      TextSpan(
                        text: ' $chapter',
                        style: TextStyle(
                          color: theme.verseNumberColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          _ReaderIconBtn(
            theme: theme,
            icon: Icons.tune_rounded,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

/// Focus toggle — stays visible in focus mode (separate from top bar).
class BpReaderFocusToggle extends StatelessWidget {
  const BpReaderFocusToggle({
    super.key,
    required this.theme,
    required this.active,
    required this.onChanged,
  });

  final ReaderColorTheme theme;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderFlat = theme.isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.08);
    final gold = theme.accentColor;

    return Material(
      color: theme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onChanged(!active),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 8, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderFlat),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: theme.isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                active ? 'Focus On' : 'Focus Off',
                style: AppTheme.ui(
                  fontSize: 11,
                  weight: FontWeight.w600,
                  color: active ? theme.headerColor : theme.verseNumberColor,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: active ? gold.withValues(alpha: 0.13) : borderFlat,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      active ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? gold : theme.verseNumberColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BpReaderChapterNav extends StatelessWidget {
  const BpReaderChapterNav({
    super.key,
    required this.theme,
    required this.onPrevious,
    required this.onNext,
    this.dimmed = false,
  });

  final ReaderColorTheme theme;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: dimmed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: dimmed ? 0 : 0.85,
        child: Row(
          children: [
            _ChapterNavBtn(
              theme: theme,
              icon: Icons.chevron_left_rounded,
              onTap: onPrevious,
            ),
            const Spacer(),
            _ChapterNavBtn(
              theme: theme,
              icon: Icons.chevron_right_rounded,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterNavBtn extends StatelessWidget {
  const _ChapterNavBtn({
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  final ReaderColorTheme theme;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderFlat = theme.isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: theme.surfaceColor,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderFlat),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: theme.isDark ? 0.35 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: theme.verseNumberColor),
        ),
      ),
    );
  }
}

class _ReaderIconBtn extends StatelessWidget {
  const _ReaderIconBtn({
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  final ReaderColorTheme theme;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 17,
            color: theme.headerColor,
          ),
        ),
      ),
    );
  }
}

/// Unified mini audio bar — used on the reading page and global shell.
class BpReaderAudioBar extends StatelessWidget {
  const BpReaderAudioBar({
    super.key,
    required this.theme,
    required this.title,
    required this.onTogglePlay,
    required this.onOpenPlayer,
  });

  final ReaderColorTheme theme;
  final String title;
  final VoidCallback onTogglePlay;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final gold = theme.accentColor;
    final goldBright =
        theme.isDark ? AppTheme.goldBright : AppTheme.goldBrightLight;
    final position = _formatDuration(audio.position);
    final duration = audio.duration > Duration.zero
        ? _formatDuration(audio.duration)
        : '--:--';

    return Material(
      color: theme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.isDark
              ? Colors.white.withValues(alpha: 0.09)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenPlayer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTogglePlay,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [goldBright, gold],
                      ),
                    ),
                    child: audio.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.onGold,
                            ),
                          )
                        : Icon(
                            audio.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppTheme.onGold,
                            size: 18,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.ui(
                        fontSize: 11.5,
                        weight: FontWeight.w600,
                        color: theme.headerColor,
                      ),
                    ),
                    Text(
                      '$position / $duration',
                      style: AppTheme.ui(
                        fontSize: 9.5,
                        color: theme.verseNumberColor,
                      ),
                    ),
                  ],
                ),
              ),
              BpReaderWaveformBars(
                theme: theme,
                playing: audio.isPlaying && !audio.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }
}

/// Animated mini waveform — pulses while audio is playing.
class BpReaderWaveformBars extends StatefulWidget {
  const BpReaderWaveformBars({
    super.key,
    required this.theme,
    required this.playing,
  });

  final ReaderColorTheme theme;
  final bool playing;

  @override
  State<BpReaderWaveformBars> createState() => _BpReaderWaveformBarsState();
}

class _BpReaderWaveformBarsState extends State<BpReaderWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant BpReaderWaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.playing) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = widget.theme.accentColor;
    final muted = widget.theme.verseNumberColor.withValues(alpha: 0.55);
    const baseHeights = [7.0, 12.0, 8.0, 14.0, 9.0];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: 16,
          child: Row(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 2,
                    height: widget.playing
                        ? baseHeights[i] +
                            (4 * _controller.value * (i.isOdd ? 1 : -1)).abs()
                        : baseHeights[i],
                    decoration: BoxDecoration(
                      color: i.isOdd ? gold.withValues(alpha: 0.85) : muted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class BpReaderChapterHeading extends StatelessWidget {
  const BpReaderChapterHeading({
    super.key,
    required this.chapter,
    required this.theme,
  });

  final int chapter;
  final ReaderColorTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$chapter',
          style: AppTheme.displayCap(
            fontSize: 62,
            color: theme.accentColor,
            height: 0.86,
          ),
        ),
      ),
    );
  }
}

class BpReaderThemeSwatches extends StatelessWidget {
  const BpReaderThemeSwatches({
    super.key,
    required this.themes,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ReaderColorTheme> themes;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final theme in themes)
          GestureDetector(
            onTap: () => onSelected(theme.id),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedId == theme.id
                      ? theme.accentColor
                      : Colors.white.withValues(alpha: 0.12),
                  width: selectedId == theme.id ? 2 : 1,
                ),
                gradient: theme.isGlass
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF132A47),
                          theme.backgroundColor,
                        ],
                      )
                    : null,
                color: theme.isGlass ? null : theme.backgroundColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Floating verse action popup — matches HTML `.verse-popup`.
class BpVersePopup extends StatelessWidget {
  const BpVersePopup({
    super.key,
    required this.theme,
    required this.selectedColor,
    required this.isBookmarked,
    required this.onHighlight,
    required this.onNote,
    required this.onBookmark,
    required this.onCopy,
    required this.onShare,
    required this.onClear,
  });

  final ReaderColorTheme theme;
  final Color? selectedColor;
  final bool isBookmarked;
  final ValueChanged<Color> onHighlight;
  final VoidCallback onNote;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final borderFlat = theme.isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: theme.surfaceColor,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 216,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderFlat),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in AppTheme.highlightColors)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => onHighlight(color),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor?.toARGB32() == color.toARGB32()
                                ? theme.headerColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: theme.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                _InlineToolBtn(
                  theme: theme,
                  icon: Icons.favorite_border_rounded,
                  label: 'Note',
                  onTap: onNote,
                ),
                _InlineToolBtn(
                  theme: theme,
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  label: 'Save',
                  active: isBookmarked,
                  onTap: onBookmark,
                ),
                _InlineToolBtn(
                  theme: theme,
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: onCopy,
                ),
                _InlineToolBtn(
                  theme: theme,
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: onShare,
                ),
                _InlineToolBtn(
                  theme: theme,
                  icon: Icons.close_rounded,
                  label: 'Clear',
                  onTap: onClear,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineToolBtn extends StatelessWidget {
  const _InlineToolBtn({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final ReaderColorTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? theme.accentColor : theme.verseNumberColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTheme.ui(
                fontSize: 8.5,
                weight: FontWeight.w600,
                color: active ? theme.accentColor : theme.verseNumberColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> shareChapterText({
  required BuildContext context,
  required String bookName,
  required int chapter,
  required String version,
  required List<String> verseLines,
}) async {
  final buffer = StringBuffer('$bookName $chapter ($version)\n\n');
  for (var i = 0; i < verseLines.length; i++) {
    buffer.writeln('${i + 1} ${verseLines[i]}');
  }
  buffer.write('\n— Bible Plus');
  try {
    await Share.share(buffer.toString());
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter copied to clipboard')),
      );
    }
  }
}

void openStudyTab(BuildContext context) {
  context.read<NavigationProvider>().setIndex(2);
}
