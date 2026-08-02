import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'config/app_capabilities.dart';
import 'config/audio_config.dart';
import 'config/cloud_config.dart';
import 'services/audio_service.dart';
import 'services/audio_contracts.dart';
import 'services/deep_link_service.dart';
import 'services/bible_brain_audio_resolver.dart';
import 'services/bible_brain_catalog_service.dart';
import 'services/bible_brain_text_service.dart';
import 'services/bible_brain_version_registry.dart';
import 'services/public_domain_web_audio_resolver.dart';
import 'services/bible_package_service.dart';
import 'services/bible_service.dart';
import 'services/auth_service.dart';
import 'services/study_sync_service.dart';
import 'services/study_group_service.dart';
import 'services/firestore_community_repository.dart';
import 'services/licensed_catalog_service.dart';
import 'providers/community_provider.dart';
import 'providers/devotional_provider.dart';
import 'providers/hymn_provider.dart';
import 'providers/reading_plan_provider.dart';
import 'providers/audio_download_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/parallel_reading_provider.dart';
import 'providers/study_group_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/bible_store_provider.dart';
import 'providers/audio_store_provider.dart';
import 'providers/user_preferences_provider.dart';
import 'providers/study_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/color_theme_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/font_settings_provider.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/home_widget_service.dart';
import 'screens/bootstrap_screen.dart';
import 'screens/search_screen.dart';
import 'screens/app_shell.dart';
import 'screens/bible_reader_screen.dart';
import 'screens/bible_store_screen.dart';
import 'screens/audio_store_screen.dart';
import 'screens/study_screen.dart';
import 'screens/wallpaper_generator_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/social/community_feed_screen.dart';
import 'screens/devotions_screen.dart';
import 'screens/hymns_screen.dart';
import 'screens/reading_plans_screen.dart';
import 'screens/prayer_journal_screen.dart';
import 'screens/study_groups_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'utils/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'l10n/fallback_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.biblepulse.audio',
      androidNotificationChannelName: 'Bible audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  }
  await DeepLinkService.instance.start();
  await HomeWidgetService.configure();
  var cloudEnabled = false;
  AudioChapterResolver? audioResolver;
  final licensedFeatures = <String>{};
  final brainVersions = BibleBrainVersionRegistry();
  await brainVersions.load();
  BibleBrainCatalogService? brainCatalog;
  BibleBrainTextGateway? brainText;

  if (CloudConfig.isConfigured) {
    try {
      await Firebase.initializeApp(options: CloudConfig.options);
      if (CloudConfig.useEmulators) {
        await FirebaseAuth.instance.useAuthEmulator(
          CloudConfig.emulatorHost,
          9099,
        );
        FirebaseFirestore.instance.useFirestoreEmulator(
          CloudConfig.emulatorHost,
          8080,
        );
      }
      cloudEnabled = true;
    } catch (error) {
      debugPrint('Cloud initialization unavailable: $error');
    }
  }

  try {
    final entries = await LicensedCatalogService().manifest();
    licensedFeatures.addAll(
      entries
          .where((entry) => entry.isCurrentlyApproved)
          .map((entry) => entry.feature),
    );
  } catch (error) {
    debugPrint('Licensed content manifest unavailable: $error');
  }

  try {
    if (AudioConfig.hasApiKey) {
      brainCatalog = BibleBrainCatalogService(apiKey: AudioConfig.apiKey);
      brainText = BibleBrainTextService(
        apiKey: AudioConfig.apiKey,
        catalog: brainCatalog,
      );
    }
    if (AudioConfig.isConfigured && brainCatalog != null) {
      audioResolver = BibleBrainAudioResolver(
        apiKey: AudioConfig.apiKey,
        versionBibleIds: AudioConfig.bibleIds,
        allowedMediaHosts: AudioConfig.mediaHosts,
        catalog: brainCatalog,
        versions: brainVersions,
      );
    } else {
      audioResolver = await PublicDomainWebAudioResolver.loadFromAssets();
    }
  } catch (error) {
    debugPrint('Audio configuration unavailable: $error');
  }

  if (!kIsWeb) {
    tz.initializeTimeZones();

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await NotificationService().initialize();
      } catch (error) {
        debugPrint('Notification initialization unavailable: $error');
      }
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        await DatabaseService().database;
      } catch (error) {
        debugPrint('Local database initialization unavailable: $error');
      }
    }
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  final capabilities = AppCapabilities.forCurrentPlatform(
    cloud: cloudEnabled,
    audio: audioResolver != null,
    community: cloudEnabled ||
        const bool.fromEnvironment('BIBLEPULSE_ENABLE_COMMUNITY'),
    devotionals: licensedFeatures.contains('devotionals'),
    readingPlans: licensedFeatures.contains('readingPlans'),
    hymns: licensedFeatures.contains('hymns'),
  );
  runApp(
    BiblePulseApp(
      capabilities: capabilities,
      audioResolver: audioResolver,
      brainCatalog: brainCatalog,
      brainText: brainText,
      brainVersions: brainVersions,
    ),
  );
}

