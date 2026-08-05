import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/app_theme.dart';
import 'gradient_library.dart';
import 'interactive_layer.dart';
import 'scenic_backgrounds.dart';
import 'studio_fonts.dart';
import 'verse_design.dart';
import 'verse_studio_controller.dart';

class StudioCanvas extends StatelessWidget {
  const StudioCanvas({
    super.key,
    required this.design,
    this.controller,
    this.editable = true,
    this.animateMotion = true,
    this.forExport = false,
    this.motionProgress,
  });

  final VerseDesign design;
  final VerseStudioController? controller;
  final bool editable;
  final bool animateMotion;
  final bool forExport;
  final double? motionProgress;

  @override
  Widget build(BuildContext context) {
    final gradient = StudioGradientLibrary.byId(design.gradientId).toGradient();

    return ClipRRect(
      borderRadius: BorderRadius.circular(forExport ? 0 : 16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          if (design.scenicPackId != 'none')
            CustomPaint(
              painter: ScenicBackgroundPainter(
                ScenicPackId.values.firstWhere(
                  (e) => e.name == design.scenicPackId,
                  orElse: () => ScenicPackId.none,
                ),
              ),
            ),
          if (design.photoPath != null && !kIsWeb) _PhotoLayer(design: design),
          _TextureOverlay(texture: design.texture),
          MotionOverlay(
            motion: design.motion,
            accent: design.accentColor,
            animate: animateMotion && !forExport,
            progress: motionProgress,
          ),
          if (design.decor != StudioDecorId.none)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 28, right: 24),
                child: InteractiveStudioLayer(
                  transform: design.decorTransform,
                  selected: editable &&
                      controller?.selectedLayer == StudioLayerId.decor,
                  onSelected: () =>
                      controller?.selectLayer(StudioLayerId.decor),
                  onChanged: (t) => controller?.updateLayerTransform(
                    StudioLayerId.decor,
                    t,
                  ),
                  child: _DecorGlyph(
                    decor: design.decor,
                    color: design.accentColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          Padding(
            padding: forExport
                ? const EdgeInsets.fromLTRB(48, 56, 48, 48)
                : const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: _LayoutBody(
              design: design,
              controller: controller,
              editable: editable,
              forExport: forExport,
            ),
          ),
          if (design.frame != StudioFrameId.none)
            IgnorePointer(child: _FrameOverlay(frame: design.frame)),
        ],
      ),
    );
  }
}

class _PhotoLayer extends StatelessWidget {
  const _PhotoLayer({required this.design});

  final VerseDesign design;

  @override
  Widget build(BuildContext context) {
    final path = design.photoPath;
    if (path == null) return const SizedBox.shrink();
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();

    Widget image = Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    if (design.photoBlur > 0.5) {
      image = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: design.photoBlur,
          sigmaY: design.photoBlur,
        ),
        child: image,
      );
    }

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(
        PhotoFilterMatrices.matrix(
          brightness: design.photoBrightness,
          contrast: design.photoContrast,
          saturation: design.photoSaturation,
          filter: design.photoFilter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          ColoredBox(
            color: Colors.black
                .withValues(alpha: design.photoDarken.clamp(0, 0.85)),
          ),
        ],
      ),
    );
  }
}

class _TextureOverlay extends StatelessWidget {
  const _TextureOverlay({required this.texture});

  final StudioTextureId texture;

  @override
  Widget build(BuildContext context) {
    switch (texture) {
      case StudioTextureId.none:
        return const SizedBox.shrink();
      case StudioTextureId.paper:
        return IgnorePointer(
          child: CustomPaint(painter: _NoisePainter(opacity: 0.08)),
        );
      case StudioTextureId.canvas:
        return IgnorePointer(
          child:
              CustomPaint(painter: _NoisePainter(opacity: 0.12, dense: true)),
        );
      case StudioTextureId.dust:
        return IgnorePointer(child: CustomPaint(painter: _DustPainter()));
      case StudioTextureId.light:
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      case StudioTextureId.vignette:
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.05,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
                stops: const [0.55, 1],
              ),
            ),
          ),
        );
      case StudioTextureId.snow:
        return IgnorePointer(
          child: CustomPaint(painter: _DustPainter(count: 40, radius: 2)),
        );
      case StudioTextureId.gold:
        return const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x33C08A28),
                  Colors.transparent,
                  Color(0x22E8C766),
                ],
              ),
            ),
          ),
        );
      case StudioTextureId.watercolor:
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.2),
                radius: 1.2,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({this.opacity = 0.1, this.dense = false});

  final double opacity;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final step = dense ? 4.0 : 7.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if (((x + y * 3).toInt() % 5) == 0) {
          canvas.drawCircle(Offset(x, y), dense ? 0.6 : 0.8, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.dense != dense;
}

class _DustPainter extends CustomPainter {
  _DustPainter({this.count = 6, this.radius = 1.6});

  final int count;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < count; i++) {
      final x = size.width * ((i * 0.17 + 0.1) % 1);
      final y = size.height * ((i * 0.23 + 0.12) % 1);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) =>
      oldDelegate.count != count;
}

