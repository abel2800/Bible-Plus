import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/bible_provider.dart';
import '../providers/bible_store_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';
import 'design/bp_widgets.dart';

class VersionSelectorBottomSheet extends StatelessWidget {
  const VersionSelectorBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bible = context.watch<BibleProvider>();
    final store = context.watch<BibleStoreProvider>();
    final prefs = context.watch<UserPreferencesProvider>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    final installed =
        store.catalog.where((pkg) => store.isInstalled(pkg.id)).toList();

    return Material(
      color: surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.selectVersion,
                      style: AppTheme.brandTitle(
                        fontSize: 19,
                        weight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ),
                  BpIconButton(
                    icon: Icons.close_rounded,
                    tooltip: l10n.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/bible_store');
                },
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(l10n.bibleStore),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: installed.isEmpty ? 1 : installed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (installed.isEmpty) {
                      return _VersionRow(
                        title: 'World English Bible',
                        subtitle: '${l10n.english} · ${l10n.publicDomain}',
                        selected: bible.currentVersion == 'WEB',
                        ink: ink,
                        soft: soft,
                        onTap: () async {
                          await bible.changeVersion('WEB');
                          await prefs.setPreferredBible('WEB');
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    }
                    final pkg = installed[index];
                    final selected = bible.currentVersion == pkg.versionId;
                    return _VersionRow(
                      title: pkg.name,
                      subtitle: '${pkg.languageName} · ${pkg.abbreviation}',
                      selected: selected,
                      ink: ink,
                      soft: soft,
                      onTap: () async {
                        await bible.changeVersion(pkg.versionId);
                        await prefs.setPreferredBible(pkg.versionId);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.ink,
    required this.soft,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final Color ink;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.ui(
                        fontSize: 15,
                        weight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.ui(fontSize: 12, color: soft),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppTheme.gold),
            ],
          ),
        ),
      ),
    );
  }
}
