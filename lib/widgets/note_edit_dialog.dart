import 'package:flutter/material.dart';

import '../models/note.dart';
import '../providers/study_provider.dart';
import '../utils/app_theme.dart';

class NoteEditDialog extends StatefulWidget {
  const NoteEditDialog({
    super.key,
    required this.note,
    required this.provider,
  });

  final Note note;
  final StudyProvider provider;

  @override
  State<NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<NoteEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.note.verseReference,
        style: AppTheme.brandTitle(fontSize: 17),
      ),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        style: AppTheme.scripture(fontSize: 15),
        decoration: const InputDecoration(
          hintText: 'Enter your note…',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (_controller.text.isNotEmpty) {
              final updatedNote = widget.note.copyWith(
                text: _controller.text,
                updatedAt: DateTime.now(),
              );
              await widget.provider.updateNote(updatedNote);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
