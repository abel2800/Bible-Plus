import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/study_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';
import '../widgets/highlight_list_item.dart';
import '../widgets/note_list_item.dart';
import '../widgets/bookmark_list_item.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = Provider.of<StudyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;
    final surface2 = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    BpIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'Study',
                    style: AppTheme.brandTitle(fontSize: 22, color: ink),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.onGold,
                  unselectedLabelColor: faint,
                  labelStyle: AppTheme.ui(
                    fontSize: 12,
                    weight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: AppTheme.ui(
                    fontSize: 12,
                    weight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                      height: 40,
                      icon: Icon(Icons.highlight_rounded, size: 16),
                      text: 'Highlights',
                    ),
                    Tab(
                      height: 40,
                      icon: Icon(Icons.note_rounded, size: 16),
                      text: 'Notes',
                    ),
                    Tab(
                      height: 40,
                      icon: Icon(Icons.bookmark_rounded, size: 16),
                      text: 'Bookmarks',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  studyProvider.highlights.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.highlight_rounded,
                          message: 'No highlights yet',
                          description:
                              'Long press any verse to add a highlight',
                          isDark: isDark,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: studyProvider.highlights.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: HighlightListItem(
                                highlight: studyProvider.highlights[index],
                              ),
                            );
                          },
                        ),
                  studyProvider.notes.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.note_rounded,
                          message: 'No notes yet',
                          description: 'Add notes to verses for personal study',
                          isDark: isDark,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: studyProvider.notes.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NoteListItem(
                                note: studyProvider.notes[index],
                              ),
                            );
                          },
                        ),
                  studyProvider.bookmarks.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.bookmark_rounded,
                          message: 'No bookmarks yet',
                          description:
                              'Bookmark verses to easily find them later',
                          isDark: isDark,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: studyProvider.bookmarks.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: BookmarkListItem(
                                bookmark: studyProvider.bookmarks[index],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String description,
    required bool isDark,
  }) {
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final surface2 = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;

    return Center(
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
                border: Border.all(color: border, width: 1.5),
              ),
              child: Icon(icon, size: 36, color: AppTheme.gold),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTheme.brandTitle(fontSize: 20, color: ink),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style:
                  AppTheme.scripture(fontSize: 15, height: 1.55, color: soft),
            ),
          ],
        ),
      ),
    );
  }
}
