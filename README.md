# BiblePulse

BiblePulse is an offline-first Bible reading and study app built with Flutter. It supports Android, iOS, web, Windows, macOS, and Linux.

The app is designed to keep Scripture reading and study focused while enabling optional audio, reminders, journaling, and artwork export. Core Bible reading works offline, and optional integrations such as Firebase, Bible Brain, and licensed catalogs are hidden until configured.

## Project Info

| Item | Value |
|---|---|
| Package | `bible_pulse` |
| App ID | `app.biblepulse.reader` |
| Version | `1.0.1+2` |
| Flutter | 3.44.1 (CI); compatible with `>=3.27.0` |
| Dart | `>=3.6.0 <4.0.0` |
| Repository | [abel2800/Bible-Plus](https://github.com/abel2800/Bible-Plus) |

## App Overview

BiblePulse combines an offline Scripture reader with study tools, audio playback, daily reading features, and scripture artwork creation.

### Core Reading

- Offline World English Bible (WEB) bundled with the app.
- Optional KJV and ASV installs from the in-app Bible Store.
- Book and chapter navigation with persistent last-read restore.
- Scripture search with direct verse navigation.
- Reader themes and adjustable text size, spacing, and font.
- Clean verse display with Strong's markup removed.

### Study Tools

- Highlight verses.
- Add, edit, and delete notes.
- Bookmark verses.
- Copy or share verse text.
- Create verse cards and wallpapers.
- View cross-references when available.
- Local study storage by default; optional cloud sync is gated.

### Audio Bible

- Public-domain WEB audio support without API keys.
- Chapter queue with auto-advance.
- Full audio player with artwork, playback controls, queue, speed, sleep timer, and sharing.
- Mini player while audio is active.
- Background playback on mobile.
- Offline audio caching for supported chapters.
- Optional Bible Brain online audio and text when configured.

### Daily Reading

- Verse of the Day.
- Reading streak tracker with a weekly grace day.
- Milestone progress and heatmap.
- Prayer journal with verse links.
- Optional morning and evening reminders on Android and iOS.
- Home widget support on Android and iOS.

### Verse Studio

- Design Scripture cards and wallpapers.
- Customize layouts, fonts, colors, and photo backgrounds.
- Export still images for sharing.
- Export MP4 when FFmpeg is available.
- GIF fallback on platforms without MP4 support.

### Localization

- UI support for English, Amharic, Afaan Oromo, Tigrinya, and Somali.
- Adjustable text size and comfort modes.
- Unavailable licensed translations are hidden from the Bible Store.

## Platforms

| Platform | Storage | Notifications | Export | Audio | Cloud |
|---|---|---|---|---|---|
| Android | SQLite | Yes | Yes | Yes | Optional |
| iOS | SQLite | Yes | Yes | Yes | Optional |
| macOS | SQLite | No | No | Yes | Optional |
| Windows | Preferences | No | No | Yes | Optional |
| Linux | Preferences | No | No | Yes | Optional |
| Web | Preferences | No | No | Yes | Optional |

The app ships with public-domain WEB reading and audio. Optional Bible Brain and Firebase capabilities require build-time configuration.

## Screens and Flows

| Screen | Purpose |
|---|---|
| Home | Greeting, streak, heatmap, Verse of the Day, continue reading/listening |
| Bible | Scripture reader, book/version picker, verse actions, playback controls |
| Now Playing | Audio player with queue, sleep timer, speed, download, and share |
| Bible Store | Install optional Bible texts and discover available translations |
| Audio Store | Install or enable audio packages |
| Prayer Journal | Private prayer entries |
| Verse Studio | Design and export Scripture artwork |
| Discover | Search Scripture and browse results |
| You | Settings, appearance, language, reminders, cache, and preferences |

Optional auth, community, and licensed catalogs appear only after their required configuration is present.

## Architecture

BiblePulse follows a layered Flutter architecture with `provider` for state management.

```text
UI screens and widgets
  -> Providers
  -> Services and repositories
  -> Local database, preferences, assets, and optional cloud services
```

Core principles:

- Offline-first reading and study.
- Optional integrations remain hidden until configured.
- Content is declared in `assets/content_manifest.json`.
- Platform features are gated through `AppCapabilities`.

## Key Packages

| Area | Packages |
|---|---|
| State | `provider` |
| Storage | `sqflite`, `shared_preferences` |
| Paths | `path_provider` |
| Audio | `just_audio`, `just_audio_background`, `audio_session`, `audio_service` |
| Deep links | `app_links` |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Cloud | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Networking | `http`, `connectivity_plus` |
| Sharing | `screenshot`, `image_gallery_saver_plus`, `share_plus`, `permission_handler`, `image_picker` |
| Export | `ffmpeg_kit_flutter_new` |
| Home widget | `home_widget` |
| Fonts | `google_fonts` |

## Project Structure

```text
lib/
  config/          App capabilities, audio, and cloud configuration
  l10n/            Localization strings
  models/          Domain models
  providers/       Application state providers
  repositories/    Data repositories and storage adapters
  screens/         UI screens
  services/        Bible, audio, search, cache, links, and sync services
  studio/          Verse Studio features
  utils/           Theme helpers and utilities
  widgets/         Shared UI components

assets/
  bible/           Bible JSON payloads
  catalog/         Store and audio catalog metadata
  content_manifest.json

tools/
  ci/
  content/
  scripture/

test/
integration_test/
firebase-tests/
.github/workflows/ci.yml
```

## Build and Run

### Requirements

- Flutter 3.44.1 or compatible stable release.
- Dart SDK `>=3.6.0 <4.0.0`.
- Python 3 for content generation scripts.
- Android SDK for Android builds.

### Setup

```powershell
flutter pub get
```

### Run locally

```powershell
flutter run -d chrome --no-web-resources-cdn
flutter run -d android
flutter run -d windows
```

### Build release

```powershell
flutter build apk --release
flutter build ios --release --no-codesign
flutter build macos --release
flutter build windows --release --no-pub
flutter build linux --release
flutter build web --release --no-wasm-dry-run
```

## Optional Integrations

### Bible Brain

Bible Brain unlocks online discovery, streaming text, and audio when configured.
Required build defines:

```text
BIBLE_BRAIN_API_KEY
BIBLE_BRAIN_BIBLE_IDS_JSON
BIBLE_BRAIN_MEDIA_HOSTS
```

If only `BIBLE_BRAIN_API_KEY` is provided, the app can discover available translations and enable online text where permitted.

### Firebase

Firebase is optional and requires Dart define values for production configuration.

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN` (optional)
- `FIREBASE_STORAGE_BUCKET` (optional)

For local emulator tests:

```powershell
FIREBASE_USE_EMULATORS=true
FIREBASE_EMULATOR_HOST=localhost
```

### Notifications and Widgets

- Notifications request permission on supported mobile platforms.
- Android widgets are supported via `HomeWidgetService`.
- iOS widget support is available when a Widget Extension is added in Xcode.

## Content and Licensing

The app ships with public-domain WEB text and audio. Optional KJV/ASV texts are available in the Bible Store. Unavailable or licensed translations are hidden unless access is configured.

All shipped content must be declared in `assets/content_manifest.json`.

## Local Checks

Perform local project validation with:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze lib test integration_test --no-fatal-infos
flutter test --exclude-tags golden
flutter build web --release --no-wasm-dry-run
```

Android release build:

```powershell
flutter build apk --release --no-pub
```

## Signing

### Android release signing

Use environment variables for Play Store signing:

```text
BIBLEPULSE_ANDROID_KEYSTORE
BIBLEPULSE_ANDROID_STORE_PASSWORD
BIBLEPULSE_ANDROID_KEY_ALIAS
BIBLEPULSE_ANDROID_KEY_PASSWORD
```

### Windows signing

If signing is required after build:

```powershell
BIBLEPULSE_WINDOWS_CERTIFICATE
BIBLEPULSE_WINDOWS_CERTIFICATE_PASSWORD
BIBLEPULSE_WINDOWS_TIMESTAMP_URL
powershell -ExecutionPolicy Bypass -File tools/release/sign_windows.ps1
```

## Notes

- The repository no longer contains separate docs folders; the main app documentation is consolidated in this README.
- Generated folders such as `.dart_tool`, `build`, `.idea`, and `.vscode` have been removed from the repository.


```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze lib test integration_test
python tools/content/validate_manifest.py
flutter test --exclude-tags golden
flutter test test/goldens
flutter build web --release --no-wasm-dry-run
```

## Build APK

```powershell
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

GitHub Actions also uploads unsigned Android verification builds on every push.

## Rebuild WEB Scripture

```powershell
powershell -ExecutionPolicy Bypass -File tools/scripture/fetch_web.ps1
```

Output:

```text
assets/bible/web.json
```

The converter requires approved redistribution information before generated Scripture assets can be used.

## Optional Integrations

Full setup notes are in [docs/INTEGRATIONS_AND_RELEASE.md](docs/INTEGRATIONS_AND_RELEASE.md).

### Firebase

Pass Firebase values with `--dart-define`. Do not commit secrets.

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
FIREBASE_AUTH_DOMAIN
FIREBASE_STORAGE_BUCKET
FIREBASE_USE_EMULATORS=true
BIBLEPULSE_ENABLE_COMMUNITY=true
```

Firestore rules and emulator tests are in `firestore.rules` and `firebase-tests/`.

### Bible Brain

```text
BIBLE_BRAIN_API_KEY
BIBLE_BRAIN_BIBLE_IDS_JSON={"WEB":"approved-bible-id","AMH":"AMHABC"}
BIBLE_BRAIN_MEDIA_HOSTS=approved.cdn.host
```

Without these values, the app still uses public-domain WEB Henson audio.

### Notifications

Android and iOS request notification permission when the user enables Verse and streak reminders in Settings.

## Content and Licensing

Only content with verified redistribution rights should be shipped with the app. Each content file must be listed in `assets/content_manifest.json` with attribution, redistribution status, and SHA-256 checksum.

| Content | Status |
|---|---|
| World English Bible | Bundled, public domain |
| King James Version | Store install, public domain |
| American Standard Version | Store install, public domain |
| WEB Henson audio | Default stream/cache, public domain |
| Amharic, Oromo, Tigrinya, Somali Scripture | Not bundled yet |
| Bible Brain audio | Available only with configuration and rights record |
| Devotionals, plans, hymns | Catalog support exists, no licensed payloads bundled |

See [docs/CONTENT_SOURCES.md](docs/CONTENT_SOURCES.md) for details.

## Testing and CI

GitHub Actions runs on pushes and pull requests.

| Job | Checks |
|---|---|
| verify | Format, analyze, manifest validation, tests, web build |
| android | APK and App Bundle |
| windows | Windows build and golden tests |
| linux | Linux release build |
| apple | iOS no-codesign build and macOS release build |
| firebase-emulators | Firestore security rules |
| web-integration | Chrome smoke test |
| publish-builds | Packages release artifacts on `main` |

Golden tests run on Windows runners to reduce pixel differences.

Windows CI strips the FFmpeg Kit desktop plugin before building so desktop verification does not need the heavy native download.

Run Firestore rule tests locally with:

```powershell
npm ci --prefix firebase-tests
npx firebase-tools@latest emulators:exec --only firestore "npm --prefix firebase-tests test"
```

## Release Notes

CI artifacts are verification builds.

- Android builds use debug signing unless release keystore secrets are configured.
- Download `android-verification-apk`, unzip it, and install `app-release.apk`.
- Do not install the `.aab` file directly.
- Windows signing is documented in the integrations guide.
- Confirm ownership of `app.biblepulse.reader` before store submission.
- Do not commit keystores, API keys, or production secrets.

## Security

- Publishable Android builds require explicit release keystore environment variables.
- Firestore rules isolate user study data by owner.
- Bible Brain audio only accepts configured HTTPS media hosts.
- Exact-alarm Android permissions are not requested.
- Content checksums protect bundled assets from accidental changes.

## Documentation

| Document | Contents |
|---|---|
| [docs/CONTENT_SOURCES.md](docs/CONTENT_SOURCES.md) | Scripture sources, licensing notes, and catalog policy |
| [docs/INTEGRATIONS_AND_RELEASE.md](docs/INTEGRATIONS_AND_RELEASE.md) | Firebase, Bible Brain, notifications, and signing |

## License and Contributions

This repository contains the application code for BiblePulse. Bundled Scripture and public-domain audio remain under their original upstream terms.

Before adding translations, devotionals, hymns, or proprietary audio, update the content manifest and document redistribution rights.

When contributing:

- Keep changes focused.
- Preserve offline reading and local study behavior.
- Keep optional integrations behind configuration.
- Run format, analyze, and tests before submitting changes.
