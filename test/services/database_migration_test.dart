import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bible_pulse/services/database_service.dart';

void main() {
  sqfliteFfiInit();

  test('v3 study migration is idempotent at the data level', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE highlights (
        id TEXT PRIMARY KEY, verseReference TEXT NOT NULL, text TEXT NOT NULL,
        color INTEGER NOT NULL, createdAt TEXT NOT NULL)
    ''');
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY, verseReference TEXT NOT NULL, text TEXT NOT NULL,
        createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL)
    ''');
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY, verseReference TEXT NOT NULL, text TEXT NOT NULL,
        createdAt TEXT NOT NULL)
    ''');
    const created = '2026-01-02T03:04:05.000Z';
    await db.insert('highlights', {
      'id': 'legacy-highlight',
      'verseReference': 'John 3:16',
      'text': 'legacy',
      'color': 1,
      'createdAt': created,
    });

    for (final statement in DatabaseService.version3MigrationStatements) {
      await db.execute(statement);
    }

    final row = (await db.query('highlights')).single;
    expect(row['ownerId'], 'guest');
    expect(row['versionId'], 'WEB');
    expect(row['updatedAt'], created);
    expect(row['syncVersion'], 0);
    expect(row['deletedAt'], isNull);
  });
}
