import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Original procedural scenic backgrounds — no third-party photo licenses.
enum ScenicPackId {
  none,
  natureDawn,
  oceanHorizon,
  mountainMist,
  softSky,
  galaxyNight,
  greeneryHills,
  flowerMeadow,
  desertDusk,
  lakeStill,
  auroraVeil,
}

class ScenicPack {
  const ScenicPack({
    required this.id,
    required this.name,
    required this.category,
  });

  final ScenicPackId id;
  final String name;
  final String category;
}

class ScenicPackLibrary {
  ScenicPackLibrary._();

  static const packs = <ScenicPack>[
    ScenicPack(
        id: ScenicPackId.natureDawn, name: 'Nature Dawn', category: 'Nature'),
    ScenicPack(
        id: ScenicPackId.oceanHorizon,
        name: 'Ocean Horizon',
        category: 'Ocean'),
    ScenicPack(
        id: ScenicPackId.mountainMist,
        name: 'Mountain Mist',
        category: 'Mountains'),
    ScenicPack(id: ScenicPackId.softSky, name: 'Soft Sky', category: 'Sky'),
    ScenicPack(
        id: ScenicPackId.galaxyNight, name: 'Galaxy Night', category: 'Galaxy'),
    ScenicPack(
        id: ScenicPackId.greeneryHills, name: 'Greenery', category: 'Greenery'),
    ScenicPack(
        id: ScenicPackId.flowerMeadow,
        name: 'Flower Meadow',
        category: 'Flowers'),
    ScenicPack(
        id: ScenicPackId.desertDusk, name: 'Desert Dusk', category: 'Nature'),
    ScenicPack(
        id: ScenicPackId.lakeStill, name: 'Still Lake', category: 'Ocean'),
    ScenicPack(
        id: ScenicPackId.auroraVeil, name: 'Aurora Veil', category: 'Galaxy'),
  ];

  static List<String> get categories =>
      packs.map((p) => p.category).toSet().toList()..sort();
}

class ScenicBackgroundPainter extends CustomPainter {
  ScenicBackgroundPainter(this.id);

  final ScenicPackId id;

  @override
  void paint(Canvas canvas, Size size) {
    switch (id) {
      case ScenicPackId.none:
        return;
      case ScenicPackId.natureDawn:
        _sky(canvas, size,
            const [Color(0xFFFFB347), Color(0xFFFF7E5F), Color(0xFF2C1654)]);
        _hills(
            canvas, size, const [Color(0xFF2E5A3C), Color(0xFF1A3A28)], 0.55);
        _sun(
            canvas, size, const Offset(0.7, 0.28), 36, const Color(0xFFFFE08A));
      case ScenicPackId.oceanHorizon:
        _sky(canvas, size,
            const [Color(0xFF87CEEB), Color(0xFF4A90A4), Color(0xFF0A2E36)]);
        _waves(canvas, size, const Color(0xFF148C9C));
      case ScenicPackId.mountainMist:
        _sky(canvas, size,
            const [Color(0xFFB8C6DB), Color(0xFF5D6D7E), Color(0xFF2C3E50)]);
        _mountains(canvas, size);
      case ScenicPackId.softSky:
        _sky(canvas, size,
            const [Color(0xFFE8F4F8), Color(0xFF87CEEB), Color(0xFFF6F0E1)]);
        _clouds(canvas, size);
      case ScenicPackId.galaxyNight:
        _sky(canvas, size,
            const [Color(0xFF0B0B2B), Color(0xFF2E1A47), Color(0xFF10182A)]);
        _stars(canvas, size);
      case ScenicPackId.greeneryHills:
        _sky(canvas, size,
            const [Color(0xFFDCEAB8), Color(0xFF8FBC8F), Color(0xFF1A2F1C)]);
        _hills(canvas, size, const [Color(0xFF3D5A3E), Color(0xFF6E8B3D)], 0.5);
      case ScenicPackId.flowerMeadow:
        _sky(canvas, size,
            const [Color(0xFFF6E8E8), Color(0xFFE8A0BF), Color(0xFF5C2A3A)]);
        _hills(
            canvas, size, const [Color(0xFF6B8F71), Color(0xFF4A7C59)], 0.62);
        _flowers(canvas, size);
      case ScenicPackId.desertDusk:
        _sky(canvas, size,
            const [Color(0xFFFF8A5B), Color(0xFFC08A28), Color(0xFF3D2A12)]);
        _dunes(canvas, size);
      case ScenicPackId.lakeStill:
        _sky(canvas, size,
            const [Color(0xFFA8C5C5), Color(0xFF4A7C7C), Color(0xFF1E3A3A)]);
        _lake(canvas, size);
      case ScenicPackId.auroraVeil:
        _sky(canvas, size,
            const [Color(0xFF0B1D2A), Color(0xFF1E7F72), Color(0xFF7B5EA7)]);
        _aurora(canvas, size);
        _stars(canvas, size, count: 40);
    }
  }

