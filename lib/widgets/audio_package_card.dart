import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/audio_package.dart';
import '../providers/audio_download_provider.dart';
import '../providers/audio_store_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../services/bible_service.dart';
import '../utils/app_theme.dart';

class AudioPackageCard extends StatelessWidget {
  const AudioPackageCard({
    super.key,
    required this.package,
    this.compact = false,
  });

  final AudioPackageInfo package;
  final bool compact;

  Future<void> _downloadFull(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bibleService = context.read<BibleService>();
    final downloads = context.read<AudioDownloadProvider>();
    final store = context.read<AudioStoreProvider>();
    final prefs = context.read<UserPreferencesProvider>();

    List<({int bookId, int chapterCount})> books;
    try {
      final catalogBooks = await bibleService.getBooks(package.bibleVersionId);
      books = [
        for (final book in catalogBooks)
          (bookId: book.id, chapterCount: book.chapters),
      ];
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadFailed)),
        );
      }
      return;
    }

    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.downloadFailed)),
      );
      return;
    }

    final chapterCount =
        books.fold<int>(0, (sum, book) => sum + book.chapterCount);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.download),
        content: Text(
          'Download ${package.name} for offline listening?\n\n'
          '$chapterCount chapters will be saved on this device.',
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
      books: books,
      packageId: package.id,
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

  Future<void> _selectPreferred(BuildContext context) async {
    final prefs = context.read<UserPreferencesProvider>();
    await prefs.setPreferredAudio(package.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${package.name} selected for listening')),
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
    final isPreferred = prefs.preferredAudioPackageId == package.id;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 14),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 16,
        vertical: compact ? 16 : 16,
      ),
      decoration: BoxDecoration(
        color: compact ? t.surface : t.surface,
        borderRadius: compact ? null : BorderRadius.circular(16),
        border: compact
            ? Border(bottom: BorderSide(color: t.border))
            : Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(package.name,
                    style: AppText.display(context, size: 17)),
              ),
              if (isPreferred)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldSoft.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.preferredAudio,
                    style: AppText.ui(
                      context,
                      size: 10,
                      w: FontWeight.w700,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
            ],
          ),
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
            '${l10n.quality}: ${package.quality} · ${l10n.duration}: ${package.durationLabel}'
            '${package.offlineDownload ? ' · Offline' : ''}',
            style: AppText.uiFaint(context),
          ),
          if (downloading && downloads.activePackageId == package.id) ...[
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
          if (downloads.error != null &&
              !downloading &&
              downloads.activePackageId == package.id) ...[
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
          else if (!package.offlineDownload)
            OutlinedButton(
              onPressed: () => _selectPreferred(context),
              child: Text(isPreferred ? l10n.preferredAudio : l10n.listen),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!installed)
                  ElevatedButton(
                    onPressed:
                        downloading ? null : () => _downloadFull(context),
                    child: Text(l10n.download),
                  )
                else ...[
                  OutlinedButton(
                    onPressed:
                        isPreferred ? null : () => _selectPreferred(context),
                    child: Text(l10n.preferredAudio),
                  ),
                  if (!downloading)
                    OutlinedButton(
                      onPressed: () => _downloadFull(context),
                      child: const Text('Update offline'),
                    ),
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
