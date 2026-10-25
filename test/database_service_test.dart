import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bible_pulse/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;
  test('resolveDatabasePath accepts a writable override directory', () async {
    final tempRoot = await Directory.systemTemp.createTemp('bp_db_');
    final overrideDir = Directory(join(tempRoot.path, 'override-db-dir'));

    try {
      final dbPath = await DatabaseService.resolveDatabasePath(
        appRootOverride: overrideDir.path,
      );

      expect(dbPath, contains(overrideDir.path));
      expect(await overrideDir.exists(), isTrue);
    } finally {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    }
  });

  test('database creates query indexes for highlights, notes, and bookmarks', () async {
    final db = await DatabaseService().database;
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name IN (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [
        'idx_highlights_deleted_owner',
        'idx_highlights_version_ref',
        'idx_notes_deleted_owner',
        'idx_notes_version_ref',
        'idx_bookmarks_deleted_owner',
        'idx_bookmarks_version_ref',
        'idx_audio_downloads_version_book_chapter',
        'idx_reading_plans_plan_id',
        'idx_journey_owner_updated',
      ],
    );

    final names = rows.map((row) => row['name'] as String).toSet();
    expect(
      names,
      containsAll([
        'idx_highlights_deleted_owner',
        'idx_highlights_version_ref',
        'idx_notes_deleted_owner',
        'idx_notes_version_ref',
        'idx_bookmarks_deleted_owner',
        'idx_bookmarks_version_ref',
        'idx_audio_downloads_version_book_chapter',
        'idx_reading_plans_plan_id',
        'idx_journey_owner_updated',
      ]),
    );
  });
}