class _FrameOverlay extends StatelessWidget {
  const _FrameOverlay({required this.frame});

  final StudioFrameId frame;

  @override
  Widget build(BuildContext context) {
    switch (frame) {
      case StudioFrameId.none:
        return const SizedBox.shrink();
      case StudioFrameId.thin:
        return Container(
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 1.4),
          ),
        );
      case StudioFrameId.doubleLine:
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54, width: 1),
          ),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 1.2),
            ),
          ),
        );
      case StudioFrameId.softGlow:
        return Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white38, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      case StudioFrameId.ornate:
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC08A28), width: 2.4),
          ),
          child: Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x88E8C766), width: 1),
            ),
          ),
        );
    }
  }
}

class _DecorGlyph extends StatelessWidget {
  const _DecorGlyph({required this.decor, required this.color});

  final StudioDecorId decor;
  final Color color;

  IconData get _icon {
    switch (decor) {
      case StudioDecorId.none:
        return Icons.circle;
      case StudioDecorId.cross:
        return Icons.add;
      case StudioDecorId.dove:
        return Icons.air;
      case StudioDecorId.olive:
        return Icons.eco_rounded;
      case StudioDecorId.star:
        return Icons.star_rounded;
      case StudioDecorId.rays:
        return Icons.wb_sunny_rounded;
      case StudioDecorId.sparkles:
        return Icons.auto_awesome;
      case StudioDecorId.heart:
        return Icons.favorite_rounded;
      case StudioDecorId.crown:
        return Icons.workspace_premium_rounded;
      case StudioDecorId.bible:
        return Icons.menu_book_rounded;
      case StudioDecorId.prayerHands:
        return Icons.volunteer_activism_rounded;
      case StudioDecorId.sun:
        return Icons.wb_sunny_outlined;
      case StudioDecorId.moon:
        return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: 56, color: color);
  }
}

class _LayoutBody extends StatelessWidget {
  const _LayoutBody({
    required this.design,
    this.controller,
    required this.editable,
    required this.forExport,
  });

  final VerseDesign design;
  final VerseStudioController? controller;
  final bool editable;
  final bool forExport;

  @override
  Widget build(BuildContext context) {
    Widget wrapLayer({
      required StudioLayerId id,
      required LayerTransform transform,
      required Widget child,
    }) {
      if (!editable || controller == null) {
        return Transform.translate(
          offset: Offset(transform.dx, transform.dy),
          child: Transform.rotate(
            angle: transform.rotation,
            child: Transform.scale(scale: transform.scale, child: child),
          ),
        );
      }
      return InteractiveStudioLayer(
        transform: transform,
        selected: controller!.selectedLayer == id,
        onSelected: () => controller!.selectLayer(id),
        onChanged: (t) => controller!.updateLayerTransform(id, t),
        child: child,
      );
    }

    final verse = wrapLayer(
      id: StudioLayerId.verse,
      transform: design.verseTransform,
      child: _VerseText(design: design, forExport: forExport),
    );
    final reference = wrapLayer(
      id: StudioLayerId.reference,
      transform: design.referenceTransform,
      child: _ReferenceText(design: design),
    );
    final logo = design.showLogo
        ? wrapLayer(
            id: StudioLayerId.logo,
            transform: design.logoTransform,
            child: Text(
              'BiblePulse',
              style: AppTheme.brandTitle(
                fontSize: 13,
                weight: FontWeight.w700,
                color: design.accentColor,
              ),
            ),
          )
        : const SizedBox.shrink();

    Widget content;
    switch (design.layout) {
      case StudioLayoutPreset.centered:
        content = Column(
          children: [
            const Spacer(flex: 2),
            Flexible(
              flex: 6,
              child: Align(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _maybeGlass(verse),
                ),
              ),
            ),
            const SizedBox(height: 8),
            reference,
            const Spacer(flex: 3),
            logo,
          ],
        );
      case StudioLayoutPreset.magazine:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            reference,
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: _maybeGlass(verse),
                ),
              ),
            ),
            logo,
          ],
        );
      case StudioLayoutPreset.instagram:
        content = Column(
          children: [
            const Spacer(),
            _Rule(color: design.accentColor),
            const SizedBox(height: 8),
            Flexible(
              flex: 5,
              child: Align(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _maybeGlass(verse),
                ),
              ),
            ),
            const SizedBox(height: 8),
            reference,
            const SizedBox(height: 8),
            _Rule(color: design.accentColor),
            const Spacer(),
            logo,
          ],
        );
      case StudioLayoutPreset.minimal:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            reference,
            const SizedBox(height: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: _maybeGlass(verse),
              ),
            ),
            Align(alignment: Alignment.bottomRight, child: logo),
          ],
        );
      case StudioLayoutPreset.pinterest:
        content = Column(
          children: [
            const Spacer(flex: 1),
            Expanded(
              flex: 4,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _maybeGlass(verse),
                ),
              ),
            ),
            reference,
            const SizedBox(height: 8),
            logo,
          ],
        );
    }

    return ClipRect(child: content);
  }

  Widget _maybeGlass(Widget child) {
    if (!design.glassEnabled) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
      width: 72,
      color: color.withValues(alpha: 0.75),
    );
  }
}

