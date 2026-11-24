/// Drive file model and interface for the sync extras (no HTTP here, so the
/// sync logic can be tested without network packages).
library;

/// File extension for the extras (settings, reading position, prayer list).
///
/// It is deliberately not `.json`: the note sync treats every `.json` file in
/// the app-data folder as a note, so older installs of the app must never see
/// these files.
const String kExtraFileSuffix = '.sync';

/// One extras file as seen in a Drive listing.
class DriveExtraFile {
  const DriveExtraFile({
    required this.fileId,
    required this.name,
    this.updatedAtMillis,
    this.isDeleted,
  });

  final String fileId;

  /// The file name, e.g. `settings.sync` or `prayer-123-0.sync`.
  final String name;

  /// The change time stamped into the file's appProperties at upload time, so
  /// an unchanged file never has to be downloaded to find out.
  final int? updatedAtMillis;
  final bool? isDeleted;
}

/// Interface so the extras sync can be unit-tested against a fake Drive.
abstract class DriveExtrasApi {
  Future<List<DriveExtraFile>> listExtraFiles(String accessToken);
  Future<String> downloadExtra(String accessToken, String fileId);
  Future<void> uploadExtra({
    required String accessToken,
    required String fileName,
    required String content,
    int? updatedAtMillis,
    bool isDeleted = false,
    String? existingFileId,
  });
}
