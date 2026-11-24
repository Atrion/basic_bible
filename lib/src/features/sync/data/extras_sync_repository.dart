import 'package:basic_bible/src/features/sync/data/extras_merge.dart';
import 'package:basic_bible/src/features/sync/data/drive_extras_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a sync pass changed on this device, so the app can refresh itself.
class ExtrasSyncSummary {
  const ExtrasSyncSummary({
    this.settingsChanged = false,
    this.prayerChanged = false,
    this.offeredPosition,
  });

  static const none = ExtrasSyncSummary();

  /// Settings were updated from another device (providers must reload).
  final bool settingsChanged;

  /// The prayer list was updated from another device.
  final bool prayerChanged;

  /// A newer reading position from another device, offered to the reader
  /// ("Continue reading..."). Never applied automatically.
  final PositionSnapshot? offeredPosition;
}

/// Syncs the app's settings, the reading position and the prayer list through
/// the same hidden Drive folder as the notes, in `.sync` files (see
/// [kExtraFileSuffix]).
class ExtrasSyncRepository {
  ExtrasSyncRepository({
    required SharedPreferences prefs,
    required Future<String> Function() accessToken,
    required DriveExtrasApi api,
    int Function()? clock,
  }) : _prefs = prefs,
       _accessToken = accessToken,
       _api = api,
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SharedPreferences _prefs;
  final Future<String> Function() _accessToken;
  final DriveExtrasApi _api;
  final int Function() _clock;

  // Preference keys owned by the sync (not themselves synced).
  static const settingsStateKey = 'extras_settings_state';
  static const positionOfferedKey = 'extras_position_offered';
  static const positionStampKey = 'bible_position_updated_at';
  static const prayerListKey = 'prayer_list';

  static const _settingsFile = 'settings$kExtraFileSuffix';
  static const _positionFile = 'position$kExtraFileSuffix';
  static const _prayerPrefix = 'prayer-';

  Future<ExtrasSyncSummary> syncOnce() async {
    final token = await _accessToken();
    final files = await _api.listExtraFiles(token);
    final byName = <String, DriveExtraFile>{};
    for (final file in files) {
      byName.putIfAbsent(file.name, () => file);
    }

    final settingsChanged = await _syncSettings(token, byName[_settingsFile]);
    final offered = await _syncPosition(token, byName[_positionFile]);
    final prayerChanged = await _syncPrayer(token, byName);

    return ExtrasSyncSummary(
      settingsChanged: settingsChanged,
      prayerChanged: prayerChanged,
      offeredPosition: offered,
    );
  }

  // --------------------------------------------------------------------------
  // Settings
  // --------------------------------------------------------------------------

  Future<bool> _syncSettings(String token, DriveExtraFile? file) async {
    Map<String, SettingEntry> remote = {};
    if (file != null) {
      final parsed = parseSettingsDoc(await _api.downloadExtra(token, file.fileId));
      if (parsed == null) return false; // unusable file: never overwrite it
      remote = parsed;
    }

    final local = <String, Object>{};
    for (final key in kSyncedSettingKeys) {
      final value = _prefs.get(key);
      if (value != null) local[key] = value;
    }

    final state = parseSettingsDoc(_prefs.getString(settingsStateKey) ?? '');
    final result = mergeSettings(
      local: local,
      localStamps: {
        if (state != null)
          for (final e in state.entries) e.key: e.value.stamp,
      },
      base: state == null
          ? null
          : {for (final e in state.entries) e.key: e.value.value},
      remote: remote,
      now: _clock(),
    );

    for (final change in result.changesForLocal.entries) {
      await _writePref(change.key, change.value);
    }
    await _prefs.setString(settingsStateKey, encodeSettingsDoc(result.merged));

    if (result.needsUpload) {
      await _api.uploadExtra(
        accessToken: token,
        fileName: _settingsFile,
        content: encodeSettingsDoc(result.merged),
        updatedAtMillis: _clock(),
        existingFileId: file?.fileId,
      );
    }
    return result.changesForLocal.isNotEmpty;
  }