class _VerseText extends StatelessWidget {
  const _VerseText({required this.design, required this.forExport});

  final VerseDesign design;
  final bool forExport;

  @override
  Widget build(BuildContext context) {
    final baseColor = StudioTextEffects.colorFor(
      design.effect,
      design.textColor,
      design.accentColor,
    );
    final shadows = StudioTextEffects.shadowsFor(
      design.effect,
      design.accentColor,
    );
    final display = SmartVerseFormatter.format(
      design.verseText,
      enabled: design.smartBreaks,
    );
    final style = StudioFonts.styleFor(
      design.fontId,
      fontSize: design.layout == StudioLayoutPreset.magazine
          ? design.fontSize * 1.15
          : design.fontSize,
      color: baseColor,
      height: design.lineHeight,
      letterSpacing: design.letterSpacing,
      weight: design.layout == StudioLayoutPreset.magazine
          ? FontWeight.w700
          : FontWeight.w500,
    ).copyWith(shadows: shadows);

    Widget textWidget;
    if (design.textPath != StudioTextPath.straight) {
      textWidget = CurvedVerseText(
        text: display.isEmpty ? 'Enter a verse…' : display,
        style: style,
        path: design.textPath,
      );
    } else if (design.highlights.isNotEmpty) {
      final words = SmartVerseFormatter.words(design.verseText);
      final highlightMap = {
        for (final h in design.highlights) h.wordIndex: h.color,
      };
      textWidget = Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < words.length; i++) ...[
              TextSpan(
                text: words[i],
                style: style.copyWith(color: highlightMap[i] ?? baseColor),
              ),
              if (i < words.length - 1) const TextSpan(text: ' '),
            ],
          ],
        ),
        textAlign: design.textAlign,
      );
    } else if (design.layout == StudioLayoutPreset.magazine &&
        display.isNotEmpty) {
      final lines = display.split('\n');
      final first = lines.first.toUpperCase();
      final rest = lines.skip(1).join('\n');
      textWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(first, textAlign: design.textAlign, style: style),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rest,
              textAlign: design.textAlign,
              style: style.copyWith(
                fontSize: design.fontSize * 0.85,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      );
    } else {
      textWidget = Text(
        display.isEmpty ? 'Enter a verse…' : display,
        textAlign: design.textAlign,
        style: style.copyWith(
          color:
              display.isEmpty ? baseColor.withValues(alpha: 0.45) : baseColor,
        ),
      );
    }

    if (design.effect == StudioTextEffect.gradientFill) {
      textWidget = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [design.accentColor, Colors.white, design.accentColor],
        ).createShader(bounds),
        child: textWidget,
      );
    }

    if (!forExport && design.quoteAnimation && display.isNotEmpty) {
      textWidget = textWidget
          .animate(key: ValueKey(display))
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOut);
    }

    return textWidget;
  }
}

class _ReferenceText extends StatelessWidget {
  const _ReferenceText({required this.design});

  final VerseDesign design;

  @override
  Widget build(BuildContext context) {
    if (design.reference.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      design.reference.toUpperCase(),
      textAlign: design.layout == StudioLayoutPreset.minimal ||
              design.layout == StudioLayoutPreset.magazine
          ? TextAlign.left
          : TextAlign.center,
      style: AppTheme.ui(
        fontSize: design.fontSize * 0.42,
        weight: FontWeight.w700,
        letterSpacing: 1.1,
        color: design.accentColor,
      ),
    );
  }
}
