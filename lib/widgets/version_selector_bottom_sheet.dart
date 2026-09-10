import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/bible_package.dart';
import '../providers/audio_store_provider.dart';
import '../providers/bible_provider.dart';
import '../providers/bible_store_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';
import 'design/bp_widgets.dart';

class _TranslationChoice {
  const _TranslationChoice({
    required this.versionId,
    required this.name,
    required this.subtitle,
    required this.languageName,
    this.packageId,
  });

  final String versionId;
  final String name;
  final String subtitle;
  final String languageName;
  final String? packageId;
}

List<_TranslationChoice> _installedTranslations({
  required BibleProvider bible,
  required BibleStoreProvider store,
}) {
  final byVersion = <String, _TranslationChoice>{};

  void addChoice({
    required String versionId,
    required String name,
    required String subtitle,
    required String languageName,
    String? packageId,
  }) {
    final key = versionId.toUpperCase();
    byVersion.putIfAbsent(
      key,
      () => _TranslationChoice(
        versionId: versionId.toUpperCase(),
        name: name,
        subtitle: subtitle,
        languageName: languageName,
        packageId: packageId,
      ),
    );
  }

  BiblePackageInfo? catalogFor(String packageId, String versionId) {
    for (final pkg in store.catalog) {
      if (pkg.id == packageId) return pkg;
    }
    for (final pkg in store.catalog) {
      if (pkg.versionId.toUpperCase() == versionId.toUpperCase()) return pkg;
    }
    return null;
  }

  for (final installed in store.installed.values) {
    final catalog = catalogFor(installed.packageId, installed.versionId);
    addChoice(
      versionId: installed.versionId,
      name: catalog?.name ?? installed.versionId,
      subtitle: catalog != null
          ? '${catalog.languageName} · ${catalog.abbreviation}'
          : '${installed.language} · ${installed.versionId}',
      languageName: catalog?.languageName ?? installed.language,
      packageId: installed.packageId,
    );
  }

  for (final versionId in bible.availableVersions) {
    if (byVersion.containsKey(versionId.toUpperCase())) continue;
    final catalog = catalogFor('', versionId);
    addChoice(
      versionId: versionId,
      name: catalog?.name ?? versionId,
      subtitle: catalog != null
          ? '${catalog.languageName} · ${catalog.abbreviation}'
          : 'Installed translation',
      languageName: catalog?.languageName ?? 'Other',
    );
  }

  if (!byVersion.containsKey('WEB')) {
    addChoice(
      versionId: 'WEB',
      name: 'World English Bible',
      subtitle: 'English · WEB',
      languageName: 'English',
      packageId: 'web',
    );
  }

  final choices = byVersion.values.toList()
    ..sort((a, b) {
      final lang = a.languageName.compareTo(b.languageName);
      if (lang != 0) return lang;
      return a.name.compareTo(b.name);
    });
  return choices;
}

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

    final installed = _installedTranslations(bible: bible, store: store);
    final installedIds =
        installed.map((e) => e.versionId.toUpperCase()).toSet();
    final storePackages = store.visiblePackages
        .where((pkg) =>
            pkg.canInstall &&
            !store.isInstalled(pkg.id) &&
            !installedIds.contains(pkg.versionId.toUpperCase()))
        .take(12)
        .toList();

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
              const SizedBox(height: 6),
              Text(
                '${installed.length} translation${installed.length == 1 ? '' : 's'} ready to read',
                style: AppTheme.ui(fontSize: 12, color: soft),
              ),
              const SizedBox(height: 12),
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
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                      child: Text(
                        'ON THIS DEVICE',
                        style: AppTheme.ui(
                          fontSize: 10,
                          weight: FontWeight.w600,
                          color: soft,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ),
                    for (final choice in installed)
                      _TransListRow(
                        title: choice.name,
                        subtitle: choice.subtitle,
                        selected: bible.currentVersion.toUpperCase() ==
                            choice.versionId.toUpperCase(),
                        ink: ink,
                        soft: soft,
                        onTap: () => _selectVersion(
                          context,
                          bible: bible,
                          prefs: prefs,
                          versionId: choice.versionId,
                        ),
                      ),
                    if (storePackages.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                        child: Text(
                          'AVAILABLE IN THE STORE',
                          style: AppTheme.ui(
                            fontSize: 10,
                            weight: FontWeight.w600,
                            color: soft,
                            letterSpacing: 0.05,
                          ),
                        ),
                      ),
                      for (final pkg in storePackages)
                        _StoreTransRow(
                          title: pkg.name,
                          subtitle:
                              '${pkg.languageName} · ${_sizeLabel(pkg.fileSizeBytes)}',
                          ink: ink,
                          soft: soft,
                          onGet: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/bible_store');
                          },
                        ),
                    ],
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/bible_store');
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                        child: Text(
                          'Browse all translations in the Store →',
                          textAlign: TextAlign.center,
                          style: AppTheme.ui(
                            fontSize: 12,
                            weight: FontWeight.w600,
                            color: AppTheme.gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectVersion(
    BuildContext context, {
    required BibleProvider bible,
    required UserPreferencesProvider prefs,
    required String versionId,
  }) async {
    final audioStore = context.read<AudioStoreProvider>();
    await bible.changeVersion(versionId);
    await prefs.setPreferredBible(versionId);
    final audioPkg = audioStore.bestPackageForTextVersion(versionId);
    if (audioPkg != null) {
      await prefs.setPreferredAudio(audioPkg.id);
    }
    if (context.mounted) Navigator.pop(context);
  }
}

String _sizeLabel(int bytes) {
  if (bytes <= 0) return 'Download';
  final mb = (bytes / (1024 * 1024)).round();
  return '$mb MB';
}

class _TransListRow extends StatelessWidget {
  const _TransListRow({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.ui(
                      fontSize: 13.5,
                      weight: FontWeight.w500,
                      color: ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.ui(fontSize: 10.5, color: soft),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.gold : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppTheme.gold
                      : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: AppTheme.onGold,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreTransRow extends StatelessWidget {
  const _StoreTransRow({
    required this.title,
    required this.subtitle,
    required this.ink,
    required this.soft,
    required this.onGet,
  });

  final String title;
  final String subtitle;
  final Color ink;
  final Color soft;
  final VoidCallback onGet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.ui(
                    fontSize: 13.5,
                    weight: FontWeight.w500,
                    color: ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.ui(fontSize: 10.5, color: soft),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onGet,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.gold,
              side: const BorderSide(color: AppTheme.gold),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              'Get',
              style: AppTheme.ui(
                fontSize: 10.5,
                weight: FontWeight.w700,
                color: AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
