import 'dart:convert';

abstract final class YouVersionConfig {
  static const String appKey = String.fromEnvironment('YOUVERSION_APP_KEY');
  static const String baseUrl = 'https://api.youversion.com/v1';

  static const String offlineVersionIdsJson = String.fromEnvironment(
    'YOUVERSION_OFFLINE_VERSION_IDS_JSON',
    defaultValue: '[]',
  );

  static const int amharicNasvVersionId = int.fromEnvironment(
    'YOUVERSION_AMH_NASV_ID',
    defaultValue: 1260,
  );

  static const int oromoVersionId = int.fromEnvironment(
    'YOUVERSION_ORM_ID',
    defaultValue: 0,
  );

  static const bool licenseConfirmedForBulkDownload = bool.fromEnvironment(
    'YOUVERSION_BULK_DOWNLOAD_LICENSED',
    defaultValue: true,
  );

  static bool get isConfigured => appKey.isNotEmpty;
  static bool get canBulkDownload =>
      isConfigured &&
      licenseConfirmedForBulkDownload &&
      offlineVersionIds.isNotEmpty;

  static Set<String> get offlineVersionIds {
    try {
      final decoded = jsonDecode(offlineVersionIdsJson);
      if (decoded is List) {
        return decoded.map((id) => id.toString()).toSet();
      }
    } catch (_) {
      // Invalid build configuration means no offline versions are allowed.
    }
    return const <String>{};
  }

  static bool isOfflineVersionLicensed(String versionId) =>
      licenseConfirmedForBulkDownload || offlineVersionIds.contains(versionId);

  static int? versionIdFor(String code) {
    final normalized = code.trim().toUpperCase();
    switch (normalized) {
      case 'AMH':
        return amharicNasvVersionId;
      case 'ORM':
        return oromoVersionId;
      default:
        return null;
    }
  }
}
