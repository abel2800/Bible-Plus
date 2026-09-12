# Bible Plus

Bible Plus is a Flutter Bible reading and study app with offline-first Scripture, local study tools, daily reading progress, optional audio, and a unified gold reading experience on Android and web.

Website: https://bibleplus-7.vercel.app/

## Current scope

| Item | Value |
| --- | --- |
| Product name | Bible Plus |
| Flutter package | `bible_pulse` |
| Application ID | `app.biblepulse.reader` |
| Version | `1.1.0+5` |
| Dart constraint | `>=3.6.0 <4.0.0` |
| Flutter constraint | `>=3.27.0` |
| Primary targets | Android, Web (Chrome) |
| Android namespace | `app.biblepulse.reader` |

Android is the primary install target. Web is supported for development and hosted builds. iOS is not included in this repository.

## Features

### Bible reading

- Local Bible reading with book/chapter navigation
- Gold-themed reader UI with focus mode, verse popup actions, and chapter arrows
- HTML-style sheets for catalog, reading settings, notes, and translations
- Bundled WEB, KJV, ASV, NASV, and Amharic Bible data
- Additional packages through the online Bible Store
- Search and direct navigation to Scripture results
- Adjustable reading appearance: themes, font size, line spacing, font family
- Verse numbers, red-letter words, and focus-on-open preferences
- Verse actions for copy, share, highlight, bookmark, and notes
- Parallel reading when Amharic is available

### Daily reading and study

- Verse of the Day
- Reading streak, milestone progress, reading heatmap, and daily reading goal
- Local prayer journal
- Study screen for saved notes, bookmarks, and highlights
- Limited built-in cross-reference data for supported passages

### Audio

- Unified gold audio bar and full audio sheet across the app
- World English Bible audio streamed from eBible.org
- Chapter playback, queue, speed control, sleep timer, download, and sharing
- Local caching where the audio source permits it
- Optional Bible Brain text and audio integrations through build-time configuration

Audio is not bundled as a complete offline library. The default WEB audio catalog entry is a public-domain stream that can be cached as chapters are played or downloaded.

### Verse Studio

- Scripture artwork and wallpaper creation
- Templates, typography, colors, and photo backgrounds on supported Android devices
- Still-image sharing and export
- Animated GIF export for Verse Studio designs

### Platform integration

- Background audio playback on Android
- Local notifications and scheduled reminders
- Android home-screen widget integration
- App links for supported shared audio links
- Web build output for hosted deployments

## Content and availability

The Bible Store catalog describes available Bible packages, licenses, and installation mode. Some entries are bundled assets; others require licensed data or Bible Brain access. A catalog entry does not by itself mean a translation is installed or available offline.

The user interface includes English, Amharic, Afaan Oromo, Tigrinya, and Somali localizations. This does not mean Scripture text or audio is available in every listed language.

Content metadata is stored in:

- `assets/catalog/bible_catalog.json`
- `assets/catalog/audio_catalog.json`
- `assets/content_manifest.json`

Rights and redistribution status must be checked before adding or shipping new content.

## Latest update

Version **1.1.0** unifies the reading experience and strengthens release verification:

- Gold reading UI across catalog, settings, notes, and audio
- Single audio experience from Read, Home, and deep links
- Reader preferences: verse numbers, red-letter, focus-on-open, parallel reading
- Daily reading goal and dashboard progress
- Bible Plus branding and launcher icons
- Web platform support in CI and release artifacts
- CI verifies formatting, analysis, tests, manifest, Android, and web builds

Download the latest Android release from the [Bible Plus website](https://bibleplus-7.vercel.app/) or the [GitHub releases page](https://github.com/abel2800/Bible-Plus/releases).

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

### YouVersion downloads

YouVersion credentials are compiled into the Android release; GitHub secrets are not available to an already-installed APK. Add `YOUVERSION_APP_KEY` as a repository secret, then create a new release build. For individually licensed offline versions, also add `YOUVERSION_OFFLINE_VERSION_IDS_JSON` with a JSON array such as `["1260"]`. Set `YOUVERSION_BULK_DOWNLOAD_LICENSED` to `true` only when the rights holder has confirmed bulk offline distribution.

The release workflow accepts an empty YouVersion configuration, so builds can publish without that optional integration.

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
web/              Web host files and PWA manifest
assets/           Bible packages and catalog metadata
test/             Flutter tests
tools/ci/         Verification and release helper scripts
```

The primary navigation destinations are Home, Read, Study, Search, and Settings.

## Setup

Install Flutter and configure an Android SDK, device, emulator, or Chrome. Then run:

```bash
flutter pub get
flutter run -d android
```

For local web development:

```bash
flutter run -d chrome
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

For a web build:

```bash
flutter build web --release
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

Run the full local verification suite:

```bash
bash tools/ci/verify.sh
```

On Windows PowerShell, run the equivalent steps:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test --no-fatal-infos
flutter test --exclude-tags golden
python tools/content/validate_manifest.py
flutter build web --release
```

Individual checks:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test --no-fatal-infos
flutter test --exclude-tags golden
python tools/content/validate_manifest.py
```

## CI and release

### Continuous integration

GitHub Actions workflow: `.github/workflows/ci.yml`

On every push and pull request, CI runs:

1. Format check (`lib`, `test`)
2. Static analysis
3. Flutter tests
4. Approved content manifest validation
5. Web release build
6. Android APK and App Bundle build
7. Firestore rules tests

### Publishing a release

1. Bump the version in `pubspec.yaml`:

```yaml
version: 1.1.0+5
```

Use `MAJOR.MINOR.PATCH+BUILD`. The tag must match the version name before `+`.

2. Commit your changes locally.

3. Push your branch, confirm CI passes.

4. Create and push a matching tag:

```bash
git tag v1.1.0
git push origin v1.1.0
```

5. The release workflow (`.github/workflows/release.yml`) will:

- Run the same verification checks as CI
- Validate that `v1.1.0` matches `pubspec.yaml`
- Build Android APKs, App Bundle, and web zip
- Publish a GitHub Release named `Bible Plus v1.1.0`

You can also trigger the release workflow manually from GitHub Actions (`workflow_dispatch`). In that case it uses the version from `pubspec.yaml` and creates/updates release `v{version}`.

Release assets include:

- `bible-plus-{version}-arm64-v8a.apk`
- `bible-plus-{version}-armeabi-v7a.apk`
- `bible-plus-{version}-x86_64.apk`
- `bible-plus-{version}.aab`
- `bible-plus-{version}-web.zip`
- Legacy aliases: `biblepulse-arm64-v8a.apk`, etc.

### Version helper

```bash
bash tools/ci/read_version.sh
```

Prints `APP_VERSION`, `APP_VERSION_NAME`, and `APP_BUILD_NUMBER` from `pubspec.yaml`.
