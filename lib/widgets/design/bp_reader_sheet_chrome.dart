import 'package:flutter/material.dart';

import '../../models/color_theme.dart';
import '../../utils/app_theme.dart';

/// Shared bottom-sheet chrome matching bible-plus-reading-page HTML mock.
class BpReaderSheetColors {
  BpReaderSheetColors({required ReaderColorTheme theme})
      : sheetBg =
            theme.isDark ? const Color(0xFF141310) : const Color(0xFFFFFDF9),
        card = theme.isDark ? const Color(0xFF161512) : Colors.white,
        card2 =
            theme.isDark ? const Color(0xFF1B1916) : const Color(0xFFF3F1EA),
        borderFlat = theme.isDark
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.black.withValues(alpha: 0.08),
        borderSoft = theme.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        gold = theme.accentColor,
        text1 = theme.headerColor,
        text2 = theme.verseNumberColor,
        text3 = theme.verseNumberColor;

  final Color sheetBg;
  final Color card;
  final Color card2;
  final Color borderFlat;
  final Color borderSoft;
  final Color gold;
  final Color text1;
  final Color text2;
  final Color text3;
}

class BpReaderSheetContainer extends StatelessWidget {
  const BpReaderSheetContainer({
    super.key,
    required this.colors,
    required this.title,
    required this.child,
    this.maxHeightFactor = 0.78,
  });

  final BpReaderSheetColors colors;
  final String title;
  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colors.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border:
            Border(top: BorderSide(color: colors.gold.withValues(alpha: 0.13))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderFlat,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.brandTitle(
                        fontSize: 16,
                        weight: FontWeight.w500,
                        color: colors.text1,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.card2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: colors.text2),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.borderSoft),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class BpReaderMiniLabel extends StatelessWidget {
  const BpReaderMiniLabel(
      {super.key, required this.label, required this.colors});

  final String label;
  final BpReaderSheetColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.ui(
          fontSize: 10.5,
          weight: FontWeight.w600,
          letterSpacing: 0.03,
          color: colors.gold,
        ),
      ),
    );
  }
}

class BpReaderTogglePill extends StatelessWidget {
  const BpReaderTogglePill({
    super.key,
    required this.colors,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  final BpReaderSheetColors colors;
  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderFlat),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillBtn(
              label: leftLabel,
              active: leftSelected,
              colors: colors,
              onTap: onLeft,
            ),
          ),
          Expanded(
            child: _PillBtn(
              label: rightLabel,
              active: !leftSelected,
              colors: colors,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  const _PillBtn({
    required this.label,
    required this.active,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool active;
  final BpReaderSheetColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? colors.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.ui(
              fontSize: 12,
              weight: FontWeight.w600,
              color: active ? AppTheme.onGold : colors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

class BpReaderSearchInput extends StatelessWidget {
  const BpReaderSearchInput({
    super.key,
    required this.colors,
    required this.hint,
    required this.onChanged,
  });

  final BpReaderSheetColors colors;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderFlat),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 14, color: colors.text2),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTheme.ui(fontSize: 12.5, color: colors.text1),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTheme.ui(fontSize: 12.5, color: colors.text2),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BpReaderStepper extends StatelessWidget {
  const BpReaderStepper({
    super.key,
    required this.colors,
    required this.valueLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  final BpReaderSheetColors colors;
  final String valueLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
            colors: colors, icon: Icons.remove_rounded, onTap: onDecrement),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            valueLabel,
            textAlign: TextAlign.center,
            style: AppTheme.ui(fontSize: 12.5, color: colors.text2),
          ),
        ),
        const SizedBox(width: 10),
        _StepBtn(colors: colors, icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.colors,
    required this.icon,
    required this.onTap,
  });

  final BpReaderSheetColors colors;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.card2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.borderFlat),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 14, color: colors.text1),
        ),
      ),
    );
  }
}

class BpReaderSwitch extends StatelessWidget {
  const BpReaderSwitch({
    super.key,
    required this.colors,
    required this.value,
    required this.onChanged,
  });

  final BpReaderSheetColors colors;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 21,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color:
              value ? colors.gold.withValues(alpha: 0.13) : colors.borderFlat,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 17,
            height: 17,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? colors.gold : colors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

class BpReaderSettingsRow extends StatelessWidget {
  const BpReaderSettingsRow({
    super.key,
    required this.colors,
    required this.label,
    required this.trailing,
  });

  final BpReaderSheetColors colors;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.ui(fontSize: 13, color: colors.text1),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
