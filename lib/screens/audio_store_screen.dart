import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_capabilities.dart';
import '../l10n/app_localizations.dart';
import '../providers/audio_store_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/audio_package_card.dart';

class AudioStoreScreen extends StatelessWidget {
  const AudioStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = context.watch<AudioStoreProvider>();
    final capabilities = context.watch<AppCapabilities>();

    return Scaffold(
      backgroundColor: context.colors.appBg,
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
                        color: context.colors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Text(
                        l10n.audioSetupNote,
                        style: AppText.ui(
                          context,
                          size: 13,
                          color: context.colors.inkSoft,
                        ),
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
                      return AudioPackageCard(
                        package: store.visiblePackages[index],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
