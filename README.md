# Bible Plus

**Read. Listen. Reflect.**

Bible Plus is an offline-first Flutter application for Bible reading, listening, and personal study. It ships with bundled Scripture, local study tools, daily reading rhythm, optional audio, and a unified gold reading experience on **Android** and **Web**.

| | |
|---|---|
| **Website** | [bibleplus-7.vercel.app](https://bibleplus-7.vercel.app/) |
| **Releases** | [GitHub Releases](https://github.com/abel2800/Bible-Plus/releases) |
| **Repository** | [abel2800/Bible-Plus](https://github.com/abel2800/Bible-Plus) |

---

## Download

Install the latest Android build from:

- [Bible Plus website](https://bibleplus-7.vercel.app/) — recommended for most users
- [GitHub Releases](https://github.com/abel2800/Bible-Plus/releases/latest) — direct APK, AAB, and web zip downloads

The website links to `biblepulse-arm64-v8a.apk`, which is the recommended build for modern Android phones.

---

## Project overview

| Item | Value |
| --- | --- |
| Product name | Bible Plus |
| Flutter package | `bible_pulse` |
| Application ID | `app.biblepulse.reader` |
| Current version | `1.1.1+6` |
| Dart SDK | `>=3.6.0 <4.0.0` |
| Flutter SDK | `>=3.27.0` |
| CI Flutter version | `3.44.1` |
| Primary targets | Android, Web (Chrome) |
| Android namespace | `app.biblepulse.reader` |

Android is the primary install and distribution target. Web is supported for development, CI verification, and hosted deployments. iOS is not included in this repository.

---

## Features

### Bible reading

- Book and chapter navigation with a gold-themed catalog sheet (Old/New Testament, search, chapter grid)
- Reader settings sheet: font family, size, line spacing, themes, verse numbers, red-letter text, focus-on-open, and parallel reading
- Verse popup actions: copy, share, highlight, bookmark, and notes
- Bundled translations including **WEB**, **KJV**, **ASV**, **NASV**, and **Amharic** packages
- Additional translations through the in-app **Bible Store**
- Full-text Scripture search with direct navigation to results
- Parallel reading when Amharic and another translation are available

### Daily reading and study

- Verse of the Day on the home dashboard
- Reading streak, milestones, heatmap, and configurable **daily reading goal**
- Local prayer journal
- Study screen for notes, bookmarks, and highlights
- Built-in cross-reference data for supported passages
- Reading plans with local progress tracking

### Audio

- Unified gold mini-player and full audio sheet across Home, Read, and deep links
- World English Bible audio streamed from [eBible.org](https://ebible.org/)
- Chapter playback, queue, speed control, sleep timer, download, and sharing
- Local chapter caching where the source permits it
- Optional Bible Brain text and audio through build-time configuration

Audio is not shipped as a complete offline library. The default WEB catalog entry is a public-domain stream that can be cached as chapters are played or downloaded.

### Verse Studio

- Scripture artwork and wallpaper creation
- Templates, typography, colors, and photo backgrounds (Android)
- Still-image sharing and export
- Animated GIF export for Verse Studio designs

### Platform integration

- Background audio playback on Android
- Local notifications and scheduled reminders
- Android home-screen widget
- App links for supported shared audio URLs
- Web build output for hosted deployments (PWA-ready host files)

---

## Platform support

| Capability | Android | Web |
| --- | --- | --- |
| Bible reading (bundled assets) | Yes | Yes |
| Local SQLite database | Yes | No |
| Notes, highlights, bookmarks | Yes | Limited / prefs-based |
| Scripture search (FTS) | Yes | In-memory fallback |
| Background audio | Yes | Browser-dependent |
| Notifications | Yes | No |
| Verse Studio export | Yes | No |
| Firebase / community | Optional | Optional |

On Android, the app uses a bundled SQLite build with FTS5 support and falls back to standard SQL search when full-text search is unavailable on a device.

---

## Content and licensing

Bible packages, licenses, and install modes are defined in the catalog files:

| File | Purpose |
| --- | --- |
| `assets/catalog/bible_catalog.json` | Bible translations and install sources |
| `assets/catalog/audio_catalog.json` | Audio narrations and stream metadata |
| `assets/content_manifest.json` | Approved bundled assets, checksums, and license metadata |

Bundled Scripture includes public-domain and approved entries validated in CI by `tools/content/validate_manifest.py`.

**Important:** A catalog entry does not guarantee that a translation is installed, available offline, or licensed for redistribution. Verify rights and attribution before adding or shipping new content.

### UI languages

The interface supports **English**, **Amharic**, **Afaan Oromo**, **Tigrinya**, and **Somali**. UI localization does not imply that Scripture text or audio is available in every listed language.

---

## Architecture

Bible Plus uses a layered Flutter structure with [`provider`](https://pub.dev/packages/provider) for application state:

```text
Screens & widgets
       ↓
   Providers
       ↓
Services & repositories
       ↓
Local database · SharedPreferences · bundled assets · optional cloud
```

### Repository layout

```text
lib/
  config/          Build-time flags (Firebase, audio, YouVersion, capabilities)
  l10n/            Localization resources (ARB + generated)
  models/          Domain models (Bible, study, audio, community)
  providers/       Application state
  repositories/    Data access abstractions
  screens/         App screens and navigation
  services/        Bible, audio, search, notifications, sync
  studio/          Verse Studio rendering and export
  utils/           Shared helpers (SQLite init, theme, navigation)
  widgets/         Reusable UI components and design system

android/           Android app, Gradle, and widget configuration
web/               Web host files and PWA manifest
website/           Static landing page (deployed to Vercel)
assets/            Bundled Bibles, catalogs, branding
test/              Unit and widget tests
tools/ci/          Verification scripts and version helpers
tools/content/     Content manifest validation
.github/workflows/ CI and release automation
```

Primary navigation: **Home**, **Read**, **Study**, **Search**, and **Settings**.

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.27.0` (CI uses `3.44.1`)
- Android SDK for device/emulator builds
- Chrome for web development
- Python 3 for content manifest validation
- Node.js 20+ (optional, for Firestore rules tests)

### Install and run

```bash
git clone https://github.com/abel2800/Bible-Plus.git
cd Bible-Plus
flutter pub get
flutter run -d android
```

Web development:

```bash
flutter run -d chrome
```

### Build release artifacts

```bash
# Universal release APK
flutter build apk --release

# Split APKs per CPU architecture (recommended for distribution)
flutter build apk --release --split-per-abi

# Google Play App Bundle
flutter build appbundle --release

# Web build
flutter build web --release
```

---

## Configuration

Secrets and API keys are **never committed**. They are supplied through environment variables, `--dart-define`, or GitHub Actions secrets at build time.

### Firebase (optional)

Firebase is disabled unless all required values are provided:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
```

When configured, the app can use Firebase Authentication and Cloud Firestore for community, groups, and study sync features.

### Bible Brain (optional)

| Variable | Purpose |
| --- | --- |
| `BIBLE_BRAIN_API_KEY` | Bible Brain API access |
| `BIBLE_BRAIN_BIBLE_IDS_JSON` | Enabled Bible ID mappings |
| `BIBLE_BRAIN_MEDIA_HOSTS` | Allowed media hosts for audio |

Request an API key at [4.dbt.io/api_key/request](https://4.dbt.io/api_key/request).

### YouVersion (optional)

YouVersion credentials are compiled into release builds via GitHub Actions secrets:

| GitHub secret | Purpose |
| --- | --- |
| `YOUVERSION_APP_KEY` | YouVersion Platform app key |
| `YOUVERSION_OFFLINE_VERSION_IDS_JSON` | Licensed offline version IDs, e.g. `["1260"]` |
| `YOUVERSION_BULK_DOWNLOAD_LICENSED` | `true` only with explicit rights-holder approval |

Obtain an app key at [platform.youversion.com](https://platform.youversion.com). The release workflow runs without YouVersion secrets; builds publish successfully with an empty configuration.

### Android release signing (optional)

For Play Store or production-signed APKs:

```text
BIBLEPULSE_ANDROID_KEYSTORE
BIBLEPULSE_ANDROID_STORE_PASSWORD
BIBLEPULSE_ANDROID_KEY_ALIAS
BIBLEPULSE_ANDROID_KEY_PASSWORD
```

Without these variables, release builds use the debug keystore so CI and sideload APKs install on devices. Debug-signed artifacts are not suitable for Play Store submission.

### Local secrets file

Create a `.env` file in the project root for local development (already listed in `.gitignore`):

```text
YVP_KEY=your_youversion_or_bible_brain_key
```

Never commit `.env`, keystore files (`.jks`), or API keys into source control.

---

## Verification

Run the full local verification suite (matches CI verify job):

```bash
bash tools/ci/verify.sh
```

On Windows PowerShell:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test --no-fatal-infos
flutter test --exclude-tags golden
python tools/content/validate_manifest.py
flutter build web --release
```

Read the current app version from `pubspec.yaml`:

```bash
bash tools/ci/read_version.sh
```

---

## CI/CD

### Continuous integration

Workflow: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

Triggered on every push and pull request to `main`.

| Job | What it does |
| --- | --- |
| **verify** | Format, analyze, test, content manifest validation |
| **web** | `flutter build web --release` |
| **android** | Split APKs + App Bundle |
| **firebase-rules** | Firestore security rules tests |

### Release publishing

Workflow: [`.github/workflows/release.yml`](.github/workflows/release.yml)

Triggered by pushing a version tag (`v*`) or manual `workflow_dispatch`.

**Steps to publish:**

1. Bump version in `pubspec.yaml`:

   ```yaml
   version: 1.1.1+6
   ```

   Format: `MAJOR.MINOR.PATCH+BUILD`. The Git tag must match the name before `+` (e.g. tag `v1.1.1` for version `1.1.1+6`).

2. Commit and push to `main`. Confirm CI passes.

3. Create and push the matching tag:

   ```bash
   git tag v1.1.1
   git push origin v1.1.1
   ```

4. The release workflow verifies the project, builds artifacts, and publishes a GitHub Release named **Bible Plus v{version}**.

**Release assets:**

| File | Description |
| --- | --- |
| `bible-plus-{version}-arm64-v8a.apk` | Recommended for modern phones |
| `bible-plus-{version}-armeabi-v7a.apk` | Older 32-bit ARM devices |
| `bible-plus-{version}-x86_64.apk` | Emulators / x86 devices |
| `bible-plus-{version}.aab` | Google Play bundle |
| `bible-plus-{version}-web.zip` | Hosted web build |
| `biblepulse-arm64-v8a.apk` | Legacy alias used by the website |

---

## Website deployment

The public landing page lives in [`website/`](website/) and is deployed to Vercel at [bibleplus-7.vercel.app](https://bibleplus-7.vercel.app/).

| Setting | Value |
| --- | --- |
| Root directory | `website` |
| Download links | Point to GitHub Releases (`/releases/latest/download/...`) |

After recreating the GitHub repository, reconnect the Vercel project to `abel2800/Bible-Plus` under **Settings → Git**. The Vercel URL stays the same; only the Git connection needs to be refreshed.

---

## Version history

### v1.1.1

- Fix Android startup on devices whose system SQLite lacks the FTS5 module
- Bundle SQLite on Android with graceful search fallback
- Website and release metadata updated to v1.1.1

### v1.1.0

- Unified gold reading UI (catalog, settings, notes, audio sheet)
- Single audio entry point from Home, Read, and deep links
- Reader preferences: verse numbers, red-letter, focus-on-open, parallel reading
- Daily reading goal and dashboard engagement tracking
- Bible Plus branding and launcher icons
- Web platform in CI and release artifacts
- Full CI verification: format, analyze, tests, manifest, Android, and web builds

---

## Scripts and tooling

Helper scripts for content management live in [`scripts/`](scripts/README.md):

- `fetch_youversion_bible.js` — fetch Bible text from YouVersion/Bible Brain APIs
- `add_local_bible_asset.js` — add a local JSON Bible to assets and catalog
- `prepare_offline_bibles.js` — minify and split Bibles for hosting
- `generate_youversion_catalog.js` — list available YouVersion Bibles by language

See [`scripts/README.md`](scripts/README.md) for usage. Keep API credentials outside the repository.

---

## Security notes

- Do not commit `.env`, keystore files, Firebase service accounts, or API keys
- GitHub Actions secrets are used for release-time YouVersion configuration only
- Installed APKs contain whatever was compiled at build time; rotating a secret requires a new release build
- Firestore rules are tested in CI when the `firebase-rules` job runs

---

## Author

**Abel Sirak** — [GitHub @abel2800](https://github.com/abel2800)

---

## Acknowledgments

- [World English Bible](https://ebible.org/) — default Scripture and audio source
- [YouVersion Platform](https://developers.youversion.com/) — optional Bible catalog and downloads
- [Bible Brain / Faith Comes By Hearing](https://4.dbt.io/) — optional text and audio integration
