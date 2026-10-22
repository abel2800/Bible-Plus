import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bible_book.dart';
import '../providers/bible_provider.dart';
import '../providers/color_theme_provider.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';
import 'design/bp_reader_sheet_chrome.dart';

Future<void> showBookSelector(
  BuildContext context, {
  bool jumpToCurrentBook = true,
  bool forcePlayAudio = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

class _BookSelectorBottomSheetState extends State<BookSelectorBottomSheet> {
  String _query = '';
  bool _showOldTestament = true;
  int? _expandedBookId;

  @override
  void initState() {
    super.initState();
    final bible = context.read<BibleProvider>();
    final currentTestament =
        widget.jumpToCurrentBook ? bible.selectedBook?.testament ?? 'OT' : 'OT';
    _showOldTestament = currentTestament.toUpperCase() != 'NT';
    _expandedBookId = null;
  }

  Future<void> _selectChapter(
    BuildContext context,
    BibleProvider bible,
    BibleBook book,
    int chapter,
  ) async {
    final loaded = await bible.loadChapter(book.id, chapter);
    if (!context.mounted) return;
    if (!loaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bible.chapterError ?? 'This chapter is unavailable.'),
        ),
      );
      return;
    }

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
            for (final item in bible.books)
              (id: item.id, name: item.name, chapters: item.chapters),
          ],
        );
      }
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final colors = BpReaderSheetColors(theme: readerTheme);
    final bible = context.watch<BibleProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final bookColumns = width < 350 ? 3 : 4;
    final chapterColumns = width < 340
        ? 4
        : width < 420
            ? 5
            : 6;
    final currentBookId = bible.selectedBook?.id;
    final currentChapter = bible.selectedChapter;
    final normalizedQuery = _query.trim().toLowerCase();
    final books = bible.books
        .where((book) =>
            book.testament.toUpperCase() == (_showOldTestament ? 'OT' : 'NT'))
        .where((book) => book.name.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
    final match = books.where((book) => book.id == _expandedBookId);
    final expandedBook = match.isEmpty ? null : match.first;

    return BpReaderSheetContainer(
      colors: colors,
      title: 'Books & Chapters',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BpReaderSearchInput(
              colors: colors,
              hint: 'Search books…',
              onChanged: (value) => setState(() {
                _query = value;
                if (expandedBook != null &&
                    !expandedBook.name
                        .toLowerCase()
                        .contains(value.trim().toLowerCase())) {
                  _expandedBookId = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            _TestamentSwitch(
              showOldTestament: _showOldTestament,
              colors: colors,
              onChanged: (showOldTestament) => setState(() {
                _showOldTestament = showOldTestament;
                _expandedBookId = null;
              }),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileSize =
                    (constraints.maxWidth - (bookColumns - 1) * 8) /
                        bookColumns;
                final rows = <Widget>[];
                for (var start = 0;
                    start < books.length;
                    start += bookColumns) {
                  final end = (start + bookColumns < books.length)
                      ? start + bookColumns
                      : books.length;
                  final rowBooks = books.sublist(start, end);
                  rows.add(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var column = 0;
                            column < bookColumns;
                            column++) ...[
                          if (column > 0) const SizedBox(width: 8),
                          SizedBox.square(
                            dimension: tileSize,
                            child: column < rowBooks.length
                                ? _BookTile(
                                    book: rowBooks[column],
                                    selected:
                                        rowBooks[column].id == currentBookId,
                                    expanded:
                                        rowBooks[column].id == _expandedBookId,
                                    colors: colors,
                                    onTap: () => setState(() {
                                      final tappedId = rowBooks[column].id;
                                      _expandedBookId =
                                          tappedId == _expandedBookId
                                              ? null
                                              : tappedId;
                                    }),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  );

                  if (expandedBook != null &&
                      rowBooks.any((book) => book.id == expandedBook.id)) {
                    rows.add(
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: _ChapterDropdown(
                          book: expandedBook,
                          selectedChapter: expandedBook.id == currentBookId
                              ? currentChapter
                              : null,
                          chapterColumns: chapterColumns,
                          colors: colors,
                          onChapterTap: (chapter) => _selectChapter(
                            context,
                            bible,
                            expandedBook,
                            chapter,
                          ),
                        ),
                      ),
                    );
                  } else {
                    rows.add(const SizedBox(height: 8));
                  }
                }
                return Column(children: rows);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TestamentSwitch extends StatelessWidget {
  const _TestamentSwitch({
    required this.showOldTestament,
    required this.colors,
    required this.onChanged,
  });

  final bool showOldTestament;
  final BpReaderSheetColors colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.borderFlat),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TestamentButton(
              label: 'Old Testament',
              selected: showOldTestament,
              colors: colors,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TestamentButton(
              label: 'New Testament',
              selected: !showOldTestament,
              colors: colors,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestamentButton extends StatelessWidget {
  const _TestamentButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final BpReaderSheetColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: AppTheme.ui(
                fontSize: 12,
                weight: FontWeight.w600,
                color: selected ? AppTheme.onGold : colors.text2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.selected,
    required this.expanded,
    required this.colors,
    required this.onTap,
  });

  final BibleBook book;
  final bool selected;
  final bool expanded;
  final BpReaderSheetColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: expanded ? colors.gold.withValues(alpha: 0.18) : colors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: expanded || selected ? colors.gold : colors.borderFlat,
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right_rounded,
                  size: 16,
                  color: expanded || selected ? colors.gold : colors.text3,
                ),
              ),
              Center(
                child: Text(
                  book.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(
                    fontSize: 11.5,
                    weight: selected || expanded
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: selected || expanded ? colors.text1 : colors.text2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterDropdown extends StatelessWidget {
  const _ChapterDropdown({
    required this.book,
    required this.selectedChapter,
    required this.chapterColumns,
    required this.colors,
    required this.onChapterTap,
  });

  final BibleBook book;
  final int? selectedChapter;
  final int chapterColumns;
  final BpReaderSheetColors colors;
  final ValueChanged<int> onChapterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderFlat),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${book.name} chapters',
            style: AppTheme.ui(
              fontSize: 12,
              weight: FontWeight.w600,
              color: colors.text1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var chapter = 1; chapter <= book.chapters; chapter++)
                SizedBox(
                  width: chapterColumns >= 6 ? 44 : 48,
                  height: 46,
                  child: Material(
                    color: chapter == selectedChapter
                        ? colors.gold.withValues(alpha: 0.22)
                        : colors.sheetBg,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => onChapterTap(chapter),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: AppTheme.ui(
                            fontSize: 13,
                            weight: chapter == selectedChapter
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: colors.text1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
