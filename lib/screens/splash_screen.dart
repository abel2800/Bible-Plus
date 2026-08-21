import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';
import '../utils/font_env_stub.dart'
    if (dart.library.io) '../utils/font_env_io.dart';

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
    final t = context.colors;
    final markLetter = isFlutterTest
        ? const TextStyle(
            fontFamily: 'serif',
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: AppTheme.goldSoft,
          )
        : GoogleFonts.fraunces(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: AppTheme.goldSoft,
          );
    final titleStyle = isFlutterTest
        ? TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: t.ink,
          )
        : GoogleFonts.fraunces(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: t.ink,
          );
    final taglineStyle = isFlutterTest
        ? TextStyle(
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontSize: 14,
            letterSpacing: 0.5,
            color: t.inkSoft,
          )
        : GoogleFonts.sourceSerif4(
            fontStyle: FontStyle.italic,
            fontSize: 14,
            letterSpacing: 0.5,
            color: t.inkSoft,
          );

    return Scaffold(
      backgroundColor: t.appBg,
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutBack,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: AppTheme.indigo,
                    border: Border.all(color: AppTheme.gold),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.25),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('B', style: markLetter),
                ),
                const SizedBox(height: 18),
                Text('BiblePulse', style: titleStyle),
                const SizedBox(height: 4),
                Text('Scripture, illuminated.', style: taglineStyle),
                const SizedBox(height: 30),
                Container(
                  width: 120,
                  height: 2,
                  decoration: BoxDecoration(
                    color: t.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
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
