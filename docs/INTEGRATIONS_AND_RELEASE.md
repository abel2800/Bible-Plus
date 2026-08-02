# Integrations and release

BiblePulse is offline-first. Cloud, community, remote audio, licensed catalogs,
and notifications fail closed when their required configuration or platform
support is unavailable.

## Firebase

Supply Firebase values with `--dart-define`; never commit credentials:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
FIREBASE_AUTH_DOMAIN (optional)
FIREBASE_STORAGE_BUCKET (optional)
```

For local emulators:

```text
FIREBASE_USE_EMULATORS=true
FIREBASE_EMULATOR_HOST=localhost
```

Android emulators normally use `10.0.2.2`. Community additionally requires
`BIBLEPULSE_ENABLE_COMMUNITY=true`.

Study records are owner-scoped and synchronize with UTC last-write-wins
semantics and deletion tombstones. Guest data remains local. Production cloud
activation also requires a published privacy/retention policy, account export
and deletion UI, moderator staffing, escalation procedures, and abuse
monitoring.

Run Firestore authorization tests:

```powershell
npm ci --prefix firebase-tests
npx firebase-tools@latest emulators:exec --only firestore "npm --prefix firebase-tests test"
```

## Audio Bible

**Default:** public-domain WEB narration (Winfred W. Henson via eBible.org) is
enabled without build-time credentials. See `docs/CONTENT_SOURCES.md`.

**Optional Bible Brain (text + audio, multi-language):**

1. Request a key: <https://4.dbt.io/api_key/request>
2. OpenAPI: <https://4.dbt.io/open-api-4.json>
3. Build defines:

```text
BIBLE_BRAIN_API_KEY=your-key
BIBLE_BRAIN_BIBLE_IDS_JSON={"WEB":"approved-bible-id","AMH":"AMHABC"}
BIBLE_BRAIN_MEDIA_HOSTS=approved.cdn.example,other.approved.host
```

- `BIBLE_BRAIN_API_KEY` alone unlocks Bible Store discovery for languages your
  key can access (Amharic, Oromo, Tigrinya, Somali, English, …) and online
  chapter text after **Enable online**.
- Full audio streaming also needs `BIBLE_BRAIN_BIBLE_IDS_JSON` (or runtime
  enable from the Store) plus an HTTPS media-host allowlist in
  `BIBLE_BRAIN_MEDIA_HOSTS`.

When audio defines are set, Bible Brain replaces the default WEB audio
resolver. The app discovers audio filesets, caches catalog responses for 24
hours, and checks the credential-scoped `/download/list`. Only
download-permitted filesets may be stored. Streaming-only filesets are never
cached. Media must use HTTPS and an allowlisted host.

Supported cache behavior includes resumable range downloads, per-chapter,
per-book and whole-Bible queues, Wi-Fi-only policy, quota eviction, cache-size
display, and clearing. Verse synchronization activates only when timing data is
available.

Before production activation of Bible Brain, record API approval, attribution,
rate limits, language coverage, caching terms, and real-device interruption/
offline tests.

## Notifications

Notification initialization does not request permission. On supported mobile
platforms, choosing a theme in Settings explicitly requests permission and
schedules a verified bundled WEB verse. Scheduling uses stable ID `1001`,
timezone-aware recurrence, and Android inexact-while-idle mode without exact
alarm permission. Notification taps currently open the app without deep links.

## Build verification

CI runs formatting, strict analysis, content-manifest validation, Flutter tests,
web release compilation, Firestore emulator tests, browser integration, and
verification builds for Android, iOS, macOS, Linux, and Windows.

CI Android artifacts are **debug-signed** when release keystore secrets are
absent, so you can sideload `app-release.apk` onto a phone for testing. They
are **not** Play Store–ready. Download the Actions artifact zip, unzip it, and
install **`app-release.apk` only** — an `.aab` cannot be installed directly.

## Signing

Android release (Play Store) signing is enabled only when all variables are present:

```text
BIBLEPULSE_ANDROID_KEYSTORE
BIBLEPULSE_ANDROID_STORE_PASSWORD
BIBLEPULSE_ANDROID_KEY_ALIAS
BIBLEPULSE_ANDROID_KEY_PASSWORD
```

Verify the variables before a publishable build:

```powershell
cd android
./gradlew verifyReleaseSigning
```

Windows binaries can be signed after a release build with:

```text
BIBLEPULSE_WINDOWS_CERTIFICATE
BIBLEPULSE_WINDOWS_CERTIFICATE_PASSWORD
BIBLEPULSE_WINDOWS_TIMESTAMP_URL (optional)
```

```powershell
powershell -ExecutionPolicy Bypass -File tools/release/sign_windows.ps1
```

Apple signing remains an Xcode/certificate/provisioning-profile responsibility.
Never commit certificates, passwords, provisioning profiles, or store keys.
