import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/bible_verse.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

enum _TestamentFilter { all, ot, nt }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  _TestamentFilter _filter = _TestamentFilter.all;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<BibleVerse> _filteredResults(List<BibleVerse> results) {
    switch (_filter) {
      case _TestamentFilter.ot:
        return results.where((v) => v.book <= 39).toList();
      case _TestamentFilter.nt:
        return results.where((v) => v.book > 39).toList();
      case _TestamentFilter.all:
        return results;
    }
  }

  void _search(BibleProvider bibleProvider) {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _query = value);
    bibleProvider.searchVerses(value);
  }

  @override
  Widget build(BuildContext context) {
    final bibleProvider = Provider.of<BibleProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final results = _filteredResults(bibleProvider.searchResults);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Search',
                    style: AppTheme.brandTitle(fontSize: 22, color: ink),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BpCard(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                child: TextField(
                  controller: _controller,
                  style: AppTheme.ui(fontSize: 14, color: ink),
                  decoration: InputDecoration(
                    hintText: 'Search Scripture…',
                    hintStyle: AppTheme.ui(fontSize: 14, color: faint),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: soft, size: 20),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      icon: Icon(Icons.arrow_forward_rounded,
                          color: soft, size: 20),
                      onPressed: () => _search(bibleProvider),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(bibleProvider),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == _TestamentFilter.all,
                    onTap: () => setState(() => _filter = _TestamentFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'OT',
                    selected: _filter == _TestamentFilter.ot,
                    onTap: () => setState(() => _filter = _TestamentFilter.ot),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'NT',
                    selected: _filter == _TestamentFilter.nt,
                    onTap: () => setState(() => _filter = _TestamentFilter.nt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: bibleProvider.isSearching
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Searching Scripture…\nFirst search may take a moment.',
                            textAlign: TextAlign.center,
                            style: AppTheme.ui(fontSize: 13, color: faint),
                          ),
                        ],
                      ),
                    )
                  : _query.isEmpty
                      ? Center(
                          child: Text(
                            'Enter a word or phrase, then tap search',
                            style: AppTheme.ui(fontSize: 13, color: faint),
                          ),
                        )
                      : results.isEmpty
                          ? Center(
                              child: Text(
                                'No results for “$_query”',
                                style: AppTheme.ui(fontSize: 13, color: faint),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final verse = results[index];
                                final reference =
                                    bibleProvider.getVerseReference(verse);
                                return BpCard(
                                  padding: const EdgeInsets.all(14),
                                  onTap: () async {
                                    final navigation =
                                        context.read<NavigationProvider>();
                                    final navigator = Navigator.of(context);
                                    await bibleProvider.goToVerse(
                                      verse.book,
                                      verse.chapter,
                                      verse.verse,
                                    );
                                    if (!context.mounted) return;
                                    navigation.setIndex(1);

                                    if (navigator.canPop()) {
                                      navigator.pop();
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reference.toUpperCase(),
                                        style: AppTheme.ui(
                                          fontSize: 11,
                                          weight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: AppTheme.gold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _HighlightedText(
                                        text: verse.text,
                                        query: _query,
                                        style: AppTheme.scripture(
                                          fontSize: 15,
                                          height: 1.65,
                                          color: ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BpPill(label: label, filled: selected),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
  });

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + lowerQuery.length),
          style: style.copyWith(
            backgroundColor: AppTheme.gold.withValues(alpha: 0.35),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      start = index + lowerQuery.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
