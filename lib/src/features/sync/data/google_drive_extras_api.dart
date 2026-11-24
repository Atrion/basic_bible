import 'dart:convert';

import 'package:basic_bible/src/features/sync/data/drive_extras_api.dart';
import 'package:http/http.dart' as http;

/// Drive v3 REST calls against the hidden appDataFolder, same approach as
/// [GoogleDriveNotesApi].
class GoogleDriveExtrasApi implements DriveExtrasApi {
  GoogleDriveExtrasApi(this._client);

  final http.Client _client;

  static const _filesHost = 'www.googleapis.com';

  Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  Never _fail(http.Response response, String action) {
    throw Exception(
      'Google Drive $action failed '
      '(HTTP ${response.statusCode}): ${response.body}',
    );
  }

  @override
  Future<List<DriveExtraFile>> listExtraFiles(String accessToken) async {
    final files = <DriveExtraFile>[];
    String? pageToken;
    do {
      final response = await _client.get(
        Uri.https(_filesHost, '/drive/v3/files', {
          'spaces': 'appDataFolder',
          'fields': 'nextPageToken,files(id,name,appProperties)',
          'pageSize': '1000',
          if (pageToken != null) 'pageToken': pageToken,
        }),
        headers: _auth(accessToken),
      );
      if (response.statusCode != 200) _fail(response, 'listing');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      for (final raw in (json['files'] as List<dynamic>? ?? const [])) {
        final file = raw as Map<String, dynamic>;
        final name = file['name'] as String? ?? '';
        if (!name.endsWith(kExtraFileSuffix)) continue; // notes and others
        final props = file['appProperties'] as Map<String, dynamic>?;
        files.add(
          DriveExtraFile(
            fileId: file['id'] as String,
            name: name,
            updatedAtMillis: int.tryParse(props?['updatedAt'] as String? ?? ''),
            isDeleted: switch (props?['deleted']) {
              '1' => true,
              '0' => false,
              _ => null,
            },
          ),
        );
      }
      pageToken = json['nextPageToken'] as String?;
    } while (pageToken != null);
    return files;
  }

  @override
  Future<String> downloadExtra(String accessToken, String fileId) async {
    final response = await _client.get(
      Uri.https(_filesHost, '/drive/v3/files/$fileId', {'alt': 'media'}),
      headers: _auth(accessToken),
    );
    if (response.statusCode != 200) _fail(response, 'download');
    return utf8.decode(response.bodyBytes);
  }

  @override
  Future<void> uploadExtra({
    required String accessToken,
    required String fileName,
    required String content,
    int? updatedAtMillis,
    bool isDeleted = false,
    String? existingFileId,
  }) async {
    final isUpdate = existingFileId != null;
    final metadata = <String, dynamic>{
      if (!isUpdate) 'name': fileName,
      if (!isUpdate) 'parents': ['appDataFolder'],
      'appProperties': {
        if (updatedAtMillis != null) 'updatedAt': '$updatedAtMillis',
        'deleted': isDeleted ? '1' : '0',
      },
    };

    const boundary = 'basic_bible_extras_sync';
    final body = utf8.encode(
      '--$boundary\r\n'
      'Content-Type: application/json; charset=UTF-8\r\n\r\n'
      '${jsonEncode(metadata)}\r\n'
      '--$boundary\r\n'
      'Content-Type: application/json\r\n\r\n'
      '$content\r\n'
      '--$boundary--',
    );
    final uri = Uri.https(
      _filesHost,
      isUpdate
          ? '/upload/drive/v3/files/$existingFileId'
          : '/upload/drive/v3/files',
      {'uploadType': 'multipart'},
    );
    final request = http.Request(isUpdate ? 'PATCH' : 'POST', uri)
      ..headers.addAll({
        ..._auth(accessToken),
        'Content-Type': 'multipart/related; boundary=$boundary',
      })
      ..bodyBytes = body;

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    if (response.statusCode != 200) _fail(response, 'upload');
  }
}
