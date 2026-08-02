import 'package:flutter/foundation.dart';

import '../models/bible_verse.dart';
import 'bible_service.dart';
import 'database_service.dart';

class BibleSearchService {
  BibleSearchService({
    BibleService? bibleService,
    DatabaseService? databaseService,
  })  : _bibleService = bibleService ?? BibleService(),
        _databaseService = databaseService ?? DatabaseService();

  final BibleService _bibleService;
  final DatabaseService _databaseService;

  bool get _supportsFts =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<List<BibleVerse>> search(
    String versionId,
    String query, {
    int limit = 100,
  }) async {
    if (!_supportsFts) {
      return _bibleService.searchIndexed(versionId, query, limit: limit);
    }

    if (!await _databaseService.hasBibleIndex(versionId)) {
      final verses = await _bibleService.getAllVerses(versionId);
      await _databaseService.replaceBibleIndex(versionId, verses);
    }
    return _databaseService.searchBible(versionId, query, limit: limit);
  }
}
