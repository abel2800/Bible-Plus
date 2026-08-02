import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_capabilities.dart';
import '../l10n/app_localizations.dart';
import '../models/audio_package.dart';
import '../providers/audio_download_provider.dart';
import '../providers/audio_store_provider.dart';
import '../providers/bible_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';

class AudioStoreScreen extends StatelessWidget {
  const AudioStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<AudioStoreProvider>();
    final t = context.colors;
    final capabilities = context.watch<AppCapabilities>();

    return Scaffold(
      backgroundColor: t.appBg,
      appBar: AppBar(title: Text(l10n.audioStore)),
      body: !store.ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!capabilities.audio)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: t.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.border),
                      ),
                      child: Text(
                        l10n.audioSetupNote,
                        style: AppText.ui(context, size: 13, color: t.inkSoft),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    onChanged: store.setQuery,
                    decoration: InputDecoration(
                      hintText: l10n.searchAudio,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: store.visiblePackages.length,
                    itemBuilder: (context, index) {
                      return _AudioCard(package: store.visiblePackages[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _AudioCard extends StatelessWidget {
  const _AudioCard({required this.package});

  final AudioPackageInfo package;

  Future<void> _downloadFull(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bible = context.read<BibleProvider>();
    final downloads = context.read<AudioDownloadProvider>();
    final store = context.read<AudioStoreProvider>();
    final prefs = context.read<UserPreferencesProvider>();

    final books = bible.books;
    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.downloadFailed)),
      );
      return;
    }

    final chapterCount = books.fold<int>(0, (sum, b) => sum + b.chapters);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.download),
        content: Text(
          'Download the full ${package.name} audio Bible?\n\n'
          '$chapterCount chapters will cache offline, like installing a '
          'Bible translation in the Bible Store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.download),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await downloads.downloadFullBible(
      versionId: package.bibleVersionId,
      books: [
        for (final book in books)
          (bookId: book.id, chapterCount: book.chapters),
      ],
    );

    if (!context.mounted) return;

    if (downloads.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.downloadFailed}: ${downloads.error}')),
      );
      return;
    }

    await store.markInstalled(
      package,
      chapters: downloads.completedChapters,
      bytes: downloads.cacheSizeBytes,
    );
    await prefs.setPreferredAudio(package.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.downloadComplete)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<AudioStoreProvider>();
    final prefs = context.watch<UserPreferencesProvider>();
    final downloads = context.watch<AudioDownloadProvider>();
    final t = context.colors;
    final installed = store.isInstalled(package.id);
    final canActivate = store.canActivate(package);
    final downloading = downloads.downloading;

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
          Text(package.name, style: AppText.display(context, size: 17)),
          const SizedBox(height: 6),
          Text(
            '${package.languageName} · ${package.translation} · ${package.narrator}',
            style: AppText.ui(context, size: 12, color: t.inkSoft),
          ),
          const SizedBox(height: 10),
          Text(
            package.description,
            style: AppText.ui(context, size: 13, color: t.inkSoft),
          ),
          const SizedBox(height: 10),
          Text(
            '${l10n.quality}: ${package.quality} · ${l10n.duration}: ${package.durationLabel}',
            style: AppText.uiFaint(context),
          ),
          if (downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: downloads.progress),
            const SizedBox(height: 6),
            Text(
              '${l10n.downloadProgress} '
              '${downloads.completedChapters}/${downloads.totalChapters}',
              style: AppText.uiFaint(context),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: downloads.pause,
                icon: const Icon(Icons.pause_rounded, size: 18),
                label: Text(l10n.cancelDownload),
              ),
            ),
          ],
          if (downloads.error != null && !downloading) ...[
            const SizedBox(height: 8),
            Text(
              downloads.error!,
              style: AppText.ui(context, size: 12, color: AppBrand.error),
            ),
          ],
          const SizedBox(height: 14),
          if (!package.approved)
            Text(
              l10n.requiresLicense,
              style: AppText.ui(
                context,
                size: 12.5,
                w: FontWeight.w600,
                color: AppBrand.vermilion,
              ),
            )
          else if (!canActivate)
            Text(l10n.audioGated, style: AppText.ui(context, size: 12.5))
          else
            Row(
              children: [
                if (!installed)
                  ElevatedButton(
                    onPressed:
                        downloading ? null : () => _downloadFull(context),
                    child: Text(l10n.download),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => prefs.setPreferredAudio(package.id),
                    child: Text(l10n.preferredAudio),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => store.uninstall(package.id),
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
