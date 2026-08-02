import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'verse_design.dart';

/// Pan + pinch-to-scale + two-finger rotate for studio layers.
class InteractiveStudioLayer extends StatefulWidget {
  const InteractiveStudioLayer({
    super.key,
    required this.transform,
    required this.selected,
    required this.onSelected,
    required this.onChanged,
    required this.child,
  });

  final LayerTransform transform;
  final bool selected;
  final VoidCallback onSelected;
  final ValueChanged<LayerTransform> onChanged;
  final Widget child;

  @override
  State<InteractiveStudioLayer> createState() => _InteractiveStudioLayerState();
}

class _InteractiveStudioLayerState extends State<InteractiveStudioLayer> {
  LayerTransform? _base;
  double _panDx = 0;
  double _panDy = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onSelected,
      onScaleStart: (_) {
        widget.onSelected();
        _base = widget.transform;
        _panDx = 0;
        _panDy = 0;
      },
      onScaleUpdate: (details) {
        final base = _base ?? widget.transform;
        _panDx += details.focalPointDelta.dx;
        _panDy += details.focalPointDelta.dy;
        widget.onChanged(
          base.copyWith(
            dx: base.dx + _panDx,
            dy: base.dy + _panDy,
            scale: (base.scale * details.scale).clamp(0.55, 2.8),
            rotation: base.rotation + details.rotation,
          ),
        );
      },
      onScaleEnd: (_) {
        _base = null;
        _panDx = 0;
        _panDy = 0;
      },
      child: Transform.translate(
        offset: Offset(widget.transform.dx, widget.transform.dy),
        child: Transform.rotate(
          angle: widget.transform.rotation,
          child: Transform.scale(
            scale: widget.transform.scale,
            child: DecoratedBox(
              decoration: widget.selected
                  ? BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : const BoxDecoration(),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class MotionOverlay extends StatefulWidget {
  const MotionOverlay({
    super.key,
    required this.motion,
    required this.accent,
    this.animate = true,
    this.progress,
  });

  final StudioMotionId motion;
  final Color accent;
  final bool animate;
  final double? progress;

  @override
  State<MotionOverlay> createState() => _MotionOverlayState();
}

class _MotionOverlayState extends State<MotionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.animate && widget.motion != StudioMotionId.none) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MotionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && widget.motion != StudioMotionId.none) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.motion == StudioMotionId.none) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _MotionPainter(
            motion: widget.motion,
            accent: widget.accent,
            t: widget.progress ?? (widget.animate ? _controller.value : 0.35),
          ),
        ),
      ),
    );
  }
}

class _MotionPainter extends CustomPainter {
  _MotionPainter({
    required this.motion,
    required this.accent,
    required this.t,
  });

  final StudioMotionId motion;
  final Color accent;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rnd = math.Random(42);

    switch (motion) {
      case StudioMotionId.none:
        return;
      case StudioMotionId.sparkles:
        paint.color = accent.withValues(alpha: 0.55);
        for (var i = 0; i < 18; i++) {
          final x = rnd.nextDouble() * size.width;
          final y = (rnd.nextDouble() * size.height + t * size.height * 0.2) %
              size.height;
          final r = 1.2 + (math.sin((t + i) * math.pi * 2) + 1) * 1.2;
          canvas.drawCircle(Offset(x, y), r, paint);
        }
      case StudioMotionId.floatingDust:
        paint.color = Colors.white.withValues(alpha: 0.25);
        for (var i = 0; i < 30; i++) {
          final x = (rnd.nextDouble() * size.width + t * 40) % size.width;
          final y = (rnd.nextDouble() * size.height - t * 60) % size.height;
          canvas.drawCircle(Offset(x, y.abs()), 1.1, paint);
        }
      case StudioMotionId.snow:
        paint.color = Colors.white.withValues(alpha: 0.7);
        for (var i = 0; i < 40; i++) {
          final x = (rnd.nextDouble() * size.width +
                  math.sin(t * math.pi * 2 + i) * 12) %
              size.width;
          final y =
              (rnd.nextDouble() * size.height + t * size.height) % size.height;
          canvas.drawCircle(Offset(x, y), 1.8, paint);
        }
      case StudioMotionId.lightRays:
        final ray = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size);
        for (var i = 0; i < 6; i++) {
          final angle = -0.4 + i * 0.18 + math.sin(t * math.pi * 2) * 0.03;
          canvas.save();
          canvas.translate(size.width * 0.5, -20);
          canvas.rotate(angle);
          canvas.drawRect(
            Rect.fromLTWH(-18, 0, 36, size.height * 1.2),
            ray,
          );
          canvas.restore();
        }
      case StudioMotionId.rain:
        paint
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < 50; i++) {
          final x = rnd.nextDouble() * size.width;
          final y = (rnd.nextDouble() * size.height + t * size.height * 1.4) %
              size.height;
          canvas.drawLine(Offset(x, y), Offset(x - 2, y + 14), paint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _MotionPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.motion != motion ||
      oldDelegate.accent != accent;
}

/// Draws text along an arc or gentle wave.
class CurvedVerseText extends StatelessWidget {
  const CurvedVerseText({
    super.key,
    required this.text,
    required this.style,
    required this.path,
  });

  final String text;
  final TextStyle style;
  final StudioTextPath path;

  @override
  Widget build(BuildContext context) {
    if (path == StudioTextPath.straight) {
      return Text(text, textAlign: TextAlign.center, style: style);
    }
    return SizedBox(
      height: (style.fontSize ?? 24) * 3.2,
      width: double.infinity,
      child: CustomPaint(
        painter: _CurvedTextPainter(text: text, style: style, path: path),
      ),
    );
  }
}

class _CurvedTextPainter extends CustomPainter {
  _CurvedTextPainter({
    required this.text,
    required this.style,
    required this.path,
  });

  final String text;
  final TextStyle style;
  final StudioTextPath path;

  @override
  void paint(Canvas canvas, Size size) {
    final clean = text.replaceAll('\n', ' ');
    if (clean.isEmpty) return;
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    if (path == StudioTextPath.wave) {
      final chars = clean.split('');
      var x = 12.0;
      for (var i = 0; i < chars.length; i++) {
        tp.text = TextSpan(text: chars[i], style: style);
        tp.layout();
        final y = size.height * 0.45 + math.sin(i * 0.45) * 10;
        tp.paint(canvas, Offset(x, y));
        x += tp.width;
        if (x > size.width - 12) break;
      }
      return;
    }

    final radius = size.width * 0.55;
    final center = Offset(size.width / 2, size.height * 0.95);
    final chars = clean.split('');
    final total = chars.length;
    final sweep = math.pi * 0.7;
    final start = -math.pi / 2 - sweep / 2;

    for (var i = 0; i < total; i++) {
      final angle = start + sweep * (i / math.max(1, total - 1));
      tp.text = TextSpan(text: chars[i], style: style);
      tp.layout();
      final pos = Offset(
        center.dx + radius * math.cos(angle) - tp.width / 2,
        center.dy + radius * math.sin(angle) - tp.height / 2,
      );
      canvas.save();
      canvas.translate(pos.dx + tp.width / 2, pos.dy + tp.height / 2);
      canvas.rotate(angle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedTextPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.path != path ||
      oldDelegate.style != style;
}
