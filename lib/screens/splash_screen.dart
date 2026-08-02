import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
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
            color: Color(0xFF241804),
          )
        : GoogleFonts.fraunces(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF241804),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.7),
            radius: 1.1,
            colors: [t.surface2, t.appBg],
          ),
        ),
        child: Center(
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8C766),
                          Color(0xFFC08A28),
                          Color(0xFFA83232),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFC08A28).withValues(alpha: 0.45),
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
                          color: const Color(0xFFC08A28),
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
      ),
    );
  }
}
