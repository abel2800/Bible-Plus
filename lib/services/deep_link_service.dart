import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'audio_share_link.dart';

/// Resolves install / cold-start / warm listen links into [AudioShareTarget]s.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  final _controller = StreamController<AudioShareTarget>.broadcast();
  StreamSubscription<Uri>? _sub;
  AudioShareTarget? _pending;
  bool _started = false;

  Stream<AudioShareTarget> get stream => _controller.stream;

  AudioShareTarget? get pending => _pending;

  AudioShareTarget? takePending() {
    final value = _pending;
    _pending = null;
    return value;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Web / same-tab opens with query params on the current page.
    if (kIsWeb) {
      final fromWeb = AudioShareLink.tryParse(Uri.base);
      if (fromWeb != null) {
        _emit(fromWeb);
      }
    }

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        final target = AudioShareLink.tryParse(initial);
        if (target != null) _emit(target);
      }
    } catch (error, stack) {
      debugPrint('DeepLinkService initial link failed: $error\n$stack');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        final target = AudioShareLink.tryParse(uri);
        if (target != null) _emit(target);
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('DeepLinkService stream error: $error\n$stack');
      },
    );
  }

  void _emit(AudioShareTarget target) {
    _pending = target;
    if (!_controller.isClosed) {
      _controller.add(target);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _controller.close();
  }
}
