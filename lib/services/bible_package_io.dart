import 'dart:io';

Future<void> ensureDir(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) await dir.create(recursive: true);
}

Future<void> writeString(String path, String contents) async {
  await File(path).writeAsString(contents);
}

Future<int> fileLength(String path) async => File(path).length();

Future<void> deleteIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<String?> readStringIfExists(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsString();
}
