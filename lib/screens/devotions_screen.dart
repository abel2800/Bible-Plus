import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/devotional_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class DevotionsScreen extends StatelessWidget {
  const DevotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DevotionalProvider>();
    final devotional = provider.todayDevotional;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  BpIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Devotionals',
                    style: AppTheme.brandTitle(fontSize: 22, color: ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold),
                    )
                  : devotional == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              'No licensed devotional catalog is installed.',
                              textAlign: TextAlign.center,
                              style: AppTheme.scripture(
                                fontSize: 15,
                                height: 1.55,
                                color: soft,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          children: [
                            BpCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    devotional.verseReference.toUpperCase(),
                                    style: AppTheme.ui(
                                      fontSize: 11,
                                      weight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppTheme.gold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    devotional.dailyVerse,
                                    style: AppTheme.scripture(
                                      fontSize: 17,
                                      height: 1.75,
                                      color: ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const BpSectionLabel(title: 'Prayer'),
                            BpCard(
                              child: Text(
                                devotional.dailyPrayer,
                                style: AppTheme.scripture(
                                  fontSize: 16,
                                  height: 1.7,
                                  color: ink,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
