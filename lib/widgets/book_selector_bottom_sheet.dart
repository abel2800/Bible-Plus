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
  int? _pickedBookId;

  @override
  void initState() {
    super.initState();
    final bible = context.read<BibleProvider>();
    _showOldTestament = bible.selectedBook?.testament != 'NT';
    if (widget.jumpToCurrentBook) {
      _pickedBookId = bible.selectedBook?.id;
    }
  }

  Future<void> _selectChapter(
    BuildContext context,
    BibleProvider bible,
    BibleBook book,
    int chapter,
  ) async {
    await bible.loadChapter(book.id, chapter);
    if (!context.mounted) return;

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
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final colors = BpReaderSheetColors(theme: readerTheme);
    final bible = context.watch<BibleProvider>();
    final currentBookId = bible.selectedBook?.id;
    final currentChapter = bible.selectedChapter;
    final activeBookId = _pickedBookId ?? currentBookId;

    bool matches(BibleBook b) =>
        b.name.toLowerCase().contains(_query.toLowerCase());

    final books = bible.books
        .where((b) => b.testament == (_showOldTestament ? 'OT' : 'NT'))
        .where(matches)
        .toList();

    BibleBook? activeBook;
    if (activeBookId != null) {
      for (final book in bible.books) {
        if (book.id == activeBookId) {
          activeBook = book;
          break;
        }
      }
    }

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
              hint: 'Search books or verses…',
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            BpReaderTogglePill(
              colors: colors,
              leftLabel: 'Old Testament',
              rightLabel: 'New Testament',
              leftSelected: _showOldTestament,
              onLeft: () => setState(() => _showOldTestament = true),
              onRight: () => setState(() => _showOldTestament = false),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
                childAspectRatio: 1.35,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final isCurrent = book.id == currentBookId;
                final isPicked = book.id == activeBookId;
                return Material(
                  color: colors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCurrent || isPicked
                          ? colors.gold
                          : colors.borderFlat,
                      width: isCurrent || isPicked ? 1.2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _pickedBookId = book.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          book.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.ui(
                            fontSize: 11,
                            weight:
                                isCurrent ? FontWeight.w600 : FontWeight.w500,
                            color: isCurrent ? colors.text1 : colors.text2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (activeBook != null) ...[
              BpReaderMiniLabel(
                colors: colors,
                label: '${activeBook.name} — chapters',
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.1,
                ),
                itemCount: activeBook.chapters,
                itemBuilder: (context, index) {
                  final chapter = index + 1;
                  final selected = activeBook!.id == currentBookId &&
                      chapter == currentChapter;
                  return Material(
                    color: selected ? colors.gold : colors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: selected ? colors.gold : colors.borderFlat,
                      ),
                    ),
                    child: InkWell(
                      onTap: () =>
                          _selectChapter(context, bible, activeBook!, chapter),
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: AppTheme.ui(
                            fontSize: 11,
                            weight: FontWeight.w700,
                            color: selected ? AppTheme.onGold : colors.text2,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
