import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_package.dart';
import '../config/audio_config.dart';
import 'package_storage.dart';
import 'bible_brain_catalog_service.dart';
import 'bible_brain_version_registry.dart';
import 'bible_package_io.dart' if (dart.library.html) 'bible_package_web.dart'
    as fs;

typedef DownloadProgressCallback = void Function(double progress);

class BiblePackageService {
  BiblePackageService({
    PackageStorage? storage,
    BibleBrainCatalogGateway? brainCatalog,
    BibleBrainVersionRegistry? brainVersions,
  })  : _storage = storage ?? const CatalogUrlPackageStorage(),
        _brainCatalog = brainCatalog,
        _brainVersions = brainVersions;

  final PackageStorage _storage;
  final BibleBrainCatalogGateway? _brainCatalog;
  final BibleBrainVersionRegistry? _brainVersions;
  static const _registryKey = 'installed_bible_packages_v1';
  static const _catalogAsset = 'assets/catalog/bible_catalog.json';
  static const _focusLanguages = ['am', 'om', 'ti', 'so', 'en'];

  List<BiblePackageInfo> _catalog = [];
  final Map<String, InstalledBiblePackage> _installed = {};
  final Map<String, PackageDownloadProgress> _progress = {};

  List<BiblePackageInfo> get catalog => List.unmodifiable(_catalog);
  Map<String, InstalledBiblePackage> get installed =>
      Map.unmodifiable(_installed);
  Map<String, PackageDownloadProgress> get progress =>
      Map.unmodifiable(_progress);

  Future<void> initialize() async {
    await _brainVersions?.load();
    await _loadCatalog();
    await _mergeBibleBrainCatalog();
    await _loadRegistry();
    await ensureBundledPackagesInstalled();
    await _syncEnabledBrainPackages();
  }

