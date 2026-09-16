import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

Future<void> initAppSqlite() async {
  if (!Platform.isAndroid) return;

  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
