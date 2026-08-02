import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reading_plan_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class ReadingPlansScreen extends StatefulWidget {
  const ReadingPlansScreen({super.key});

  @override
  State<ReadingPlansScreen> createState() => _ReadingPlansScreenState();
}

class _ReadingPlansScreenState extends State<ReadingPlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReadingPlanProvider>().loadPlans(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingPlanProvider>();
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
                    'Reading plans',
                    style: AppTheme.brandTitle(fontSize: 22, color: ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch ((
                provider.isLoading,
                provider.availablePlans.isEmpty
              )) {
                (true, _) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold),
                  ),
                (false, true) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'No licensed reading-plan catalog is installed.',
                        textAlign: TextAlign.center,
                        style: AppTheme.scripture(
                          fontSize: 15,
                          height: 1.55,
                          color: soft,
                        ),
                      ),
                    ),
                  ),
                _ => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    itemCount: provider.availablePlans.length,
                    itemBuilder: (context, index) {
                      final plan = provider.availablePlans[index];
                      final userPlan = provider.getUserPlanByPlanId(plan.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BpCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.title['en'] ?? plan.name,
                                      style: AppTheme.brandTitle(
                                        fontSize: 16,
                                        weight: FontWeight.w600,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${plan.duration} days',
                                      style: AppTheme.ui(
                                        fontSize: 12,
                                        color: soft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (userPlan == null)
                                FilledButton(
                                  onPressed: () => provider.startPlan(plan),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: Text(
                                    'Start',
                                    style: AppTheme.ui(
                                      fontSize: 12,
                                      weight: FontWeight.w700,
                                      color: AppTheme.onGold,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  '${(userPlan.progress * 100).round()}%',
                                  style: AppTheme.ui(
                                    fontSize: 14,
                                    weight: FontWeight.w700,
                                    color: AppTheme.teal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
