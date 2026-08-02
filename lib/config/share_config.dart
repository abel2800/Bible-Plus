/// Store and web URLs used when sharing Scripture / audio.
///
/// Override at build time after you publish, e.g.:
/// ```
/// flutter build apk \
///   --dart-define=SHARE_BASE_URL=https://biblepulse.app \
///   --dart-define=PLAY_STORE_URL=https://play.google.com/store/apps/details?id=app.biblepulse.reader \
///   --dart-define=APP_STORE_URL=https://apps.apple.com/app/idYOUR_ID
/// ```
abstract final class ShareConfig {
  /// Public web (or App Link) origin without a trailing slash.
  static const webBaseUrl = String.fromEnvironment(
    'SHARE_BASE_URL',
    defaultValue: 'https://biblepulse.app',
  );

  static const playStoreUrl = String.fromEnvironment(
    'PLAY_STORE_URL',
    defaultValue:
        'https://play.google.com/store/apps/details?id=app.biblepulse.reader',
  );

  static const appStoreUrl = String.fromEnvironment(
    'APP_STORE_URL',
    defaultValue: 'https://apps.apple.com/app/biblepulse/id0000000000',
  );

  /// Custom scheme handled by the native app (`biblepulse://listen?...`).
  static const appScheme = 'biblepulse';

  static const listenPath = '/listen';
}
