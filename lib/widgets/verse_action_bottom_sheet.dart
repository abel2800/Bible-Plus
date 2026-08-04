import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_capabilities.dart';
import '../models/bible_verse.dart';
import '../providers/study_provider.dart';
import '../providers/hymn_provider.dart';
import '../services/cross_reference_service.dart';
import '../utils/app_theme.dart';
import 'design/bp_widgets.dart';

class VerseActionBottomSheet extends StatefulWidget {
  final BibleVerse verse;
  final String reference;
  final String versionId;

  const VerseActionBottomSheet({
    super.key,
    required this.verse,
    required this.reference,
    required this.versionId,
  });

  @override
  State<VerseActionBottomSheet> createState() => _VerseActionBottomSheetState();
}

class _VerseActionBottomSheetState extends State<VerseActionBottomSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _showNoteField = false;

  @override
  void initState() {
    super.initState();
    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    final existingNote = studyProvider.getNoteForVerse(
      widget.reference,
      versionId: widget.versionId,
    );
    if (existingNote != null) {
      _noteController.text = existingNote.text;
      _showNoteField = true;
    }
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareText() async {
    final text = '${widget.verse.text}\n— ${widget.reference}\n\nBiblePulse';
    final origin = _shareOrigin();
    try {
      await Share.share(
        text,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied — sharing isn’t available here',
            style: AppTheme.ui(color: Colors.white),
          ),
          backgroundColor: AppTheme.teal,
        ),
      );
    }
  }

  void _closeWithMessage(String message, {Color? background}) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.ui(color: Colors.white)),
        duration: const Duration(seconds: 2),
        backgroundColor: background ?? AppTheme.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = Provider.of<StudyProvider>(context);
    final isHighlighted = studyProvider.isHighlighted(
      widget.reference,
      versionId: widget.versionId,
    );
    final isBookmarked = studyProvider.isBookmarked(
      widget.reference,
      versionId: widget.versionId,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final inkSoft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final capabilities = context.watch<AppCapabilities>();
    final linkedHymns = capabilities.hymns
        ? context
            .watch<HymnProvider>()
            .hymns
            .where(
              (hymn) =>
                  hymn.scripture?.toLowerCase().contains(
                        widget.reference.toLowerCase(),
                      ) ??
                  false,
            )
            .toList()
        : const [];

    return Material(
      color: surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.reference,
                      style: AppTheme.brandTitle(
                        fontSize: 18,
                        weight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ),
                  BpIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold, width: 1.2),
                ),
                child: Text(
                  widget.verse.text,
                  style: AppTheme.scripture(
                    fontSize: 16,
                    height: 1.75,
                    style: FontStyle.italic,
                    color: ink,
                  ),
                ),
              ),
              if (linkedHymns.isNotEmpty) ...[
                const SizedBox(height: 20),
                const BpGroupHeader('Inspired hymns'),
                for (final hymn in linkedHymns)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.music_note_rounded,
                        color: AppTheme.teal),
                    title: Text(
                      hymn.title,
                      style: AppTheme.ui(
                          fontSize: 14, weight: FontWeight.w600, color: ink),
                    ),
                    subtitle: Text(
                      hymn.scripture ?? '',
                      style: AppTheme.ui(fontSize: 12, color: inkSoft),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              const BpGroupHeader('Highlight'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in AppTheme.highlightColors)
                    _HighlightSwatch(
                      color: color,
                      isSelected: studyProvider
                              .getHighlightColor(
                                widget.reference,
                                versionId: widget.versionId,
                              )
                              ?.toARGB32() ==
                          color.toARGB32(),
                      onTap: () async {
                        await studyProvider.addHighlight(
                          widget.reference,
                          widget.verse.text,
                          color,
                          versionId: widget.versionId,
                        );
                        if (!mounted) return;
                        _closeWithMessage('Verse highlighted',
                            background: color);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _ActionRow(
                icon: Icons.note_alt_outlined,
                label: 'Add note',
                color: AppTheme.teal,
                onTap: () => setState(() => _showNoteField = !_showNoteField),
              ),
              if (_showNoteField) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: AppTheme.scripture(fontSize: 15, color: ink),
                  decoration: InputDecoration(
                    hintText: 'Write your thoughts here…',
                    hintStyle: AppTheme.ui(fontSize: 13, color: inkSoft),
                    suffixIcon: IconButton(
                      icon:
                          const Icon(Icons.check_rounded, color: AppTheme.gold),
                      onPressed: () => _saveNote(context, studyProvider),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _ActionRow(
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                color: AppTheme.gold,
                onTap: () async {
                  if (isBookmarked) {
                    await studyProvider.removeBookmark(
                      widget.reference,
                      versionId: widget.versionId,
                    );
                    if (!mounted) return;
                    _closeWithMessage('Bookmark removed');
                  } else {
                    await studyProvider.addBookmark(
                      widget.reference,
                      widget.verse.text,
                      versionId: widget.versionId,
                    );
                    if (!mounted) return;
                    _closeWithMessage('Verse bookmarked');
                  }
                },
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.auto_awesome_outlined,
                label: 'Open in Verse Studio',
                color: AppTheme.gold,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pushNamed(
                    '/wallpaper',
                    arguments: {
                      'text': widget.verse.text,
                      'reference': widget.reference,
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy_rounded,
                label: 'Copy',
                color: inkSoft,
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: '${widget.verse.text}\n— ${widget.reference}',
                    ),
                  );
                  if (!mounted) return;
                  _closeWithMessage('Verse copied', background: AppTheme.teal);
                },
              ),
              if (isHighlighted) ...[
                const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.highlight_off_rounded,
                  label: 'Remove highlight',
                  color: AppTheme.vermilion,
                  labelColor: AppTheme.vermilion,
                  onTap: () async {
                    await studyProvider.removeHighlight(
                      widget.reference,
                      versionId: widget.versionId,
                    );
                    if (!mounted) return;
                    _closeWithMessage(
                      'Highlight removed',
                      background: AppTheme.vermilion,
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _shareText,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share text'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showCrossReferences(context),
                    icon: const Icon(Icons.account_tree_rounded, size: 18),
                    label: const Text('Cross-references'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNote(
    BuildContext context,
    StudyProvider studyProvider,
  ) async {
    if (_noteController.text.trim().isEmpty) return;
    await studyProvider.addNote(
      widget.reference,
      _noteController.text.trim(),
      versionId: widget.versionId,
    );
    if (!mounted) return;
    _closeWithMessage('Note saved');
  }

  Future<void> _showCrossReferences(BuildContext context) async {
    final references =
        CrossReferenceService().getCrossReferences(widget.reference);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cross-references · ${widget.reference}',
          style: AppTheme.brandTitle(
            fontSize: 17,
            weight: FontWeight.w600,
            color: isDark ? AppTheme.inkDark : AppTheme.ink,
          ),
        ),
        content: references.isEmpty
            ? Text(
                'No verified cross-references are available.',
                style: AppTheme.ui(
                  color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: references
                    .map(
                      (reference) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          reference.toReference,
                          style: AppTheme.ui(weight: FontWeight.w600),
                        ),
                        subtitle: Text(reference.description ?? ''),
                      ),
                    )
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

class _HighlightSwatch extends StatelessWidget {
  const _HighlightSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.gold : borderFor(context),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Color borderFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.borderDark : AppTheme.borderLight;
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = labelColor ?? (isDark ? AppTheme.inkDark : AppTheme.ink);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: AppTheme.ui(
                  fontSize: 14,
                  weight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
