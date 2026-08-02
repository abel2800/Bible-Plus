import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bible_book.dart';
import '../providers/bible_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

Future<void> showBookSelector(
  BuildContext context, {
  bool jumpToCurrentBook = true,
  bool forcePlayAudio = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BookSelectorBottomSheet(
      jumpToCurrentBook: jumpToCurrentBook,
      forcePlayAudio: forcePlayAudio,
    ),
  );
}

class BookSelectorBottomSheet extends StatefulWidget {
  const BookSelectorBottomSheet({
    super.key,
    this.jumpToCurrentBook = true,
    this.forcePlayAudio = false,
  });

  final bool jumpToCurrentBook;
  final bool forcePlayAudio;

  @override
  State<BookSelectorBottomSheet> createState() =>
      _BookSelectorBottomSheetState();
}

class _BookSelectorBottomSheetState extends State<BookSelectorBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _query = '';
  int? _expandedBookId;

  @override
  void initState() {
    super.initState();
    final bible = context.read<BibleProvider>();
    final currentTestament = bible.selectedBook?.testament;
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: currentTestament == 'NT' ? 1 : 0,
    );
    if (widget.jumpToCurrentBook) {
      _expandedBookId = bible.selectedBook?.id;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _toggle(int bookId) {
    setState(() => _expandedBookId = _expandedBookId == bookId ? null : bookId);
  }

  Future<void> _selectChapter(
    BuildContext context,
    BibleProvider bible,
    BibleBook book,
    int chapter,
  ) async {
    await bible.loadChapter(book.id, chapter);
    if (!context.mounted) return;

    // Only start/change audio when opened from the audio player picker.
    if (widget.forcePlayAudio) {
      final audio = context.read<AudioService>();
      if (audio.enabled) {
        await audio.playChapter(
          bible.currentVersion,
          book.id,
          chapter,
          bookName: book.name,
          bookChapterCount: book.chapters,
          bookCatalog: [
            for (final b in bible.books)
              (id: b.id, name: b.name, chapters: b.chapters),
          ],
        );
      }
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    final bible = context.watch<BibleProvider>();
    final currentBookId = bible.selectedBook?.id;

    bool matches(BibleBook b) =>
        b.name.toLowerCase().contains(_query.toLowerCase());

    final ot =
        bible.books.where((b) => b.testament == 'OT').where(matches).toList();
    final nt =
        bible.books.where((b) => b.testament == 'NT').where(matches).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: AppText.ui(context),
                decoration: const InputDecoration(
                  hintText: 'Search books…',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                ),
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: AppBrand.gold,
              unselectedLabelColor: t.inkFaint,
              indicatorColor: AppBrand.gold,
              labelStyle: AppText.ui(context, size: 13, w: FontWeight.w700),
              tabs: const [
                Tab(text: 'Old Testament'),
                Tab(text: 'New Testament'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _BookChapterList(
                    books: ot,
                    currentBookId: currentBookId,
                    currentChapter: bible.selectedChapter,
                    expandedBookId: _expandedBookId,
                    scrollController: scrollController,
                    onToggle: _toggle,
                    onSelectChapter: (book, chapter) =>
                        _selectChapter(context, bible, book, chapter),
                  ),
                  _BookChapterList(
                    books: nt,
                    currentBookId: currentBookId,
                    currentChapter: bible.selectedChapter,
                    expandedBookId: _expandedBookId,
                    scrollController: scrollController,
                    onToggle: _toggle,
                    onSelectChapter: (book, chapter) =>
                        _selectChapter(context, bible, book, chapter),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookChapterList extends StatelessWidget {
  final List<BibleBook> books;
  final int? currentBookId;
  final int currentChapter;
  final int? expandedBookId;
  final ScrollController scrollController;
  final void Function(int bookId) onToggle;
  final Future<void> Function(BibleBook book, int chapter) onSelectChapter;

  const _BookChapterList({
    required this.books,
    required this.currentBookId,
    required this.currentChapter,
    required this.expandedBookId,
    required this.scrollController,
    required this.onToggle,
    required this.onSelectChapter,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.colors;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        final isCurrent = book.id == currentBookId;
        final isExpanded = book.id == expandedBookId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isExpanded ? t.surface2 : t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? AppBrand.gold : t.border,
              width: isCurrent ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onToggle(book.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          book.name,
                          style: AppText.ui(
                            context,
                            size: 15,
                            w: isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: isCurrent ? AppBrand.gold : t.ink,
                          ),
                        ),
                      ),
                      Text(
                        '${book.chapters} ch',
                        style: AppText.ui(context, size: 12, color: t.inkFaint),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: t.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: book.chapters,
                    itemBuilder: (context, ci) {
                      final chapter = ci + 1;
                      final selected = isCurrent && chapter == currentChapter;
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onSelectChapter(book, chapter),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppBrand.gold : t.appBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? AppBrand.gold : t.border,
                            ),
                          ),
                          child: Text(
                            '$chapter',
                            style: AppText.ui(
                              context,
                              size: 12.5,
                              w: FontWeight.w700,
                              color: selected ? AppBrand.onGold : t.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                secondChild: const SizedBox(width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }
}
