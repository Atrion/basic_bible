import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

const bool usesFileBackedStorage = true;
const bool supportsDirectFileImport = true;

Future<bool> pathExists(String path) => File(path).exists();

Future<void> deleteFileIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<String> readTextFile(String path) => File(path).readAsString();

Future<List<int>> readBinaryFile(String path) => File(path).readAsBytes();

Future<void> copyFile(String sourcePath, String destinationPath) async {
  final sourceFile = File(sourcePath);
  if (!await sourceFile.exists()) {
    throw Exception('Selected Bible file does not exist.');
  }

  final destinationFile = File(destinationPath);
  if (await destinationFile.exists()) {
    await destinationFile.delete();
  }
  await sourceFile.copy(destinationPath);
}

Future<void> writeBinaryFile(String destinationPath, List<int> bytes) async {
  final destinationFile = File(destinationPath);
  await destinationFile.writeAsBytes(bytes, flush: true);
}

/// Decompresses [compressed] (gzip) and writes the result to
/// [destinationPath] on a background isolate using the platform's native zlib.
/// The 50 MB bundled KJV database would otherwise block the UI thread (and use
/// a lot of memory) for a long time on a phone.
Future<void> writeGunzippedFile(
  String destinationPath,
  Uint8List compressed,
) {
  return Isolate.run(() {
    final bytes = gzip.decode(compressed);
    File(destinationPath).writeAsBytesSync(bytes, flush: true);
  });
}

Future<void> clearDirectoryFiles(
  String directoryPath, {
  String? extension,
}) async {
  final dir = Directory(directoryPath);
  if (!await dir.exists()) return;

  final files = await dir
      .list()
      .where(
        (e) =>
            e is File &&
            (extension == null || e.path.endsWith(extension)),
      )
      .cast<File>()
      .toList();

  await Future.wait(files.map((f) => f.delete()));
}
