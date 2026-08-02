import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/note.dart';
import '../models/engagement.dart';
import '../services/database_service.dart';
import '../services/study_sync_service.dart';

class StudyProvider with ChangeNotifier {
  StudyProvider() {
    loadAll();
  }

  final DatabaseService _database = DatabaseService();
  final Uuid _uuid = const Uuid();
  List<Highlight> _highlights = [];
  List<Note> _notes = [];
  List<Bookmark> _bookmarks = [];
  List<SyncRecord> _tombstones = [];

  List<Highlight> get highlights => List.unmodifiable(_highlights);
  List<Note> get notes => List.unmodifiable(_notes);
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  bool get _usesSqlite =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> loadAll() async {
    if (_usesSqlite) {
      final values = await Future.wait([
        _database.getHighlights(),
        _database.getNotes(),
        _database.getBookmarks(),
      ]);
      _highlights = values[0] as List<Highlight>;
      _notes = values[1] as List<Note>;
      _bookmarks = values[2] as List<Bookmark>;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _highlights = _decode(
        prefs.getString('study_highlights'),
        Highlight.fromJson,
      );
      _notes = _decode(prefs.getString('study_notes'), Note.fromJson);
      _bookmarks = _decode(
        prefs.getString('study_bookmarks'),
        Bookmark.fromJson,
      );
      _tombstones = _decode(
        prefs.getString('study_sync_tombstones'),
        SyncRecord.fromJson,
      );
    }
    notifyListeners();
  }

  Future<void> addHighlight(
    String verseReference,
    String text,
    Color color,
  ) async {
    final item = Highlight(
      id: _uuid.v4(),
      verseReference: verseReference,
      text: text,
      color: color.toARGB32(),
      createdAt: DateTime.now().toUtc(),
    );
    if (_usesSqlite) {
      await _database.deleteHighlight(verseReference);
      await _database.insertHighlight(item);
      _highlights = await _database.getHighlights();
    } else {
      _highlights
          .removeWhere((value) => value.verseReference == verseReference);
      _highlights.add(item);
      await _saveFallback();
    }
    notifyListeners();
  }

  Future<void> removeHighlight(String verseReference) async {
    if (_usesSqlite) {
      await _database.deleteHighlight(verseReference);
      _highlights = await _database.getHighlights();
    } else {
      final existing = _highlights.where(
        (value) => value.verseReference == verseReference,
      );
      _addTombstones('highlight', existing.map((value) => value.toJson()));
      _highlights
          .removeWhere((value) => value.verseReference == verseReference);
      await _saveFallback();
    }
    notifyListeners();
  }

