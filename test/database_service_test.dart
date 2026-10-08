import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import 'package:bible_pulse/services/database_service.dart';

void main() {
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
}