  Future<void> _loadCatalog() async {
    final raw = await rootBundle.loadString(_catalogAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>? ?? const [];
    _catalog = packages
        .map((e) =>
            BiblePackageInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _mergeBibleBrainCatalog() async {
    final catalog = _brainCatalog;
    if (catalog == null || !AudioConfig.hasApiKey) return;
    final remote = <BiblePackageInfo>[];
    for (final language in _focusLanguages) {
      try {
        final bibles = await catalog.listBibles(
          languageCode: language,
          limit: 25,
        );
        for (final bible in bibles) {
          if (!bible.hasText && !bible.hasAudio) continue;
          remote.add(
            BiblePackageInfo(
              id: 'bb-${bible.id.toLowerCase()}',
              versionId: bible.abbreviation.toUpperCase(),
              name: bible.name,
              abbreviation: bible.abbreviation.toUpperCase(),
              language:
                  bible.languageIso.isEmpty ? language : bible.languageIso,
              languageName:
                  bible.languageName.isEmpty ? language : bible.languageName,
              description: bible.hasAudio && bible.hasText
                  ? 'Stream text and audio via Bible Brain (Faith Comes By Hearing). Online while your API key grants access; offline only if download is permitted for that fileset.'
                  : bible.hasAudio
                      ? 'Audio available via Bible Brain. Enable to map this Bible ID for playback.'
                      : 'Stream Scripture text via Bible Brain. Enable to read online with your API key.',
              license: 'Bible Brain / rights holder terms',
              attribution: 'Content via Faith Comes By Hearing / Bible Brain',
              source: 'https://4.dbt.io/',
              commercialUse: false,
              redistribution: false,
              approved: true,
              category: const ['new', 'bible_brain'],
              fileSizeBytes: 0,
              offlineSizeBytes: 0,
              updatedAt:
                  DateTime.now().toUtc().toIso8601String().split('T').first,
              install: BiblePackageInstall(
                type: 'bible_brain',
                path: bible.id,
              ),
            ),
          );
        }
      } catch (error) {
        debugPrint('Bible Brain catalog unavailable for $language: $error');
      }
    }
    if (remote.isEmpty) return;
    final byId = <String, BiblePackageInfo>{
      for (final pkg in _catalog)
        if (pkg.install.type != 'unavailable') pkg.id: pkg,
    };
    final existingBrainPackages = <String, BiblePackageInfo>{
      for (final pkg in _catalog)
        if (pkg.install.type == 'bible_brain' &&
            pkg.install.path != null &&
            pkg.install.path!.isNotEmpty)
          pkg.install.path!: pkg,
    };
    for (final pkg in remote) {
      if (pkg.install.path != null && pkg.install.path!.isNotEmpty) {
        final existing = existingBrainPackages[pkg.install.path!];
        if (existing != null) {
          byId.remove(existing.id);
        }
      }
      byId.putIfAbsent(pkg.id, () => pkg);
    }
    _catalog = byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _syncEnabledBrainPackages() async {
    final registry = _brainVersions;
    if (registry == null) return;
    for (final entry in registry.all.entries) {
      final versionId = entry.key;
      final bibleId = entry.value;
      BiblePackageInfo? match;
      for (final pkg in _catalog) {
        if (pkg.install.type == 'bible_brain' &&
            pkg.install.path == bibleId &&
            pkg.versionId == versionId) {
          match = pkg;
          break;
        }
      }
      final pkg = match ??
          BiblePackageInfo(
            id: 'bb-${bibleId.toLowerCase()}',
            versionId: versionId,
            name: versionId,
            abbreviation: versionId,
            language: 'und',
            languageName: 'Unknown',
            description: 'Enabled Bible Brain translation.',
            license: 'Bible Brain / rights holder terms',
            attribution: 'Content via Faith Comes By Hearing / Bible Brain',
            source: 'https://4.dbt.io/',
            commercialUse: false,
            redistribution: false,
            approved: true,
            category: const ['bible_brain'],
            fileSizeBytes: 0,
            offlineSizeBytes: 0,
            updatedAt:
                DateTime.now().toUtc().toIso8601String().split('T').first,
            install: BiblePackageInstall(type: 'bible_brain', path: bibleId),
          );
      if (!_catalog.any((item) => item.id == pkg.id)) {
        _catalog = [..._catalog, pkg];
      }
      _installed[pkg.id] = InstalledBiblePackage(
        packageId: pkg.id,
        versionId: pkg.versionId,
        language: pkg.language,
        localPath: 'bible_brain:$bibleId',
        installedAt: DateTime.now().toUtc().toIso8601String(),
        sizeBytes: 0,
        bundled: false,
      );
    }
  }

  Future<void> _loadRegistry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_registryKey);
    _installed.clear();
    if (raw == null || raw.isEmpty) return;
    final list = jsonDecode(raw) as List<dynamic>;
    for (final item in list) {
      final installed = InstalledBiblePackage.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      _installed[installed.packageId] = installed;
    }
  }

  Future<void> _saveRegistry() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _installed.values.map((e) => e.toJson()).toList();
    await prefs.setString(_registryKey, jsonEncode(list));
  }

  Future<void> ensureBundledPackagesInstalled() async {
    for (final pkg in _catalog) {
      if (pkg.install.type != 'asset' || !pkg.canInstall) continue;
      if (!pkg.category.contains('bundled')) continue;
      if (_installed.containsKey(pkg.id)) continue;
      await installPackage(pkg);
    }
  }

  bool isInstalled(String packageId) => _installed.containsKey(packageId);

  InstalledBiblePackage? installedByVersion(String versionId) {
    for (final item in _installed.values) {
      if (item.versionId == versionId) return item;
    }
    return null;
  }

  String? sourceForVersion(String versionId) {
    final installed = installedByVersion(versionId);
    if (installed == null) return null;
    return installed.localPath;
  }

  List<String> get installedVersionIds =>
      _installed.values.map((e) => e.versionId).toSet().toList()..sort();

  Future<void> installPackage(
    BiblePackageInfo pkg, {
    DownloadProgressCallback? onProgress,
  }) async {
    if (!pkg.canInstall) {
      throw StateError('Package ${pkg.id} is not legally installable');
    }
    if (pkg.install.type == 'bible_brain') {
      await _enableBibleBrainPackage(pkg, onProgress: onProgress);
      return;
    }
    if (kIsWeb && pkg.install.type == 'url') {
      throw UnsupportedError(
        'This translation must be installed from a bundled package on web. '
        'Try KJV or ASV from the Bible Store.',
      );
    }

    _progress[pkg.id] = PackageDownloadProgress(
      packageId: pkg.id,
      state: PackageDownloadState.downloading,
      progress: 0.05,
    );
    onProgress?.call(0.05);

    try {
      late final String outPath;
      late final int size;
      late final bool bundled;

      if (pkg.install.type == 'asset') {
        final assetPath = pkg.install.path!;
        if (kIsWeb) {
          outPath = 'asset:$assetPath';
          size = pkg.fileSizeBytes;
          bundled = true;
        } else {
          final raw = await rootBundle.loadString(assetPath);
          final bibleJson = jsonDecode(raw) as Map<String, dynamic>;
          outPath = await _writePackageFiles(pkg, bibleJson);
          size = await fs.fileLength(outPath);
          bundled = true;
        }
        _progress[pkg.id] = PackageDownloadProgress(
          packageId: pkg.id,
          state: PackageDownloadState.installing,
          progress: 0.8,
        );
        onProgress?.call(0.8);
      } else {
        final url = pkg.install.url!;
        final uri = await _storage.resolveBiblePackageUrl(pkg.id, url) ??
            Uri.parse(url);
        final response = await http.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Download failed (${response.statusCode})');
        }
        _progress[pkg.id] = PackageDownloadProgress(
          packageId: pkg.id,
          state: PackageDownloadState.verifying,
          progress: 0.55,
        );
        onProgress?.call(0.55);
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final bibleJson = _normalizeBibleJson(
          decoded,
          versionId: pkg.versionId,
          language: pkg.language,
          name: pkg.name,
        );
        outPath = await _writePackageFiles(pkg, bibleJson);
        size = await fs.fileLength(outPath);
        bundled = false;
      }

      _installed[pkg.id] = InstalledBiblePackage(
        packageId: pkg.id,
        versionId: pkg.versionId,
        language: pkg.language,
        localPath: outPath,
        installedAt: DateTime.now().toUtc().toIso8601String(),
        sizeBytes: size,
        bundled: bundled,
      );
      await _saveRegistry();

      _progress[pkg.id] = PackageDownloadProgress(
        packageId: pkg.id,
        state: PackageDownloadState.completed,
        progress: 1,
      );
      onProgress?.call(1);
    } catch (error) {
      _progress[pkg.id] = PackageDownloadProgress(
        packageId: pkg.id,
        state: PackageDownloadState.failed,
        progress: 0,
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<String> _writePackageFiles(
    BiblePackageInfo pkg,
    Map<String, dynamic> bibleJson,
  ) async {
    final support = await getApplicationSupportDirectory();
    final langDir = p.join(support.path, 'bibles', pkg.language);
    await fs.ensureDir(langDir);
    final outPath = p.join(langDir, '${pkg.versionId.toLowerCase()}.json');
    await fs.writeString(outPath, jsonEncode(bibleJson));
    final indexPath = p.join(langDir, '${pkg.versionId.toLowerCase()}.db.json');
    await fs.writeString(indexPath, jsonEncode(_verseIndex(bibleJson)));
    return outPath;
  }

  Future<void> _enableBibleBrainPackage(
    BiblePackageInfo pkg, {
    DownloadProgressCallback? onProgress,
  }) async {
    if (!AudioConfig.hasApiKey) {
      throw StateError(
        'Bible Brain API key required. Request one at https://4.dbt.io/api_key/request',
      );
    }
    final bibleId = pkg.install.path;
    if (bibleId == null || bibleId.isEmpty) {
      throw StateError('Package ${pkg.id} is missing a Bible Brain bible id.');
    }
    final registry = _brainVersions;
    if (registry == null) {
      throw StateError('Bible Brain version registry is unavailable.');
    }

    _progress[pkg.id] = PackageDownloadProgress(
      packageId: pkg.id,
      state: PackageDownloadState.installing,
      progress: 0.5,
    );
    onProgress?.call(0.5);

    await registry.enable(versionId: pkg.versionId, bibleId: bibleId);
    _installed[pkg.id] = InstalledBiblePackage(
      packageId: pkg.id,
      versionId: pkg.versionId,
      language: pkg.language,
      localPath: 'bible_brain:$bibleId',
      installedAt: DateTime.now().toUtc().toIso8601String(),
      sizeBytes: 0,
      bundled: false,
    );
    await _saveRegistry();
    _progress[pkg.id] = PackageDownloadProgress(
      packageId: pkg.id,
      state: PackageDownloadState.completed,
      progress: 1,
    );
    onProgress?.call(1);
  }

  Future<void> uninstallPackage(String packageId) async {
    final installed = _installed[packageId];
    if (installed == null) return;
    if (installed.localPath.startsWith('bible_brain:')) {
      await _brainVersions?.disable(installed.versionId);
      _installed.remove(packageId);
      await _saveRegistry();
      return;
    }
    if (installed.bundled) {
      throw StateError('Bundled packages cannot be removed');
    }
    _installed.remove(packageId);
    if (!installed.localPath.startsWith('asset:')) {
      await fs.deleteIfExists(installed.localPath);
      await fs.deleteIfExists(
        installed.localPath.replaceAll('.json', '.db.json'),
      );
    }
    await _saveRegistry();
    _progress.remove(packageId);
  }

  Future<int> totalStorageBytes() async {
    var total = 0;
    for (final item in _installed.values) {
      total += item.sizeBytes;
    }
    return total;
  }

  Map<String, dynamic> _normalizeBibleJson(
    dynamic decoded, {
    required String versionId,
    required String language,
    required String name,
  }) {
    if (decoded is Map<String, dynamic> && decoded['books'] is List) {
      return decoded;
    }

    if (decoded is List) {
      final byBook = <int, Map<String, dynamic>>{};
      for (final row in decoded) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final bookId = (map['book'] as num?)?.toInt() ??
            (map['book_id'] as num?)?.toInt() ??
            0;
        if (bookId < 1) continue;
        final bookName =
            (map['book_name'] ?? map['bookName'] ?? 'Book $bookId').toString();
        final chapter = (map['chapter'] as num?)?.toInt() ?? 0;
        final verse = (map['verse'] as num?)?.toInt() ?? 0;
        final text = (map['text'] ?? map['verse_text'] ?? '').toString();
        if (chapter < 1 || verse < 1 || text.isEmpty) continue;

        final book = byBook.putIfAbsent(
          bookId,
          () => {
            'id': bookId,
            'name': bookName,
            'testament': bookId <= 39 ? 'OT' : 'NT',
            'chapters': <Map<String, dynamic>>[],
          },
        );
        final chapters = book['chapters'] as List<Map<String, dynamic>>;
        Map<String, dynamic>? chapterMap;
        for (final c in chapters) {
          if (c['number'] == chapter) {
            chapterMap = c;
            break;
          }
        }
        if (chapterMap == null) {
          chapterMap = {
            'number': chapter,
            'verses': <Map<String, dynamic>>[],
          };
          chapters.add(chapterMap);
        }
        (chapterMap['verses'] as List).add({'verse': verse, 'text': text});
      }

      final books = byBook.keys.toList()..sort();
      return {
        'schemaVersion': 1,
        'translation': {
          'id': versionId,
          'name': name,
          'language': language,
          'license': 'Public Domain',
        },
        'books': [
          for (final id in books) byBook[id]!,
        ],
      };
    }

    throw const FormatException('Unsupported Bible package JSON format');
  }

  Map<String, dynamic> _verseIndex(Map<String, dynamic> bibleJson) {
    final rows = <Map<String, dynamic>>[];
    final books = bibleJson['books'];
    if (books is! List) return {'verses': rows};
    for (var bi = 0; bi < books.length; bi++) {
      final dynamic bookRaw = books[bi];
      if (bookRaw == null) continue;
      if (bookRaw is! Map) continue;
      final book = Map<String, dynamic>.from(bookRaw as Map);
      final bookId = (book['id'] is num)
          ? (book['id'] as num).toInt()
          : (int.tryParse(book['id']?.toString() ?? '') ?? bi + 1);

      final chaptersRaw = book['chapters'];
      if (chaptersRaw is! List) continue;
      for (var ci = 0; ci < chaptersRaw.length; ci++) {
        final dynamic chapterRaw = chaptersRaw[ci];
        int chapterNum = ci + 1;
        dynamic versesRaw;

        if (chapterRaw is Map) {
          final chapter = Map<String, dynamic>.from(chapterRaw as Map);
          // support both 'number' and 'chapter' keys
          chapterNum = (chapter['number'] is num)
              ? (chapter['number'] as num).toInt()
              : (int.tryParse(chapter['number']?.toString() ?? '') ??
                  (int.tryParse(chapter['chapter']?.toString() ?? '') ?? ci + 1));
          versesRaw = chapter.containsKey('verses') ? chapter['verses'] : null;
          // if chapter is actually a list-like map with numeric keys, try its values
          if (versesRaw == null && chapter.values.any((v) => v is List)) {
            final maybeList = chapter.values.firstWhere((v) => v is List);
            versesRaw = maybeList;
          }
        } else if (chapterRaw is List) {
          versesRaw = chapterRaw;
        } else {
          versesRaw = null;
        }

        if (versesRaw is! List) continue;
        final verses = versesRaw as List;
        for (var vi = 0; vi < verses.length; vi++) {
          final dynamic vRaw = verses[vi];
          int verseNum = vi + 1;
          String text = '';

          if (vRaw is Map) {
            final verseMap = Map<String, dynamic>.from(vRaw as Map);
            verseNum = (verseMap['verse'] is num)
                ? (verseMap['verse'] as num).toInt()
                : (int.tryParse(verseMap['verse']?.toString() ?? '') ??
                    (int.tryParse(verseMap['id']?.toString() ?? '') ?? vi + 1));
            text = (verseMap['text'] ?? verseMap['verse_text'] ??
                    verseMap['content'] ?? '')
                .toString();
          } else {
            // verse represented as plain string
            verseNum = vi + 1;
            text = vRaw?.toString() ?? '';
          }

          if (text.isEmpty) continue;
          rows.add({
            'book': bookId,
            'chapter': chapterNum,
            'verse': verseNum,
            'text': text,
          });
        }
      }
    }
    return {'verses': rows};
  }
}
