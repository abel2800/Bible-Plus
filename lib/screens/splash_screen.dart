import 'package:flutter/material.dart';

import '../widgets/design/bp_brand.dart';

/// Startup splash — black backdrop with centered Bible Plus logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    final scale = Tween(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: fade.value.clamp(0.88, 1.0),
              child: Transform.scale(scale: scale.value, child: child),
            );
          },
          child: Image.asset(
            BpBrandAssets.logoPath,
            width: 240,
            height: 240,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const BpBrandMark(size: 180),
          ),
        ),
      ),
    );
  }
}
