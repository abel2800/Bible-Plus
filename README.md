# BiblePulse

BiblePulse is an offline-first Bible reading and study app built with Flutter. It runs on Android, iOS, web, Windows, macOS, and Linux.

The app focuses on simple Scripture reading, local study tools, audio playback, and daily reading habits. Core reading works offline. Optional services such as Firebase, Bible Brain, community features, and licensed content stay disabled until they are configured.

## Project Info

| Item | Value |
|---|---|
| Package | `bible_pulse` |
| App ID | `app.biblepulse.reader` |
| Version | `1.0.1+2` |
| Flutter | 3.44.1 in CI, `>=3.27.0` supported |
| Dart | `>=3.6.0 <4.0.0` |
| Repository | [abel2800/Bible-Plus](https://github.com/abel2800/Bible-Plus) |

## Features

### Bible Reading

- Offline World English Bible (WEB), bundled with the app.
- King James Version (KJV) and American Standard Version (ASV) available from the in-app Bible Store.
- Book and chapter navigation.
- Last-read position restore.
- Search results can jump directly to the selected verse.
- Light, dark, and eye-comfort reader themes.
- Adjustable font size, line spacing, and Scripture font.
- Clean verse display with Strong's markup removed.

### Search

- Search across Scripture with Old Testament, New Testament, and All filters.
- SQLite FTS5 search on Android, iOS, and macOS.
- In-memory search index on web, Windows, and Linux.

### Study Tools

Tap or long-press a verse to:

- Highlight it.
- Add or edit a note.
- Bookmark it.
- Copy or share it.
- Create a verse card or wallpaper where supported.
- View cross-references when available.

Guest study data is stored locally. Android, iOS, and macOS use SQLite. Web, Windows, and Linux use SharedPreferences fallback storage.

When cloud sync is enabled, deleted items are tracked with tombstones and conflicts are resolved with last-write-wins behavior.

### Audio Bible

- Chapter queue with auto-advance.
- Continue into the next book.
- Now Playing screen with artwork, seek, speed, sleep timer, download, queue, chapter picker, and sharing.
- Mini player while audio is active.
- Reading and listening history are kept separate.
- Background playback on mobile.
- Web Media Session support where available.
- Offline chapter cache.
- Listen links through `biblepulse://listen` deep links and configured store URLs.

### Daily Reading

- Verse of the Day.
- Reading streaks with one grace day per seven-day window.
- Progress toward reading milestones.
- Reading heatmap on the Home screen.
- Optional morning and evening reminders on Android and iOS.
- Prayer journal with optional verse links.
- Home widget support on Android and iOS.

### Verse Studio

Verse Studio lets users create Scripture cards and wallpapers with:

- Layouts.
- Fonts.
- Colors.
- Photo backgrounds.
- Still image export.
- MP4 export where FFmpeg is available.
- GIF fallback on limited platforms.

Community publishing is available only when cloud and community features are enabled.

### Languages

The app UI supports:

- English
- Amharic
- Afaan Oromo
- Tigrinya
- Somali

Non-English Scripture texts are not bundled yet. They are placeholders until redistribution rights are approved and documented.

## Platforms

| Platform | Local Storage | Notifications | Gallery Export | Audio | Cloud |
|---|---|---|---|---|---|
| Android | SQLite | Yes | Yes | Yes | Optional |
| iOS | SQLite | Yes | Yes | Yes | Optional |
| macOS | SQLite | No | No | Yes | Optional |
| Windows | Preferences | No | No | Yes | Optional |
| Linux | Preferences | No | No | Yes | Optional |
| Web | Preferences | No | No | Yes | Optional |

Public-domain WEB Henson audio works without API keys. Bible Brain and Firebase require build-time configuration.

Minimum iOS deployment target: **15.0**.

## Main Screens

| Screen | Purpose |
|---|---|
| Home | Greeting, streak, heatmap, Verse of the Day, Continue Reading, Continue Listening |
| Bible | Chapter reader, book/version picker, verse actions, playback controls |
| Now Playing | Full audio player with queue, sleep timer, speed, download, and sharing |
| Plans | Highlights, notes, and bookmarks |
| Discover | Scripture search |
| You | Settings, appearance, language, reminders, cache, and preferences |
| Bible Store | Install public-domain Bible texts |
| Audio Store | Install or access audio packages |
| Prayer Journal | Private prayer entries |
| Verse Studio | Create and export Scripture artwork |

Auth, groups, community, and extra catalogs only appear when the required configuration is available.

## Design

BiblePulse uses a warm parchment and dark navy visual style with gold accents.

| Token | Value | Use |
|---|---|---|
| Gold | `#C08A28` | Primary actions, active navigation, verse numbers |
| Soft gold | `#E8C766` | Gradients and dark-mode accents |
| Vermilion | `#A83232` | Destructive actions |
| Teal | `#1E7F72` | Progress and positive status |

| Surface | Light | Dark |
|---|---|---|
| App background | `#F6F0E1` | `#10182A` |
| Surface | `#FFFDF8` | `#161F33` |
| Elevated | `#FBF4E4` | `#1B2540` |
| Border | `#DED0AC` | `#2A3654` |
| Main text | `#201A10` | `#F1E9D6` |
| Soft text | `#6B5D42` | `#B7AD90` |

Typography:

- Fraunces for brand and titles.
- Source Serif 4 for Scripture.
- Inter for app UI.
- Noto Serif Ethiopic for Ethiopic UI text.

## Architecture

BiblePulse uses a layered Flutter structure with Provider for presentation state.

```text
UI screens and widgets
  -> Providers
  -> Services and repositories
  -> Local database, preferences, assets, and optional cloud services
```

Main ideas:

- Core reading and study work offline.
- Optional integrations stay hidden until configured.
- Content must be listed in `assets/content_manifest.json`.
- Startup waits for real app readiness instead of using a fixed delay.
- Platform features are controlled through `AppCapabilities`.

## Key Packages

| Area | Packages |
|---|---|
| State | `provider` |
| Local database | `sqflite` |
| Preferences and paths | `shared_preferences`, `path_provider` |
| Audio | `just_audio`, `just_audio_background`, `audio_session`, `audio_service` |
| Deep links | `app_links` |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Cloud | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Networking | `http`, `connectivity_plus` |
| Sharing and images | `screenshot`, `image_gallery_saver_plus`, `share_plus`, `permission_handler`, `image_picker`, `image` |
| Motion export | `ffmpeg_kit_flutter_new` |
| Home widget | `home_widget` |
| Fonts | `google_fonts` |

## Project Structure

```text
lib/
  config/          Cloud, audio, share URLs, and capability flags
  l10n/            UI strings
  models/          Domain models
  providers/       App state
  repositories/    Repository boundaries
  screens/         App screens
  services/        Bible, search, database, audio, cache, links, sync
  studio/          Verse Studio
  utils/           Theme helpers, streak copy, greetings, Scripture cleanup
  widgets/         Shared widgets and design components

assets/
  bible/           WEB, KJV, and ASV data
  catalog/         Bible and audio catalogs
  content_manifest.json

docs/
  CONTENT_SOURCES.md
  INTEGRATIONS_AND_RELEASE.md

tools/
  ci/
  content/
  scripture/

test/
integration_test/
firebase-tests/
.github/workflows/ci.yml
```

## Getting Started

### Requirements

- Flutter 3.44.1, or a compatible stable Flutter version.
- Dart SDK `>=3.6.0 <4.0.0`.
- Python 3 if regenerating Scripture assets.
- Android Studio and Android SDK for Android builds.

### Install Dependencies

```powershell
flutter pub get
```

### Run

```powershell
flutter run -d chrome --no-web-resources-cdn
```

Other examples:

```powershell
flutter run -d windows
flutter run -d android
```

VS Code users can use the **BiblePulse (Chrome)** launch config in `.vscode/launch.json`.

## Local Checks

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
BIBLE_BRAIN_BIBLE_IDS_JSON={"WEB":"approved-bible-id"}
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