class BiblePulseApp extends StatelessWidget {
  const BiblePulseApp({
    super.key,
    this.audioResolver,
    this.brainCatalog,
    this.brainText,
    this.brainVersions,
    this.capabilities = const AppCapabilities(
      cloud: false,
      localDatabase: false,
      notifications: false,
      audio: false,
      wallpaperExport: false,
      devotionals: false,
      readingPlans: false,
      hymns: false,
    ),
  });

  final AppCapabilities capabilities;
  final AudioChapterResolver? audioResolver;
  final BibleBrainCatalogService? brainCatalog;
  final BibleBrainTextGateway? brainText;
  final BibleBrainVersionRegistry? brainVersions;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: capabilities),
        if (brainVersions != null) Provider.value(value: brainVersions!),
        ChangeNotifierProvider(
          create: (_) => AuthService(enabled: capabilities.cloud),
        ),
        Provider<StudySyncGateway>(
          create: (_) => FirestoreStudySyncService(
            enabled: capabilities.cloud,
          ),
        ),
        if (capabilities.community)
          ChangeNotifierProvider(
            create: (_) => CommunityProvider(
              FirestoreCommunityRepository(FirebaseFirestore.instance),
            ),
          ),
        if (capabilities.cloud && capabilities.readingPlans)
          ChangeNotifierProvider(
            create: (_) => StudyGroupProvider(
              FirestoreStudyGroupService(),
            ),
          ),
        if (capabilities.devotionals)
          ChangeNotifierProvider(create: (_) => DevotionalProvider()),
        if (capabilities.readingPlans)
          ChangeNotifierProvider(create: (_) => ReadingPlanProvider()),
        if (capabilities.hymns)
          ChangeNotifierProvider(create: (_) => HymnProvider()),
        ChangeNotifierProvider(
          create: (_) => AudioService(
            enabled: capabilities.audio,
            resolver: audioResolver,
            timingResolver: audioResolver is AudioTimingResolver
                ? audioResolver as AudioTimingResolver
                : null,
          ),
        ),
        if (capabilities.audio)
          ChangeNotifierProvider(
            create: (context) => AudioDownloadProvider(
              resolver: audioResolver!,
              cache: context.read<AudioService>().cache,
            )..initialize(),
          ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => UserPreferencesProvider()..initialize(),
        ),
        Provider(
          create: (_) => BiblePackageService(
            brainCatalog: brainCatalog,
            brainVersions: brainVersions,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BibleStoreProvider(
            context.read<BiblePackageService>(),
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioStoreProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => EngagementProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ParallelReadingProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => BibleProvider(
            bibleService: BibleService(
              packageService: context.read<BiblePackageService>(),
              brainText: brainText,
              brainVersions: brainVersions,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StudyProvider(),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ColorThemeProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => FontSettingsProvider()),
      ],
      child: Consumer2<ThemeProvider, UserPreferencesProvider>(
        builder: (context, themeProvider, userPrefs, child) {
          return MaterialApp(
            title: 'BiblePulse',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale:
                userPrefs.ready ? userPrefs.appLocale : themeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              GlobalWidgetsLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supported) {
              if (locale == null) return supported.first;
              for (final item in supported) {
                if (item.languageCode == locale.languageCode) return item;
              }
              return supported.first;
            },
            home: const BootstrapScreen(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const AppShell(),
              '/search': (context) => const SearchScreen(),
              '/bible': (context) => const BibleReaderScreen(),
              '/bible_store': (context) => const BibleStoreScreen(),
              '/audio_store': (context) => const AudioStoreScreen(),
              '/study': (context) => const StudyScreen(),
              '/wallpaper': (context) => const WallpaperGeneratorScreen(),
              '/settings': (context) => const SettingsScreen(),
              if (capabilities.community)
                '/community': (context) => const CommunityFeedScreen(),
              if (capabilities.cloud) '/auth': (context) => const AuthScreen(),
              if (capabilities.devotionals)
                '/devotions': (context) => const DevotionsScreen(),
              if (capabilities.readingPlans)
                '/reading_plans': (context) => const ReadingPlansScreen(),
              '/prayer_journal': (context) => const PrayerJournalScreen(),
              if (capabilities.cloud && capabilities.readingPlans)
                '/study_groups': (context) => const StudyGroupsScreen(),
              if (capabilities.hymns)
                '/hymns': (context) => const HymnsScreen(),
            },
          );
        },
      ),
    );
  }
}
