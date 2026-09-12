import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bible_verse.dart';
import '../../providers/color_theme_provider.dart';
import '../../providers/study_provider.dart';
import '../../utils/app_theme.dart';
import 'bp_reader_sheet_chrome.dart';

class BpReaderNoteSheet extends StatefulWidget {
  const BpReaderNoteSheet({
    super.key,
    required this.verse,
    required this.reference,
    required this.versionId,
  });

  final BibleVerse verse;
  final String reference;
  final String versionId;

  static Future<void> show(
    BuildContext context, {
    required BibleVerse verse,
    required String reference,
    required String versionId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BpReaderNoteSheet(
        verse: verse,
        reference: reference,
        versionId: versionId,
      ),
    );
  }

  @override
  State<BpReaderNoteSheet> createState() => _BpReaderNoteSheetState();
}

class _BpReaderNoteSheetState extends State<BpReaderNoteSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final study = context.read<StudyProvider>();
    final existing = study.getNoteForVerse(
      widget.reference,
      versionId: widget.versionId,
    );
    _controller = TextEditingController(text: existing?.text ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(StudyProvider study) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    await study.addNote(
      widget.reference,
      text,
      versionId: widget.versionId,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = context.watch<ColorThemeProvider>().currentTheme;
    final colors = BpReaderSheetColors(theme: readerTheme);
    final study = context.watch<StudyProvider>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BpReaderSheetContainer(
        colors: colors,
        title: 'Add Note',
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.reference.toUpperCase(),
                style: AppTheme.ui(
                  fontSize: 11,
                  weight: FontWeight.w600,
                  color: colors.gold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: colors.gold.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  widget.verse.text,
                  style: AppTheme.scripture(
                    fontSize: 13.5,
                    height: 1.5,
                    color: colors.text2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 4,
                style: AppTheme.ui(fontSize: 13, color: colors.text1),
                decoration: InputDecoration(
                  hintText: 'Write what this verse means to you…',
                  hintStyle: AppTheme.ui(fontSize: 13, color: colors.text2),
                  filled: true,
                  fillColor: colors.card,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderFlat),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderFlat),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saving ? null : () => _save(study),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          readerTheme.isDark
                              ? AppTheme.goldBright
                              : AppTheme.goldBrightLight,
                          colors.gold,
                        ],
                      ),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.onGold,
                              ),
                            )
                          : Text(
                              'Save note',
                              style: AppTheme.ui(
                                fontSize: 13,
                                weight: FontWeight.w700,
                                color: AppTheme.onGold,
                              ),
                            ),
                    ),
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
