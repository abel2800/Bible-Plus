import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/highlight.dart';
import '../models/note.dart';
import '../models/bookmark.dart';
import '../models/bible_verse.dart';
import '../models/reading_plan.dart';
import '../models/audio_download.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database not available on web');
    }

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'bible_pulse.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE highlights (
        id TEXT PRIMARY KEY,
        verseReference TEXT NOT NULL,
        text TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        ownerId TEXT NOT NULL DEFAULT 'guest',
        versionId TEXT NOT NULL DEFAULT 'WEB',
        canonicalVerseId TEXT,
        syncVersion INTEGER NOT NULL DEFAULT 0,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        verseReference TEXT NOT NULL,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        ownerId TEXT NOT NULL DEFAULT 'guest',
        versionId TEXT NOT NULL DEFAULT 'WEB',
        canonicalVerseId TEXT,
        syncVersion INTEGER NOT NULL DEFAULT 0,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        verseReference TEXT NOT NULL,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        ownerId TEXT NOT NULL DEFAULT 'guest',
        versionId TEXT NOT NULL DEFAULT 'WEB',
        canonicalVerseId TEXT,
        syncVersion INTEGER NOT NULL DEFAULT 0,
        deletedAt TEXT
      )
    ''');

    await _createVersion2Tables(db);
    await _createVersion4Tables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createVersion2Tables(db);
    }
    if (oldVersion < 3) {
      for (final statement in version3MigrationStatements) {
        await db.execute(statement);
      }
    }
    if (oldVersion < 4) {
      await _createVersion4Tables(db);
    }
  }

  static const version3MigrationStatements = <String>[
    "ALTER TABLE highlights ADD COLUMN updatedAt TEXT NOT NULL DEFAULT '1970-01-01T00:00:00.000Z'",
    "ALTER TABLE highlights ADD COLUMN ownerId TEXT NOT NULL DEFAULT 'guest'",
    "ALTER TABLE highlights ADD COLUMN versionId TEXT NOT NULL DEFAULT 'WEB'",
    'ALTER TABLE highlights ADD COLUMN canonicalVerseId TEXT',
    'ALTER TABLE highlights ADD COLUMN syncVersion INTEGER NOT NULL DEFAULT 0',
    'ALTER TABLE highlights ADD COLUMN deletedAt TEXT',
    "ALTER TABLE notes ADD COLUMN ownerId TEXT NOT NULL DEFAULT 'guest'",
    "ALTER TABLE notes ADD COLUMN versionId TEXT NOT NULL DEFAULT 'WEB'",
    'ALTER TABLE notes ADD COLUMN canonicalVerseId TEXT',
    'ALTER TABLE notes ADD COLUMN syncVersion INTEGER NOT NULL DEFAULT 0',
    'ALTER TABLE notes ADD COLUMN deletedAt TEXT',
    "ALTER TABLE bookmarks ADD COLUMN updatedAt TEXT NOT NULL DEFAULT '1970-01-01T00:00:00.000Z'",
    "ALTER TABLE bookmarks ADD COLUMN ownerId TEXT NOT NULL DEFAULT 'guest'",
    "ALTER TABLE bookmarks ADD COLUMN versionId TEXT NOT NULL DEFAULT 'WEB'",
    'ALTER TABLE bookmarks ADD COLUMN canonicalVerseId TEXT',
    'ALTER TABLE bookmarks ADD COLUMN syncVersion INTEGER NOT NULL DEFAULT 0',
    'ALTER TABLE bookmarks ADD COLUMN deletedAt TEXT',
    'UPDATE highlights SET updatedAt = createdAt WHERE updatedAt LIKE \'1970-%\'',
    'UPDATE bookmarks SET updatedAt = createdAt WHERE updatedAt LIKE \'1970-%\'',
  ];

  Future<void> _createVersion2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bible_verses (
        versionId TEXT NOT NULL,
        bookId INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (versionId, bookId, chapter, verse)
      )
    ''');
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS bible_verses_fts USING fts5(
        text,
        versionId UNINDEXED,
        bookId UNINDEXED,
        chapter UNINDEXED,
        verse UNINDEXED,
        tokenize = 'unicode61'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_reading_plans (
        id TEXT PRIMARY KEY,
        planId TEXT NOT NULL,
        startDate TEXT NOT NULL,
        currentDay INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        completedDate TEXT,
        daysCompleted TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createVersion4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audio_downloads (
        versionId TEXT NOT NULL,
        filesetId TEXT NOT NULL,
        bookId INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        localPath TEXT NOT NULL,
        downloadedAt TEXT NOT NULL,
        fileSize INTEGER NOT NULL,
        sha256 TEXT,
        PRIMARY KEY (versionId, bookId, chapter)
      )
    ''');
  }

  Future<bool> hasBibleIndex(String versionId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM bible_verses WHERE versionId = ?',
      [versionId],
    );
    return (result.first['count'] as int? ?? 0) > 0;
  }

  Future<void> replaceBibleIndex(
    String versionId,
    List<BibleVerse> verses,
  ) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'bible_verses',
        where: 'versionId = ?',
        whereArgs: [versionId],
      );
      await transaction.delete(
        'bible_verses_fts',
        where: 'versionId = ?',
        whereArgs: [versionId],
      );

      final batch = transaction.batch();
      for (final verse in verses) {
        final values = {
          'versionId': versionId,
          'bookId': verse.book,
          'chapter': verse.chapter,
          'verse': verse.verse,
          'text': verse.text,
        };
        batch.insert('bible_verses', values);
        batch.insert('bible_verses_fts', values);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<BibleVerse>> searchBible(
    String versionId,
    String query, {
    int limit = 100,
  }) async {
    final tokens = RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(query)
        .map((match) => match.group(0)!)
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return [];

    final expression = tokens
        .map((token) => '"${token.replaceAll('"', '""')}"*')
        .join(' AND ');
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT bookId, chapter, verse, text
      FROM bible_verses_fts
      WHERE bible_verses_fts MATCH ? AND versionId = ?
      ORDER BY bookId, chapter, verse
      LIMIT ?
      ''',
      [expression, versionId, limit],
    );
    return rows
        .map(
          (row) => BibleVerse(
            id: row['verse'] as int,
            book: row['bookId'] as int,
            chapter: row['chapter'] as int,
            verse: row['verse'] as int,
            text: row['text'] as String,
          ),
        )
        .toList();
  }

  Future<void> insertHighlight(Highlight highlight) async {
    final db = await database;
    await db.insert(
      'highlights',
      highlight.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Highlight>> getHighlights() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'highlights',
      where: 'deletedAt IS NULL',
    );
    return List.generate(maps.length, (i) => Highlight.fromJson(maps[i]));
  }

  Future<List<Highlight>> getHighlightsForSync() async {
    final db = await database;
    final maps = await db.query('highlights');
    return maps.map(Highlight.fromJson).toList(growable: false);
  }

  Future<void> deleteHighlight(String verseReference) async {
    final db = await database;
    await db.update(
      'highlights',
      {
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'verseReference = ?',
      whereArgs: [verseReference],
    );
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toJson(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'deletedAt IS NULL',
    );
    return List.generate(maps.length, (i) => Note.fromJson(maps[i]));
  }

  Future<List<Note>> getNotesForSync() async {
    final db = await database;
    final maps = await db.query('notes');
    return maps.map(Note.fromJson).toList(growable: false);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    await db.insert(
      'bookmarks',
      bookmark.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Bookmark>> getBookmarks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'deletedAt IS NULL',
    );
    return List.generate(maps.length, (i) => Bookmark.fromJson(maps[i]));
  }

  Future<List<Bookmark>> getBookmarksForSync() async {
    final db = await database;
    final maps = await db.query('bookmarks');
    return maps.map(Bookmark.fromJson).toList(growable: false);
  }

  Future<void> deleteBookmark(String verseReference) async {
    final db = await database;
    await db.update(
      'bookmarks',
      {
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'verseReference = ?',
      whereArgs: [verseReference],
    );
  }

  Future<void> saveAudioDownload(AudioDownload download) async {
    final db = await database;
    await db.insert(
      'audio_downloads',
      download.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AudioDownload?> getAudioDownload(
    String versionId,
    int bookId,
    int chapter,
  ) async {
    final db = await database;
    final rows = await db.query(
      'audio_downloads',
      where: 'versionId = ? AND bookId = ? AND chapter = ?',
      whereArgs: [versionId, bookId, chapter],
      limit: 1,
    );
    return rows.isEmpty ? null : AudioDownload.fromJson(rows.first);
  }

  Future<List<AudioDownload>> getAudioDownloads() async {
    final db = await database;
    final rows = await db.query(
      'audio_downloads',
      orderBy: 'versionId, bookId, chapter',
    );
    return rows.map(AudioDownload.fromJson).toList(growable: false);
  }

  Future<void> clearAudioDownloads() async {
    final db = await database;
    await db.delete('audio_downloads');
  }

  Future<void> insertUserReadingPlan(UserReadingPlan plan) async {
    final db = await database;
    final values = plan.toJson();
    values['daysCompleted'] = jsonEncode(values['daysCompleted']);
    await db.insert(
      'user_reading_plans',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUserReadingPlan(UserReadingPlan plan) async {
    final db = await database;
    final values = plan.toJson();
    values['daysCompleted'] = jsonEncode(values['daysCompleted']);
    await db.update(
      'user_reading_plans',
      values,
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<List<UserReadingPlan>> getUserReadingPlans() async {
    final db = await database;
    final rows = await db.query('user_reading_plans');
    return rows.map(_userReadingPlanFromRow).toList();
  }

  Future<UserReadingPlan?> getUserReadingPlanByPlanId(String planId) async {
    final db = await database;
    final rows = await db.query(
      'user_reading_plans',
      where: 'planId = ?',
      whereArgs: [planId],
      limit: 1,
    );
    return rows.isEmpty ? null : _userReadingPlanFromRow(rows.first);
  }

  Future<void> deleteUserReadingPlan(String id) async {
    final db = await database;
    await db.delete(
      'user_reading_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  UserReadingPlan _userReadingPlanFromRow(Map<String, Object?> row) {
    final values = Map<String, dynamic>.from(row);
    values['daysCompleted'] =
        jsonDecode(values['daysCompleted'] as String) as Map<String, dynamic>;
    return UserReadingPlan.fromJson(values);
  }
}