  Future<void> _writePref(String key, Object value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    }
  }

  // --------------------------------------------------------------------------
  // Reading position
  // --------------------------------------------------------------------------

  PositionSnapshot? _localPosition() {
    final book = _prefs.getString('bible_book');
    final chapter = _prefs.getInt('bible_chapter');
    if (book == null || chapter == null) return null;
    return PositionSnapshot(
      translationId: _prefs.getString('bible_translation') ?? 'kjv',
      bookId: book,
      chapter: chapter,
      verse: _prefs.getInt('bible_verse'),
      updatedAt: _prefs.getInt(positionStampKey) ?? 0,
    );
  }

  Future<PositionSnapshot?> _syncPosition(
    String token,
    DriveExtraFile? file,
  ) async {
    PositionSnapshot? remote;
    if (file != null) {
      remote = PositionSnapshot.tryParse(
        await _api.downloadExtra(token, file.fileId),
      );
    }
    final local = _localPosition();
    final action = decidePosition(
      local: local,
      remote: remote,
      lastOfferedStamp: _prefs.getInt(positionOfferedKey),
    );

    switch (action) {
      case PositionAction.none:
        return null;
      case PositionAction.push:
        await _api.uploadExtra(
          accessToken: token,
          fileName: _positionFile,
          content: local!.toJsonString(),
          updatedAtMillis: local.updatedAt,
          existingFileId: file?.fileId,
        );
        return null;
      case PositionAction.offerRemote:
        // Remember it was offered so it is shown once, not on every sync.
        await _prefs.setInt(positionOfferedKey, remote!.updatedAt);
        return remote;
    }
  }

  // --------------------------------------------------------------------------
  // Prayer list
  // --------------------------------------------------------------------------

  static String prayerFileName(String id) => '$_prayerPrefix$id$kExtraFileSuffix';

  static String? _prayerIdOf(String fileName) {
    if (!fileName.startsWith(_prayerPrefix) ||
        !fileName.endsWith(kExtraFileSuffix)) {
      return null;
    }
    final id = fileName.substring(
      _prayerPrefix.length,
      fileName.length - kExtraFileSuffix.length,
    );
    return id.isEmpty ? null : id;
  }

  List<PrayerRecord> _localPrayer() {
    final records = <PrayerRecord>[];
    for (final raw in _prefs.getStringList(prayerListKey) ?? const <String>[]) {
      final record = PrayerRecord.tryParse(raw);
      if (record != null) records.add(record);
    }
    return records;
  }

  Future<bool> _syncPrayer(
    String token,
    Map<String, DriveExtraFile> filesByName,
  ) async {
    final local = _localPrayer();
    final localById = {for (final r in local) r.id: r};

    final remoteFiles = <String, DriveExtraFile>{};
    for (final entry in filesByName.entries) {
      final id = _prayerIdOf(entry.key);
      if (id != null) remoteFiles[id] = entry.value;
    }

    // Only download entries that are new or newer in the cloud; entries with
    // the same change time on both sides need no work at all.
    final downloaded = <PrayerRecord>[];
    final skipIds = <String>{};
    for (final entry in remoteFiles.entries) {
      final localRecord = localById[entry.key];
      final remoteStamp = entry.value.updatedAtMillis;
      if (localRecord != null && remoteStamp != null) {
        if (localRecord.updatedAt == remoteStamp) {
          skipIds.add(entry.key);
          continue;
        }
        if (localRecord.updatedAt > remoteStamp) continue; // we upload ours
      }
      final record = PrayerRecord.tryParse(
        await _api.downloadExtra(token, entry.value.fileId),
      );
      if (record != null && record.id == entry.key) downloaded.add(record);
    }

    final result = mergePrayer(
      local: [for (final r in local) if (!skipIds.contains(r.id)) r],
      remote: downloaded,
    );

    for (final record in result.toUpload) {
      await _api.uploadExtra(
        accessToken: token,
        fileName: prayerFileName(record.id),
        content: record.toJsonString(),
        updatedAtMillis: record.updatedAt,
        isDeleted: record.deleted,
        existingFileId: remoteFiles[record.id]?.fileId,
      );
    }

    final byId = {for (final r in local) r.id: r};
    for (final record in result.toApplyLocally) {
      byId[record.id] = record;
    }
    final all = purgeOldTombstones(byId.values.toList(), now: _clock())
      ..sort(comparePrayerRecords);
    await _prefs.setStringList(prayerListKey, [
      for (final r in all) r.toJsonString(),
    ]);
    return result.toApplyLocally.isNotEmpty;
  }
}