  Future<void> addNote(String verseReference, String text) async {
    final existing = getNoteForVerse(verseReference);
    if (existing != null) {
      await updateNote(
        existing.copyWith(text: text, updatedAt: DateTime.now().toUtc()),
      );
      return;
    }
    final item = Note(
      id: _uuid.v4(),
      verseReference: verseReference,
      text: text,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    if (_usesSqlite) {
      await _database.insertNote(item);
      _notes = await _database.getNotes();
    } else {
      _notes.add(item);
      await _saveFallback();
    }
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    if (_usesSqlite) {
      await _database.updateNote(note);
      _notes = await _database.getNotes();
    } else {
      final index = _notes.indexWhere((value) => value.id == note.id);
      if (index == -1) return;
      _notes[index] = note;
      await _saveFallback();
    }
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    if (_usesSqlite) {
      await _database.deleteNote(id);
      _notes = await _database.getNotes();
    } else {
      final existing = _notes.where((value) => value.id == id);
      _addTombstones('note', existing.map((value) => value.toJson()));
      _notes.removeWhere((value) => value.id == id);
      await _saveFallback();
    }
    notifyListeners();
  }

  Future<void> addBookmark(String verseReference, String text) async {
    if (isBookmarked(verseReference)) return;
    final item = Bookmark(
      id: _uuid.v4(),
      verseReference: verseReference,
      text: text,
      createdAt: DateTime.now().toUtc(),
    );
    if (_usesSqlite) {
      await _database.insertBookmark(item);
      _bookmarks = await _database.getBookmarks();
    } else {
      _bookmarks.add(item);
      await _saveFallback();
    }
    notifyListeners();
  }

  Future<void> removeBookmark(String verseReference) async {
    if (_usesSqlite) {
      await _database.deleteBookmark(verseReference);
      _bookmarks = await _database.getBookmarks();
    } else {
      final existing = _bookmarks.where(
        (value) => value.verseReference == verseReference,
      );
      _addTombstones('bookmark', existing.map((value) => value.toJson()));
      _bookmarks.removeWhere((value) => value.verseReference == verseReference);
      await _saveFallback();
    }
    notifyListeners();
  }

  bool isHighlighted(String reference) =>
      _highlights.any((value) => value.verseReference == reference);

  Color? getHighlightColor(String reference) {
    final index =
        _highlights.indexWhere((value) => value.verseReference == reference);
    return index == -1 ? null : Color(_highlights[index].color);
  }

  bool isBookmarked(String reference) =>
      _bookmarks.any((value) => value.verseReference == reference);

  Note? getNoteForVerse(String reference) {
    final index =
        _notes.indexWhere((value) => value.verseReference == reference);
    return index == -1 ? null : _notes[index];
  }

  List<StudyMemory> onThisDay([DateTime? value]) {
    final today = value ?? DateTime.now();
    final memories = <StudyMemory>[
      ..._highlights
          .where(
            (item) =>
                item.createdAt.year < today.year &&
                item.createdAt.month == today.month &&
                item.createdAt.day == today.day,
          )
          .map(
            (item) => StudyMemory(
              kind: 'Highlight',
              reference: item.verseReference,
              text: item.text,
              createdAt: item.createdAt,
            ),
          ),
      ..._notes
          .where(
            (item) =>
                item.createdAt.year < today.year &&
                item.createdAt.month == today.month &&
                item.createdAt.day == today.day,
          )
          .map(
            (item) => StudyMemory(
              kind: 'Note',
              reference: item.verseReference,
              text: item.text,
              createdAt: item.createdAt,
            ),
          ),
    ];
    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return memories;
  }

  Future<void> synchronize(StudySyncGateway gateway, String userId) async {
    final highlights =
        _usesSqlite ? await _database.getHighlightsForSync() : _highlights;
    final notes = _usesSqlite ? await _database.getNotesForSync() : _notes;
    final bookmarks =
        _usesSqlite ? await _database.getBookmarksForSync() : _bookmarks;
    final local = <SyncRecord>[
      ...highlights.map(
        (item) => SyncRecord(
          kind: 'highlight',
          id: item.id,
          updatedAt: item.updatedAt,
          deletedAt: item.deletedAt,
          data: {...item.toJson(), 'ownerId': userId},
        ),
      ),
      ...notes.map(
        (item) => SyncRecord(
          kind: 'note',
          id: item.id,
          updatedAt: item.updatedAt,
          deletedAt: item.deletedAt,
          data: {...item.toJson(), 'ownerId': userId},
        ),
      ),
      ...bookmarks.map(
        (item) => SyncRecord(
          kind: 'bookmark',
          id: item.id,
          updatedAt: item.updatedAt,
          deletedAt: item.deletedAt,
          data: {...item.toJson(), 'ownerId': userId},
        ),
      ),
      if (!_usesSqlite) ..._tombstones,
    ];
    final merged = await gateway.synchronize(userId, local);
    for (final record in merged) {
      final data = {...record.data, 'ownerId': userId};
      if (record.kind == 'highlight') {
        final item = Highlight.fromJson(data);
        if (record.deletedAt != null) {
          await removeHighlight(item.verseReference);
        } else if (!_highlights.any(
          (local) =>
              local.id == item.id && local.updatedAt.isAfter(item.updatedAt),
        )) {
          if (_usesSqlite) {
            await _database.deleteHighlight(item.verseReference);
            await _database.insertHighlight(item);
          } else {
            _highlights.removeWhere(
              (local) => local.verseReference == item.verseReference,
            );
            _highlights.add(item);
          }
        }
      } else if (record.kind == 'note') {
        final item = Note.fromJson(data);
        if (record.deletedAt != null) {
          await deleteNote(item.id);
        } else if (!_notes.any(
          (local) =>
              local.id == item.id && local.updatedAt.isAfter(item.updatedAt),
        )) {
          if (_usesSqlite) {
            await _database.insertNote(item);
          } else {
            _notes.removeWhere((local) => local.id == item.id);
            _notes.add(item);
          }
        }
      } else if (record.kind == 'bookmark') {
        final item = Bookmark.fromJson(data);
        if (record.deletedAt != null) {
          await removeBookmark(item.verseReference);
        } else if (!_bookmarks.any(
          (local) =>
              local.id == item.id && local.updatedAt.isAfter(item.updatedAt),
        )) {
          if (_usesSqlite) {
            await _database.deleteBookmark(item.verseReference);
            await _database.insertBookmark(item);
          } else {
            _bookmarks.removeWhere(
              (local) => local.verseReference == item.verseReference,
            );
            _bookmarks.add(item);
          }
        }
      }
    }
    if (_usesSqlite) {
      await loadAll();
    } else {
      await _saveFallback();
      notifyListeners();
    }
  }

  void _addTombstones(
    String kind,
    Iterable<Map<String, dynamic>> values,
  ) {
    final deletedAt = DateTime.now().toUtc();
    for (final data in values) {
      _tombstones.removeWhere(
        (record) => record.kind == kind && record.id == data['id'],
      );
      _tombstones.add(
        SyncRecord(
          kind: kind,
          id: data['id'] as String,
          updatedAt: deletedAt,
          deletedAt: deletedAt,
          data: {...data, 'deletedAt': deletedAt.toIso8601String()},
        ),
      );
    }
  }

  List<T> _decode<T>(
    String? source,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (source == null) return [];
    try {
      return (jsonDecode(source) as List<dynamic>)
          .map((value) => fromJson(value as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveFallback() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(
        'study_highlights',
        jsonEncode(_highlights.map((value) => value.toJson()).toList()),
      ),
      prefs.setString(
        'study_sync_tombstones',
        jsonEncode(
          _tombstones
              .map((value) => value.toJson('guest'))
              .toList(growable: false),
        ),
      ),
      prefs.setString(
        'study_notes',
        jsonEncode(_notes.map((value) => value.toJson()).toList()),
      ),
      prefs.setString(
        'study_bookmarks',
        jsonEncode(_bookmarks.map((value) => value.toJson()).toList()),
      ),
    ]);
  }
}
