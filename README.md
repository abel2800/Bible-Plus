# BiblePulse

BiblePulse is a Flutter Bible reading and study application with an Android project in this repository. Its core reading experience is designed to work offline, with local study tools, daily reading progress, and optional audio and cloud services.

## Current scope

The maintained platform target in this checkout is Android. The repository does not include an iOS project or claim a release process for desktop or web platforms.

| Item | Value |
| --- | --- |
| Application ID | `app.biblepulse.reader` |
| Flutter package | `bible_pulse` |
| Version | `1.0.1+2` |
| Dart constraint | `>=3.6.0 <4.0.0` |
| Flutter constraint | `>=3.27.0` |
| Android namespace | `app.biblepulse.reader` |

## Features

### Bible reading

- Local Bible reading with book and chapter navigation
- Bundled WEB, NASV, and Amharic Bible data
- Additional Bible packages available through the online Bible store
- Search and direct navigation to Scripture results
- Adjustable reading appearance and text comfort settings
- Verse actions for copying, sharing, highlighting, bookmarking, and notes
- Parallel reading support when a second installed version is available

### Daily reading and study

- Verse of the Day
- Reading streak, milestone progress, and reading heatmap
- Local prayer journal
- Study screen for saved notes, bookmarks, and highlights
- Limited built-in cross-reference data for supported passages

### Audio

- World English Bible audio streamed from eBible.org
- Chapter playback, queue, speed control, sleep timer, and sharing
- Local caching and download handling where the audio source permits it
- Optional Bible Brain text and audio integrations through build-time configuration

Audio is not bundled in the repository as a complete offline audio library. The default WEB audio catalog entry is a public-domain stream that can be cached as chapters are played or downloaded.

### Verse Studio

- Scripture artwork and wallpaper creation
- Templates, typography, colors, and photo backgrounds on supported Android devices
- Still-image sharing and export
- Animated GIF export for Verse Studio designs

### Android integration

- Background audio playback
- Local notifications and scheduled reminders
- Android home-screen widget integration
- App links for supported shared audio links

## Content and availability

The Bible Store catalog describes the available Bible packages, their licenses, and their installation mode. Some entries are bundled assets; others are placeholders that require licensed data or Bible Brain access. A catalog entry does not by itself mean that a translation is installed or available offline.

The user interface includes English, Amharic, Afaan Oromo, Tigrinya, and Somali localizations. This does not mean that Scripture text or audio is available in every listed language.

Content metadata is stored in:

- `assets/catalog/bible_catalog.json`
- `assets/catalog/audio_catalog.json`
- `assets/content_manifest.json`

Rights and redistribution status must be checked before adding or shipping new content.

## Optional services

### Firebase

Firebase is disabled unless all required build-time values are supplied:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
```

When configured, the app can initialize Firebase Authentication and Cloud Firestore. Cloud-dependent community, group, and synchronization features remain configuration-gated.

### Bible Brain

Bible Brain text access requires `BIBLE_BRAIN_API_KEY`. Bible Brain audio additionally requires:

```text
BIBLE_BRAIN_BIBLE_IDS_JSON
BIBLE_BRAIN_MEDIA_HOSTS
```

These values are supplied with `--dart-define` and must not be committed.

## Architecture

The app uses a layered Flutter structure with `provider` for application state:

```text
Screens and widgets
  -> Providers
  -> Services and repositories
  -> Local database, preferences, bundled assets, and optional cloud services
```

Important areas of the codebase:

```text
lib/config/       Build-time configuration and capability flags
lib/l10n/         Generated and fallback localization resources
lib/models/       Bible and study domain models
lib/providers/    Application state providers
lib/repositories/ Persistence and data access abstractions
lib/screens/      App screens and navigation destinations
lib/services/     Bible, audio, study, notification, and integration services
lib/studio/       Verse Studio rendering and export logic
lib/widgets/      Shared interface components
android/          Android application and Gradle configuration
assets/           Bible packages and catalog metadata
test/             Flutter widget tests
tools/            Content and maintenance scripts
```

The primary navigation destinations are Home, Read, Study, Search, and Settings. Other screens are opened from those destinations or when their corresponding capability is enabled.

## Setup

Install Flutter and configure an Android SDK, device, or emulator. Then run:

```bash
flutter pub get
flutter run -d android
```

For a local release artifact:

```bash
flutter build apk --release
```

For an Android App Bundle:

```bash
flutter build appbundle --release
```

For architecture-specific APKs:

```bash
flutter build apk --release --split-per-abi
```

Release signing uses these environment variables when a publishable signed artifact is required:

```text
BIBLEPULSE_ANDROID_KEYSTORE
BIBLEPULSE_ANDROID_STORE_PASSWORD
BIBLEPULSE_ANDROID_KEY_ALIAS
BIBLEPULSE_ANDROID_KEY_PASSWORD
```

Without those values, the Android release configuration falls back to the debug keystore for local or verification builds. Such artifacts are not suitable for store publication.

## Verification

The repository’s local checks are:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test --no-fatal-infos
flutter test --exclude-tags golden
```

GitHub Actions is configured to run formatting, analysis, Flutter tests, content-manifest validation, and Android APK/App Bundle builds. The current Flutter test directory contains the shared widget test; Firebase rule tests live separately under `firebase-tests`.
