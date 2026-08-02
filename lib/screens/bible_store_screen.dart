import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/audio_config.dart';
import '../l10n/app_localizations.dart';
import '../models/bible_package.dart';
import '../providers/bible_provider.dart';
import '../providers/bible_store_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';

class BibleStoreScreen extends StatelessWidget {
  const BibleStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<BibleStoreProvider>();
    final t = context.colors;

    return Scaffold(
      backgroundColor: t.appBg,
      appBar: AppBar(
        title: Text(l10n.bibleStore),
      ),
      body: !store.ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextField(
                    onChanged: store.setQuery,
                    decoration: InputDecoration(
                      hintText: l10n.searchVersions,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _Chip(
                        label: l10n.categoryAll,
                        selected: store.categoryFilter == 'all',
                        onTap: () => store.setCategoryFilter('all'),
                      ),
                      _Chip(
                        label: l10n.categoryPopular,
                        selected: store.categoryFilter == 'popular',
                        onTap: () => store.setCategoryFilter('popular'),
                      ),
                      _Chip(
                        label: l10n.categoryNew,
                        selected: store.categoryFilter == 'new',
                        onTap: () => store.setCategoryFilter('new'),
                      ),
                      _Chip(
                        label: l10n.categoryUpdated,
                        selected: store.categoryFilter == 'updated',
                        onTap: () => store.setCategoryFilter('updated'),
                      ),
                      _Chip(
                        label: l10n.english,
                        selected: store.languageFilter == 'en',
                        onTap: () => store.setLanguageFilter(
                          store.languageFilter == 'en' ? 'all' : 'en',
                        ),
                      ),
                      _Chip(
                        label: l10n.amharic,
                        selected: store.languageFilter == 'am',
                        onTap: () => store.setLanguageFilter(
                          store.languageFilter == 'am' ? 'all' : 'am',
                        ),
                      ),
                      _Chip(
                        label: l10n.afaanOromo,
                        selected: store.languageFilter == 'om',
                        onTap: () => store.setLanguageFilter(
                          store.languageFilter == 'om' ? 'all' : 'om',
                        ),
                      ),
                      _Chip(
                        label: l10n.tigrinya,
                        selected: store.languageFilter == 'ti',
                        onTap: () => store.setLanguageFilter(
                          store.languageFilter == 'ti' ? 'all' : 'ti',
                        ),
                      ),
                      _Chip(
                        label: l10n.somali,
                        selected: store.languageFilter == 'so',
                        onTap: () => store.setLanguageFilter(
                          store.languageFilter == 'so' ? 'all' : 'so',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: store.visiblePackages.length,
                    itemBuilder: (context, index) {
                      final pkg = store.visiblePackages[index];
                      return _BiblePackageCard(package: pkg);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppBrand.teal,
        labelStyle: AppText.ui(
          context,
          size: 11.5,
          w: FontWeight.w600,
          color: selected ? Colors.white : t.inkSoft,
        ),
        backgroundColor: t.surface2,
        side: BorderSide(color: selected ? AppBrand.teal : t.border),
      ),
    );
  }
}

class _BiblePackageCard extends StatelessWidget {
  const _BiblePackageCard({required this.package});

  final BiblePackageInfo package;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<BibleStoreProvider>();
    final prefs = context.watch<UserPreferencesProvider>();
    final bible = context.watch<BibleProvider>();
    final t = context.colors;
    final installed = store.isInstalled(package.id);
    final progress = store.progress[package.id];
    final downloading = progress?.state == PackageDownloadState.downloading ||
        progress?.state == PackageDownloadState.verifying ||
        progress?.state == PackageDownloadState.installing;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  package.name,
                  style: AppText.display(context, size: 17),
                ),
              ),
              if (installed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppBrand.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    package.install.type == 'asset'
                        ? l10n.bundled
                        : l10n.installed,
                    style: AppText.ui(
                      context,
                      size: 11,
                      w: FontWeight.w700,
                      color: AppBrand.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${package.languageName} · ${package.abbreviation} · ${package.license}',
            style: AppText.ui(context, size: 12, color: t.inkSoft),
          ),
          const SizedBox(height: 10),
          Text(
            package.description,
            style: AppText.ui(context, size: 13, color: t.inkSoft),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('${l10n.fileSize}: ${_formatBytes(package.fileSizeBytes)}',
                  style: AppText.uiFaint(context)),
              Text(
                '${l10n.offlineSize}: ${_formatBytes(package.offlineSizeBytes)}',
                style: AppText.uiFaint(context),
              ),
              Text('${l10n.lastUpdated}: ${package.updatedAt}',
                  style: AppText.uiFaint(context)),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress?.progress),
            const SizedBox(height: 6),
            Text(l10n.downloadProgress, style: AppText.uiFaint(context)),
          ],
          if (progress?.state == PackageDownloadState.failed) ...[
            const SizedBox(height: 8),
            Text(
              progress?.error ?? l10n.downloadFailed,
              style: AppText.ui(context, size: 12, color: AppBrand.error),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (!package.canInstall)
                Text(
                  package.install.type == 'unavailable' && AudioConfig.hasApiKey
                      ? 'Use Bible Brain listings below when your key includes this language'
                      : l10n.requiresLicense,
                  style: AppText.ui(
                    context,
                    size: 12.5,
                    w: FontWeight.w600,
                    color: AppBrand.vermilion,
                  ),
                )
              else if (package.install.type == 'bible_brain' &&
                  !AudioConfig.hasApiKey)
                Text(
                  'Add BIBLE_BRAIN_API_KEY to enable online',
                  style: AppText.ui(
                    context,
                    size: 12.5,
                    w: FontWeight.w600,
                    color: AppBrand.vermilion,
                  ),
                )
              else if (!installed)
                ElevatedButton(
                  onPressed: downloading
                      ? null
                      : () async {
                          try {
                            await store.install(package);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    package.install.type == 'bible_brain'
                                        ? 'Enabled ${package.abbreviation} (online)'
                                        : l10n.downloadComplete,
                                  ),
                                ),
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${l10n.downloadFailed}: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: Text(
                    package.install.type == 'bible_brain'
                        ? 'Enable online'
                        : l10n.download,
                  ),
                )
              else ...[
                OutlinedButton(
                  onPressed: () async {
                    await prefs.setPreferredBible(package.versionId);
                    await bible.changeVersion(package.versionId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${l10n.preferredBible}: ${package.abbreviation}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(l10n.preferredBible),
                ),
                const SizedBox(width: 8),
                if (package.install.type != 'asset')
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.delete),
                          content: Text(l10n.deletePackageConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) await store.uninstall(package.id);
                    },
                    child: Text(l10n.delete),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