  void _sky(Canvas canvas, Size size, List<Color> colors) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        colors,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _sun(Canvas canvas, Size size, Offset frac, double r, Color color) {
    final c = Offset(size.width * frac.dx, size.height * frac.dy);
    canvas.drawCircle(
        c, r * 1.6, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(c, r, Paint()..color = color);
  }

  void _hills(Canvas canvas, Size size, List<Color> colors, double startY) {
    for (var i = 0; i < colors.length; i++) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(0, size.height * (startY + i * 0.08));
      for (var x = 0.0; x <= size.width; x += 20) {
        final y = size.height * (startY + i * 0.08) +
            math.sin(x / 40 + i) * 18 -
            i * 10;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
  }

  void _mountains(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF5D6D7E),
      const Color(0xFF34495E),
      const Color(0xFF1C2833)
    ];
    for (var i = 0; i < 3; i++) {
      final path = Path()..moveTo(-40, size.height);
      final peaks = 3 + i;
      for (var p = 0; p <= peaks; p++) {
        final x = size.width * (p / peaks);
        final y =
            size.height * (0.42 + i * 0.08) - (p.isEven ? 90.0 - i * 12 : 40.0);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width + 40, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i].withValues(alpha: 0.9));
    }
  }

  void _waves(Canvas canvas, Size size, Color color) {
    for (var i = 0; i < 5; i++) {
      final path = Path()..moveTo(0, size.height * (0.55 + i * 0.08));
      for (var x = 0.0; x <= size.width; x += 16) {
        path.lineTo(
          x,
          size.height * (0.55 + i * 0.08) + math.sin(x / 28 + i) * 10,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: 0.35 + i * 0.08),
      );
    }
  }

  void _clouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    void puff(double x, double y, double r) {
      canvas.drawCircle(Offset(x, y), r, paint);
      canvas.drawCircle(Offset(x + r * 0.8, y + 4), r * 0.7, paint);
      canvas.drawCircle(Offset(x - r * 0.7, y + 6), r * 0.6, paint);
    }

    puff(size.width * 0.2, size.height * 0.22, 28);
    puff(size.width * 0.65, size.height * 0.18, 34);
    puff(size.width * 0.45, size.height * 0.3, 22);
  }

  void _stars(Canvas canvas, Size size, {int count = 70}) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final rnd = math.Random(7);
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width,
            rnd.nextDouble() * size.height * 0.7),
        rnd.nextDouble() * 1.8 + 0.4,
        paint,
      );
    }
  }

  void _flowers(Canvas canvas, Size size) {
    final rnd = math.Random(3);
    for (var i = 0; i < 28; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = size.height * (0.62 + rnd.nextDouble() * 0.3);
      canvas.drawCircle(
        Offset(x, y),
        3 + rnd.nextDouble() * 3,
        Paint()
          ..color = [
            const Color(0xFFE8A0BF),
            const Color(0xFFE8C766),
            Colors.white,
          ][i % 3],
      );
    }
  }

  void _dunes(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFC08A28),
      const Color(0xFFA0763A),
      const Color(0xFF5C3A12),
    ];
    for (var i = 0; i < colors.length; i++) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(0, size.height * (0.58 + i * 0.08));
      for (var x = 0.0; x <= size.width; x += 24) {
        final y =
            size.height * (0.58 + i * 0.08) + math.sin(x / 70 + i * 0.8) * 28;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
  }

  void _lake(Canvas canvas, Size size) {
    final rect =
        Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [const Color(0x884A7C7C), const Color(0xFF1E3A3A)],
        ),
    );
    _hills(canvas, size, const [Color(0xFF2C4A3E)], 0.48);
  }

  void _aurora(Canvas canvas, Size size) {
    for (var i = 0; i < 4; i++) {
      final path = Path()..moveTo(0, size.height * (0.15 + i * 0.08));
      for (var x = 0.0; x <= size.width; x += 12) {
        path.lineTo(
          x,
          size.height * (0.15 + i * 0.08) + math.sin(x / 50 + i) * 30,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..color = [
            const Color(0x661E7F72),
            const Color(0x667B5EA7),
            const Color(0x6656CCF2),
            const Color(0x66E8A0BF),
          ][i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScenicBackgroundPainter oldDelegate) =>
      oldDelegate.id != id;
}
