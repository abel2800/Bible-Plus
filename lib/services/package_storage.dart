abstract class PackageStorage {
  Future<Uri?> resolveBiblePackageUrl(String packageId, String relativePath);
  Future<Uri?> resolveAudioPackageUrl(String packageId, String relativePath);
}

class CatalogUrlPackageStorage implements PackageStorage {
  const CatalogUrlPackageStorage();

  @override
  Future<Uri?> resolveBiblePackageUrl(
      String packageId, String relativePath) async {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return Uri.parse(relativePath);
    }
    return null;
  }

  @override
  Future<Uri?> resolveAudioPackageUrl(
      String packageId, String relativePath) async {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return Uri.parse(relativePath);
    }
    return null;
  }
}
