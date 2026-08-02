import '../config/share_config.dart';
import '../models/audio_queue_item.dart';

/// Chapter target carried in a share / deep link.
class AudioShareTarget {
  const AudioShareTarget({
    required this.versionId,
    required this.bookId,
    required this.chapter,
    this.bookName,
  });

  final String versionId;
  final int bookId;
  final int chapter;
  final String? bookName;

  String get label {
    final name = (bookName == null || bookName!.trim().isEmpty)
        ? 'Book $bookId'
        : bookName!.trim();
    return '$name $chapter ($versionId)';
  }
}

abstract final class AudioShareLink {
  /// HTTPS App Link / web URL that opens this chapter after install or on web.
  static Uri httpsListenUri(AudioQueueItem item) {
    final base = ShareConfig.webBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base${ShareConfig.listenPath}').replace(
      queryParameters: _query(item),
    );
  }

  /// Native custom-scheme URI (`biblepulse://listen?...`).
  static Uri appSchemeUri(AudioQueueItem item) {
    return Uri(
      scheme: ShareConfig.appScheme,
      host: 'listen',
      queryParameters: _query(item),
    );
  }

  static Map<String, String> _query(AudioQueueItem item) {
    return {
      'v': item.versionId,
      'b': '${item.bookId}',
      'c': '${item.chapter}',
      if (item.bookName.trim().isNotEmpty) 'n': item.bookName,
    };
  }

  static AudioShareTarget? tryParse(Uri uri) {
    if (!_isListenUri(uri)) return null;

    final params = <String, String>{
      ...uri.queryParameters,
    };
    // Support path style: /listen/WEB/43/3
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 4 && segments.first == 'listen') {
      params.putIfAbsent('v', () => segments[1]);
      params.putIfAbsent('b', () => segments[2]);
      params.putIfAbsent('c', () => segments[3]);
    }

    final version = (params['v'] ?? params['version'] ?? '').trim();
    final bookId = int.tryParse(params['b'] ?? params['book'] ?? '');
    final chapter = int.tryParse(params['c'] ?? params['chapter'] ?? '');
    if (version.isEmpty || bookId == null || bookId < 1) return null;
    if (chapter == null || chapter < 1) return null;

    final name = (params['n'] ?? params['name'] ?? '').trim();
    return AudioShareTarget(
      versionId: version,
      bookId: bookId,
      chapter: chapter,
      bookName: name.isEmpty ? null : name,
    );
  }

  static bool _isListenUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == ShareConfig.appScheme) {
      return uri.host.toLowerCase() == 'listen' ||
          uri.pathSegments.contains('listen');
    }
    if (scheme == 'http' || scheme == 'https') {
      final path = uri.path.toLowerCase();
      final hasChapterQuery = uri.queryParameters.containsKey('v') &&
          uri.queryParameters.containsKey('b') &&
          uri.queryParameters.containsKey('c');
      return path == ShareConfig.listenPath ||
          path.startsWith('${ShareConfig.listenPath}/') ||
          hasChapterQuery;
    }
    // Flutter web often surfaces as path-only relative to the deployed app.
    if (scheme.isEmpty || scheme == 'file') {
      return uri.path.toLowerCase().contains('listen') ||
          (uri.queryParameters.containsKey('v') &&
              uri.queryParameters.containsKey('b') &&
              uri.queryParameters.containsKey('c'));
    }
    return false;
  }

  /// Body passed to the system share sheet.
  static String shareMessage(AudioQueueItem item) {
    final listen = httpsListenUri(item);
    final buffer = StringBuffer()
      ..writeln('Listen to ${item.title} (${item.versionId}) on BiblePulse')
      ..writeln()
      ..writeln('Open this chapter:')
      ..writeln(listen)
      ..writeln()
      ..writeln('Get the app:')
      ..writeln('Android: ${ShareConfig.playStoreUrl}')
      ..writeln('iOS: ${ShareConfig.appStoreUrl}');
    return buffer.toString().trimRight();
  }
}
