import 'package:flutter/foundation.dart';

class AppCapabilities {
  const AppCapabilities({
    required this.cloud,
    required this.localDatabase,
    required this.notifications,
    required this.audio,
    required this.wallpaperExport,
    required this.devotionals,
    required this.readingPlans,
    required this.hymns,
    this.community = false,
  });

  final bool cloud;
  final bool localDatabase;
  final bool notifications;
  final bool audio;
  final bool wallpaperExport;
  final bool devotionals;
  final bool readingPlans;
  final bool hymns;
  final bool community;

  factory AppCapabilities.forCurrentPlatform({
    required bool cloud,
    bool audio = false,
    bool community = false,
    bool devotionals = false,
    bool readingPlans = false,
    bool hymns = false,
  }) {
    if (kIsWeb) {
      return AppCapabilities(
        cloud: cloud,
        localDatabase: false,
        notifications: false,
        audio: audio,
        wallpaperExport: false,
        devotionals: devotionals,
        readingPlans: readingPlans,
        hymns: hymns,
        community: cloud && community,
      );
    }

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final isMacOs = defaultTargetPlatform == TargetPlatform.macOS;

    return AppCapabilities(
      cloud: cloud,
      localDatabase: isAndroid || isIos || isMacOs,
      notifications: isAndroid || isIos,
      audio: audio,
      wallpaperExport: isAndroid || isIos,
      devotionals: devotionals,
      readingPlans: readingPlans,
      hymns: hymns,
      community: cloud && community,
    );
  }
}
