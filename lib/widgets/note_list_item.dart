import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../providers/study_provider.dart';
import '../utils/app_theme.dart';
import 'design/bp_widgets.dart';
import 'note_edit_dialog.dart';

class NoteListItem extends StatelessWidget {
  final Note note;

  const NoteListItem({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final studyProvider = Provider.of<StudyProvider>(context, listen: false);
    final dateFormat = DateFormat('MMM d, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final inkSoft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;

    return BpCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showEditDialog(context, studyProvider),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.teal.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.note_rounded,
                  color: AppTheme.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  note.verseReference,
                  style: AppTheme.brandTitle(
                    fontSize: 15,
                    weight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              BpIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete note',
                onPressed: () => _deleteNote(context, studyProvider),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note.text,
            style: AppTheme.scripture(
              fontSize: 15,
              height: 1.65,
              color: inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${dateFormat.format(note.updatedAt)}',
            style: AppTheme.ui(fontSize: 11, color: faint),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    StudyProvider provider,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => NoteEditDialog(
        note: note,
        provider: provider,
      ),
    );
  }

  Future<void> _deleteNote(
    BuildContext context,
    StudyProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Note',
          style: AppTheme.brandTitle(fontSize: 17),
        ),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.vermilion),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteNote(note.id);
    }
  }
}
