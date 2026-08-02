import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hymn.dart';
import '../providers/hymn_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class HymnsScreen extends StatefulWidget {
  const HymnsScreen({super.key});

  @override
  State<HymnsScreen> createState() => _HymnsScreenState();
}

class _HymnsScreenState extends State<HymnsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<HymnProvider>().loadHymns(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HymnProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    return Scaffold(
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
                  Text(
                    'Hymns',
                    style: AppTheme.brandTitle(fontSize: 22, color: ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch ((provider.isLoading, provider.hymns.isEmpty)) {
                (true, _) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold),
                  ),
                (false, true) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'No licensed hymn catalog is installed.',
                        textAlign: TextAlign.center,
                        style: AppTheme.scripture(
                          fontSize: 15,
                          height: 1.55,
                          color: soft,
                        ),
                      ),
                    ),
                  ),
                _ => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    itemCount: provider.hymns.length,
                    itemBuilder: (context, index) {
                      final hymn = provider.hymns[index];
                      final isFavorite = provider.isFavorite(hymn.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BpCard(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          onTap: () => _showHymn(context, hymn),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${hymn.number}. ${hymn.title}',
                                      style: AppTheme.brandTitle(
                                        fontSize: 15,
                                        weight: FontWeight.w600,
                                        color: ink,
                                      ),
                                    ),
                                    if (hymn.author != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        hymn.author!,
                                        style: AppTheme.ui(
                                          fontSize: 12,
                                          color: soft,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: isFavorite
                                    ? 'Remove favorite'
                                    : 'Add favorite',
                                onPressed: () =>
                                    provider.toggleFavorite(hymn.id),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite ? AppTheme.gold : soft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHymn(BuildContext context, Hymn hymn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          hymn.title,
          style: AppTheme.brandTitle(fontSize: 18, color: ink),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hymn.scripture != null) ...[
                BpPill(
                  icon: Icons.menu_book_rounded,
                  label: hymn.scripture!,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                hymn.fullText,
                style: AppTheme.scripture(
                  fontSize: 15,
                  height: 1.7,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTheme.ui(fontSize: 13, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
