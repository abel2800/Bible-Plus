import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_store_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';

/// Pick which audio narration to use while reading or listening.
class AudioVersionSelectorSheet extends StatelessWidget {
  const AudioVersionSelectorSheet({
    super.key,
    this.textVersionId,
    this.currentPackageId,
  });

  final String? textVersionId;
  final String? currentPackageId;

  static Future<void> show(
    BuildContext context, {
    String? textVersionId,
    String? currentPackageId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioVersionSelectorSheet(
        textVersionId: textVersionId,
        currentPackageId: currentPackageId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AudioStoreProvider>();
    final prefs = context.watch<UserPreferencesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    final packages = textVersionId == null
        ? store.catalog.where(store.canActivate).toList()
        : store.packagesForTextVersion(textVersionId!);

    final activeId = currentPackageId ?? prefs.preferredAudioPackageId;

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
              Text(
                'Choose audio version',
                style: AppTheme.brandTitle(
                  fontSize: 19,
                  weight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                textVersionId == null
                    ? 'Select the narration you want to hear.'
                    : 'Audio matched to your $textVersionId reading text.',
                style: AppTheme.ui(fontSize: 13, color: soft),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: packages.isEmpty ? 1 : packages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (packages.isEmpty) {
                      return Text(
                        'No audio available for this Bible version yet.',
                        style: AppTheme.ui(fontSize: 14, color: soft),
                      );
                    }
                    final pkg = packages[index];
                    final selected = activeId == pkg.id;
                    return Material(
                      color: isDark
                          ? AppTheme.surface2Dark
                          : AppTheme.surface2Light,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () async {
                          await prefs.setPreferredAudio(pkg.id);
                          if (context.mounted) Navigator.pop(context, pkg.id);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pkg.name,
                                      style: AppTheme.ui(
                                        fontSize: 15,
                                        weight: FontWeight.w600,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pkg.translation} · ${pkg.narrator}',
                                      style: AppTheme.ui(
                                          fontSize: 12, color: soft),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.gold,
                                ),
                            ],
                          ),
                        ),
                      ),
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
