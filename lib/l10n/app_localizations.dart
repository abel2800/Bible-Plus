import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';
import 'app_localizations_so.dart';
import 'app_localizations_ti.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('am'),
    Locale('om'),
    Locale('ti'),
    Locale('so')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BiblePulse'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Scripture, illuminated.'**
  String get tagline;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to your daily reading'**
  String get welcomeBack;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRead.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get navRead;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navSearch;

  /// No description provided for @navStudy.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get navStudy;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navSettings;

  /// No description provided for @readBible.
  ///
  /// In en, this message translates to:
  /// **'Read Bible'**
  String get readBible;

  /// No description provided for @myStudy.
  ///
  /// In en, this message translates to:
  /// **'My Study'**
  String get myStudy;

  /// No description provided for @createWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Verse Studio'**
  String get createWallpaper;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @verseOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Verse of the Day'**
  String get verseOfTheDay;

  /// No description provided for @dailyPrayer.
  ///
  /// In en, this message translates to:
  /// **'Daily Prayer'**
  String get dailyPrayer;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @wallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get wallpaper;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue listening'**
  String get continueListening;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @parallelRead.
  ///
  /// In en, this message translates to:
  /// **'Parallel read'**
  String get parallelRead;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @readingPlans.
  ///
  /// In en, this message translates to:
  /// **'Reading plans'**
  String get readingPlans;

  /// No description provided for @hymns.
  ///
  /// In en, this message translates to:
  /// **'Hymns'**
  String get hymns;

  /// No description provided for @searchScripture.
  ///
  /// In en, this message translates to:
  /// **'Search Scripture…'**
  String get searchScripture;

  /// No description provided for @searchAllScripture.
  ///
  /// In en, this message translates to:
  /// **'Search all Scripture…'**
  String get searchAllScripture;

  /// No description provided for @searchBooks.
  ///
  /// In en, this message translates to:
  /// **'Search books…'**
  String get searchBooks;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterOldTestament.
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get filterOldTestament;

  /// No description provided for @filterNewTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get filterNewTestament;

  /// No description provided for @filterMyNotes.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get filterMyNotes;

  /// No description provided for @selectBook.
  ///
  /// In en, this message translates to:
  /// **'Select Book'**
  String get selectBook;

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapter;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'chapters'**
  String get chapters;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @chooseBookToRead.
  ///
  /// In en, this message translates to:
  /// **'Choose a Book to Read'**
  String get chooseBookToRead;

  /// No description provided for @tapBookName.
  ///
  /// In en, this message translates to:
  /// **'Tap the book name above to get started'**
  String get tapBookName;

  /// No description provided for @browseBooks.
  ///
  /// In en, this message translates to:
  /// **'Browse Books'**
  String get browseBooks;

  /// No description provided for @changeVersion.
  ///
  /// In en, this message translates to:
  /// **'Change Version'**
  String get changeVersion;

  /// No description provided for @loadingScripture.
  ///
  /// In en, this message translates to:
  /// **'Loading Scripture...'**
  String get loadingScripture;

  /// No description provided for @oldTestament.
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// No description provided for @newTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// No description provided for @selectChapter.
  ///
  /// In en, this message translates to:
  /// **'Select Chapter'**
  String get selectChapter;

  /// No description provided for @selectVersion.
  ///
  /// In en, this message translates to:
  /// **'Select Version'**
  String get selectVersion;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @highlightColor.
  ///
  /// In en, this message translates to:
  /// **'Highlight Color'**
  String get highlightColor;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// No description provided for @verseHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Verse highlighted'**
  String get verseHighlighted;

  /// No description provided for @highlightRemoved.
  ///
  /// In en, this message translates to:
  /// **'Highlight removed'**
  String get highlightRemoved;

  /// No description provided for @noHighlights.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet'**
  String get noHighlights;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotes;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @preferredBible.
  ///
  /// In en, this message translates to:
  /// **'Preferred Bible'**
  String get preferredBible;

  /// No description provided for @preferredAudio.
  ///
  /// In en, this message translates to:
  /// **'Preferred audio'**
  String get preferredAudio;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dailyDevotional.
  ///
  /// In en, this message translates to:
  /// **'Daily Devotional'**
  String get dailyDevotional;

  /// No description provided for @notificationTime.
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get notificationTime;

  /// No description provided for @receiveDailyVerse.
  ///
  /// In en, this message translates to:
  /// **'Receive daily verse and prayer'**
  String get receiveDailyVerse;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'scheduled for'**
  String get scheduledFor;

  /// No description provided for @readerTheme.
  ///
  /// In en, this message translates to:
  /// **'Reader theme'**
  String get readerTheme;

  /// No description provided for @offlineAudio.
  ///
  /// In en, this message translates to:
  /// **'Offline audio'**
  String get offlineAudio;

  /// No description provided for @downloadedBooks.
  ///
  /// In en, this message translates to:
  /// **'Downloaded books'**
  String get downloadedBooks;

  /// No description provided for @wifiOnlyDownloads.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only downloads'**
  String get wifiOnlyDownloads;

  /// No description provided for @featureAvailability.
  ///
  /// In en, this message translates to:
  /// **'Feature availability'**
  String get featureAvailability;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownload;

  /// No description provided for @bibleStore.
  ///
  /// In en, this message translates to:
  /// **'Bible Store'**
  String get bibleStore;

  /// No description provided for @audioStore.
  ///
  /// In en, this message translates to:
  /// **'Audio Store'**
  String get audioStore;

  /// No description provided for @browseBibles.
  ///
  /// In en, this message translates to:
  /// **'Browse Bibles'**
  String get browseBibles;

  /// No description provided for @browseAudio.
  ///
  /// In en, this message translates to:
  /// **'Browse audio'**
  String get browseAudio;

  /// No description provided for @searchVersions.
  ///
  /// In en, this message translates to:
  /// **'Search translations…'**
  String get searchVersions;

  /// No description provided for @searchAudio.
  ///
  /// In en, this message translates to:
  /// **'Search audio packs…'**
  String get searchAudio;

  /// No description provided for @categoryPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get categoryPopular;

  /// No description provided for @categoryNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get categoryNew;

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get categoryUpdated;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @languageFilter.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageFilter;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get fileSize;

  /// No description provided for @offlineSize.
  ///
  /// In en, this message translates to:
  /// **'Offline size'**
  String get offlineSize;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @narrator.
  ///
  /// In en, this message translates to:
  /// **'Narrator'**
  String get narrator;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloadProgress;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get storageUsed;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @comingWithLicense.
  ///
  /// In en, this message translates to:
  /// **'Coming with license'**
  String get comingWithLicense;

  /// No description provided for @audioGated.
  ///
  /// In en, this message translates to:
  /// **'Audio gated'**
  String get audioGated;

  /// No description provided for @chapterAudio.
  ///
  /// In en, this message translates to:
  /// **'Chapter audio'**
  String get chapterAudio;

  /// No description provided for @prayerJournal.
  ///
  /// In en, this message translates to:
  /// **'Prayer journal'**
  String get prayerJournal;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @verseWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Create with Scripture'**
  String get verseWallpaper;

  /// No description provided for @devotionals.
  ///
  /// In en, this message translates to:
  /// **'Devotionals'**
  String get devotionals;

  /// No description provided for @privateReadingGroups.
  ///
  /// In en, this message translates to:
  /// **'Private reading groups'**
  String get privateReadingGroups;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @syncStudy.
  ///
  /// In en, this message translates to:
  /// **'Sync study'**
  String get syncStudy;

  /// No description provided for @offlineReading.
  ///
  /// In en, this message translates to:
  /// **'Offline reading'**
  String get offlineReading;

  /// No description provided for @bootstrapFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'BiblePulse could not finish starting.'**
  String get bootstrapFailedTitle;

  /// No description provided for @bootstrapFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your local data is safe. Check the app resources and try again.'**
  String get bootstrapFailedBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @manageDownloads.
  ///
  /// In en, this message translates to:
  /// **'Manage downloads'**
  String get manageDownloads;

  /// No description provided for @preferredLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Translates the entire app interface'**
  String get preferredLanguageSubtitle;

  /// No description provided for @preferredBibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default translation for reading and search'**
  String get preferredBibleSubtitle;

  /// No description provided for @preferredAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default narration when listening'**
  String get preferredAudioSubtitle;

  /// No description provided for @scriptureLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'App language and Bible text are separate. Changing the app language does not change Scripture. Install a translation from the Bible Store, then set it as Preferred Bible.'**
  String get scriptureLanguageNote;

  /// No description provided for @audioSetupNote.
  ///
  /// In en, this message translates to:
  /// **'English WEB audio (Henson / eBible) is included by default. Optional Bible Brain packs need API credentials at build time. Open the Audio Store to manage narrations.'**
  String get audioSetupNote;

  /// No description provided for @noScriptureForLanguage.
  ///
  /// In en, this message translates to:
  /// **'No licensed Scripture package is installed for this language yet. English WEB remains available offline.'**
  String get noScriptureForLanguage;

  /// No description provided for @openBibleStore.
  ///
  /// In en, this message translates to:
  /// **'Open Bible Store'**
  String get openBibleStore;

  /// No description provided for @openAudioStore.
  ///
  /// In en, this message translates to:
  /// **'Open Audio Store'**
  String get openAudioStore;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @bundled.
  ///
  /// In en, this message translates to:
  /// **'Bundled'**
  String get bundled;

  /// No description provided for @publicDomain.
  ///
  /// In en, this message translates to:
  /// **'Public Domain'**
  String get publicDomain;

  /// No description provided for @requiresLicense.
  ///
  /// In en, this message translates to:
  /// **'Requires license'**
  String get requiresLicense;

  /// No description provided for @unavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Unavailable offline'**
  String get unavailableOffline;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @deletePackageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this package from this device?'**
  String get deletePackageConfirm;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get amharic;

  /// No description provided for @afaanOromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromo'**
  String get afaanOromo;

  /// No description provided for @tigrinya.
  ///
  /// In en, this message translates to:
  /// **'Tigrinya'**
  String get tigrinya;

  /// No description provided for @somali.
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get somali;

  /// No description provided for @moreLanguages.
  ///
  /// In en, this message translates to:
  /// **'More…'**
  String get moreLanguages;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak · grace day available'**
  String streakLabel(int count);

  /// No description provided for @chapterOf.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter}'**
  String chapterOf(int chapter);

  /// No description provided for @tapToChangeChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter} · tap to change'**
  String tapToChangeChapter(int chapter);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en', 'om', 'so', 'ti'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
    case 'so':
      return AppLocalizationsSo();
    case 'ti':
      return AppLocalizationsTi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
