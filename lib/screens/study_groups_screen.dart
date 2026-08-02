import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/study_group_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  bool _watching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_watching) return;
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      context.read<StudyGroupProvider>().watch(user.uid);
      _watching = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final groups = context.watch<StudyGroupProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final surface2 = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Scaffold(
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _create(context, user.uid),
              icon: const Icon(Icons.group_add_rounded),
              label: Text(
                'New group',
                style: AppTheme.ui(fontSize: 13, weight: FontWeight.w700),
              ),
            ),
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
                  Expanded(
                    child: Text(
                      'Private reading groups',
                      style: AppTheme.brandTitle(fontSize: 22, color: ink),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: user == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Sign in to use private reading groups.',
                          textAlign: TextAlign.center,
                          style: AppTheme.scripture(
                            fontSize: 15,
                            height: 1.55,
                            color: soft,
                          ),
                        ),
                      ),
                    )
                  : groups.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: AppTheme.vermilion,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  groups.error!,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.ui(fontSize: 14, color: soft),
                                ),
                              ],
                            ),
                          ),
                        )
                      : groups.groups.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        color: surface2,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.groups_rounded,
                                        size: 36,
                                        color: AppTheme.gold,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No groups yet',
                                      style: AppTheme.brandTitle(
                                        fontSize: 20,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Create a family or church-cell reading group.',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.scripture(
                                        fontSize: 15,
                                        height: 1.55,
                                        color: soft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 96),
                              itemCount: groups.groups.length,
                              itemBuilder: (context, index) {
                                final group = groups.groups[index];
                                final day = group.progressByUser[user.uid] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: BpCard(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      8,
                                      14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: surface2,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(color: border),
                                          ),
                                          child: const Icon(
                                            Icons.groups_rounded,
                                            color: AppTheme.teal,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                group.name,
                                                style: AppTheme.brandTitle(
                                                  fontSize: 15,
                                                  weight: FontWeight.w600,
                                                  color: ink,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${group.memberIds.length} members · '
                                                'Your completed day: $day',
                                                style: AppTheme.ui(
                                                  fontSize: 12,
                                                  color: soft,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Complete next day',
                                          onPressed: () =>
                                              groups.updateProgress(
                                            group.id,
                                            user.uid,
                                            day + 1,
                                          ),
                                          icon: const Icon(
                                            Icons.task_alt_rounded,
                                            color: AppTheme.teal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, String ownerId) async {
    final name = TextEditingController();
    final plan = TextEditingController();
    final members = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'New reading group',
          style: AppTheme.brandTitle(fontSize: 18, color: ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              style: AppTheme.ui(fontSize: 14, color: ink),
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            TextField(
              controller: plan,
              style: AppTheme.ui(fontSize: 14, color: ink),
              decoration: const InputDecoration(labelText: 'Reading plan ID'),
            ),
            TextField(
              controller: members,
              style: AppTheme.ui(fontSize: 14, color: ink),
              decoration: const InputDecoration(
                labelText: 'Member user IDs (comma-separated)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTheme.ui(fontSize: 13, weight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (save == true && context.mounted && name.text.trim().isNotEmpty) {
      await context.read<StudyGroupProvider>().create(
            ownerId: ownerId,
            name: name.text,
            planId: plan.text.trim(),
            invitedUserIds: members.text
                .split(',')
                .map((id) => id.trim())
                .where((id) => id.isNotEmpty)
                .toList(),
          );
    }
    name.dispose();
    plan.dispose();
    members.dispose();
  }
}
