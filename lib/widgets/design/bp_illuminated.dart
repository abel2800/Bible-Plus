import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class BpCornerMark extends StatelessWidget {
  const BpCornerMark({super.key, this.size = 10, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerMarkPainter(color ?? AppTheme.goldSoft),
      ),
    );
  }
}

class _CornerMarkPainter extends CustomPainter {
  _CornerMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final arm = size.width / 2;
    final vertical = Path()
      ..moveTo(cx, cy - arm)
      ..lineTo(cx + arm * .35, cy)
      ..lineTo(cx, cy + arm)
      ..lineTo(cx - arm * .35, cy)
      ..close();
    final horizontal = Path()
      ..moveTo(cx - arm, cy)
      ..lineTo(cx, cy - arm * .35)
      ..lineTo(cx + arm, cy)
      ..lineTo(cx, cy + arm * .35)
      ..close();
    canvas
      ..drawPath(vertical, paint)
      ..drawPath(horizontal, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class BpMedallion extends StatelessWidget {
  const BpMedallion({
    super.key,
    required this.child,
    this.size = 34,
    this.ringColor,
  });

  final Widget child;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final color = ringColor ?? AppTheme.gold;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
          ),
          Container(
            margin: EdgeInsets.all(size * .09),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .5), width: .6),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class BpIlluminatedAction {
  const BpIlluminatedAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
}

class BpIlluminatedCard extends StatelessWidget {
  const BpIlluminatedCard({
    super.key,
    required this.tag,
    required this.text,
    required this.reference,
    this.actions = const [],
    this.onTap,
    this.ethiopicText = false,
  });

  final String tag;
  final String text;
  final String reference;
  final List<BpIlluminatedAction> actions;
  final VoidCallback? onTap;
  final bool ethiopicText;

  @override
  Widget build(BuildContext context) {
    final style = ethiopicText
        ? AppTheme.ethopic(fontSize: 16, color: AppTheme.appBgLight)
        : AppTheme.brandTitle(
            fontSize: 16,
            weight: FontWeight.w400,
            color: AppTheme.appBgLight,
          ).copyWith(height: 1.5);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.indigo,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.gold),
            boxShadow: const [
              BoxShadow(color: AppTheme.goldSoft, blurRadius: 0, spreadRadius: 4),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(top: 10, left: 12, child: BpCornerMark()),
              const Positioned(top: 10, right: 12, child: BpCornerMark()),
              const Positioned(bottom: 10, left: 12, child: BpCornerMark()),
              const Positioned(bottom: 10, right: 12, child: BpCornerMark()),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
                child: Column(
                  children: [
                    Text(
                      tag.toUpperCase(),
                      style: AppTheme.ui(
                        fontSize: 10,
                        weight: FontWeight.w700,
                        color: AppTheme.goldSoft,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _DropCapText(text: text, style: style),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      reference.toUpperCase(),
                      style: AppTheme.ui(
                        fontSize: 10,
                        weight: FontWeight.w600,
                        color: AppTheme.goldSoft,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(width: 36, height: 1, color: AppTheme.goldSoft.withValues(alpha: .6)),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: AppTheme.goldSoft.withValues(alpha: .25))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              if (i > 0) const SizedBox(width: 28),
                              _IlluminatedActionButton(action: actions[i]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IlluminatedActionButton extends StatelessWidget {
  const _IlluminatedActionButton({required this.action});
  final BpIlluminatedAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? AppTheme.goldSoft;
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 17, color: color),
            const SizedBox(height: 3),
            Text(
              action.label,
              style: AppTheme.ui(fontSize: 9, weight: FontWeight.w600, color: color.withValues(alpha: .9)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropCapText extends StatelessWidget {
  const _DropCapText({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, 1),
            style: style.copyWith(
              fontSize: (style.fontSize ?? 16) * 2.7,
              color: AppTheme.gold,
              fontWeight: FontWeight.w500,
              height: .75,
            ),
          ),
          TextSpan(text: text.substring(1), style: style),
        ],
      ),
    );
  }
}

class BpReadingThread extends StatefulWidget {
  const BpReadingThread({
    super.key,
    required this.scrollController,
    this.tickCount = 12,
    this.width = 18,
    this.activeColor,
    this.inactiveColor,
  });

  final ScrollController scrollController;
  final int tickCount;
  final double width;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  State<BpReadingThread> createState() => _BpReadingThreadState();
}

class _BpReadingThreadState extends State<BpReadingThread> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final position = widget.scrollController.hasClients
        ? widget.scrollController.position
        : null;
    final fraction = position == null || position.maxScrollExtent <= 0
      ? 1.0
        : (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
    final filled = (fraction * widget.tickCount).round();
    final active = widget.activeColor ?? AppTheme.gold;
    final inactive = widget.inactiveColor ?? AppTheme.borderLight;
    return SizedBox(
      width: widget.width,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          children: List.generate(widget.tickCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: 2,
                height: 12,
                decoration: BoxDecoration(
                  color: index < filled ? active : inactive,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
