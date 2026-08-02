import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_capabilities.dart';
import '../l10n/app_localizations.dart';
import '../providers/study_provider.dart';
import '../services/auth_service.dart';
import '../services/study_sync_service.dart';
import '../utils/app_theme.dart';
import 'design/bp_widgets.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final capabilities = context.watch<AppCapabilities>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final inkSoft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    return Drawer(
      backgroundColor: isDark ? AppTheme.appBgDark : AppTheme.appBgLight,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BpBrandMark(size: 52),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: AppTheme.brandTitle(fontSize: 22, color: ink),
                      children: const [
                        TextSpan(text: 'Bible'),
                        TextSpan(
                          text: 'Pulse',
                          style: TextStyle(color: AppTheme.gold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.offlineReading,
                    style: AppTheme.ui(fontSize: 12.5, color: inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const BpRule(),
            _item(context, Icons.search_rounded, l10n.navSearch, '/search'),
            _item(
              context,
              Icons.storefront_outlined,
              l10n.bibleStore,
              '/bible_store',
            ),
            _item(
              context,
              Icons.graphic_eq_outlined,
              l10n.audioStore,
              '/audio_store',
            ),
            if (capabilities.devotionals)
              _item(
                context,
                Icons.self_improvement_rounded,
                l10n.devotionals,
                '/devotions',
              ),
            if (capabilities.readingPlans)
              _item(
                context,
                Icons.route_rounded,
                l10n.readingPlans,
                '/reading_plans',
              ),
            if (capabilities.cloud && capabilities.readingPlans)
              _item(
                context,
                Icons.groups_rounded,
                l10n.privateReadingGroups,
                '/study_groups',
              ),
            if (capabilities.hymns)
              _item(context, Icons.music_note_rounded, l10n.hymns, '/hymns'),
            _item(
              context,
              Icons.volunteer_activism_rounded,
              l10n.prayerJournal,
              '/prayer_journal',
            ),
            if (capabilities.community)
              _item(
                  context, Icons.forum_outlined, l10n.community, '/community'),
            _item(
              context,
              Icons.auto_awesome_rounded,
              l10n.verseWallpaper,
              '/wallpaper',
            ),
            const SizedBox(height: 8),
            const BpRule(),
            if (!capabilities.cloud)
              ListTile(
                minTileHeight: 48,
                leading: Icon(Icons.cloud_off_rounded, color: inkSoft),
                title: Text(
                  l10n.audioGated,
                  style: AppTheme.ui(fontSize: 13, color: inkSoft),
                ),
              )
            else if (context.watch<AuthService>().currentUser == null)
              _item(context, Icons.login_rounded, l10n.signIn, '/auth')
            else ...[
              ListTile(
                minTileHeight: 48,
                leading: Icon(Icons.sync_rounded, color: inkSoft),
                title: Text(
                  l10n.syncStudy,
                  style: AppTheme.ui(
                    fontSize: 13.5,
                    weight: FontWeight.w500,
                    color: ink,
                  ),
                ),
                onTap: () async {
                  final user = context.read<AuthService>().currentUser!;
                  await context.read<StudyProvider>().synchronize(
                        context.read<StudySyncGateway>(),
                        user.uid,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                minTileHeight: 48,
                leading: Icon(Icons.logout_rounded, color: inkSoft),
                title: Text(
                  l10n.signOut,
                  style: AppTheme.ui(
                    fontSize: 13.5,
                    weight: FontWeight.w500,
                    color: ink,
                  ),
                ),
                onTap: () async {
                  await context.read<AuthService>().signOut();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route, {
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final inkSoft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;

    return ListTile(
      minTileHeight: 48,
      enabled: enabled,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: enabled ? inkSoft : faint),
      title: Text(
        label,
        style: AppTheme.ui(
          fontSize: 13.5,
          weight: FontWeight.w500,
          color: enabled ? ink : faint,
        ),
      ),
      trailing: Icon(
        enabled ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
        size: 18,
        color: faint,
      ),
      onTap: enabled
          ? () {
              Navigator.pop(context);
              Navigator.pushNamed(context, route);
            }
          : null,
    );
  }
}
