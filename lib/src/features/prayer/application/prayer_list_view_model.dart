import 'package:basic_bible/src/features/sync/application/auto_sync_scheduler.dart';
import 'package:basic_bible/src/features/sync/application/view_models/sync_view_models.dart'
    show noteChangeSyncTriggerProvider;
import 'package:basic_bible/src/features/sync/data/extras_merge.dart';
import 'package:basic_bible/src/services/shared_preferences_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One entry on the prayer list: a person, event or request to remember.
/// (The same class the Google Drive sync merges; see extras_merge.dart.)
typedef PrayerItem = PrayerRecord;

final prayerListProvider =
    StateNotifierProvider<PrayerListNotifier, List<PrayerItem>>((ref) {
      return PrayerListNotifier(
        ref.read(sharedPreferencesProvider),
        syncTrigger: ref.read(noteChangeSyncTriggerProvider),
      );
    });

/// The user's prayer list, kept on the device in SharedPreferences and synced
/// through Google Drive when signed in.
///
/// Removed names are kept as hidden "removal markers" for a while so the
/// removal reaches the user's other devices; [state] only holds visible names.
class PrayerListNotifier extends StateNotifier<List<PrayerItem>> {
  PrayerListNotifier(
    this._prefs, {
    NoteSyncTrigger? syncTrigger,
    int Function()? clock,
  }) : _syncTrigger = syncTrigger ?? const NoOpNoteSyncTrigger(),
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _all = _load(_prefs),
       super(_visible(_load(_prefs)));

  static const String prefsKey = 'prayer_list';

  final SharedPreferences _prefs;
  final NoteSyncTrigger _syncTrigger;
  final int Function() _clock;
  List<PrayerRecord> _all;
  int _counter = 0;

  static List<PrayerRecord> _load(SharedPreferences prefs) {
    final records = <PrayerRecord>[];
    for (final raw in prefs.getStringList(prefsKey) ?? const <String>[]) {
      final record = PrayerRecord.tryParse(raw);
      if (record != null) records.add(record);
    }
    records.sort(comparePrayerRecords);
    return records;
  }

  static List<PrayerRecord> _visible(List<PrayerRecord> all) => [
    for (final record in all)
      if (!record.deleted) record,
  ];

  /// Re-reads the list after a sync changed it from another device.
  void reload() {
    _all = _load(_prefs);
    state = _visible(_all);
  }

  /// Adds [text] to the end of the list. Returns false if it was blank.
  Future<bool> add(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final now = _clock();
    await _commit([
      ..._all,
      PrayerRecord(
        id: '${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
        text: trimmed,
        createdAt: now,
        updatedAt: now,
        deleted: false,
      ),
    ]);
    return true;
  }

  Future<void> remove(String id) async {
    final now = _clock();
    await _commit([
      for (final record in _all)
        record.id == id && !record.deleted
            ? record.copyWith(deleted: true, updatedAt: now)
            : record,
    ]);
  }

  /// Puts a removed [item] back in its old place (used by "Undo").
  Future<void> restore(PrayerItem item) async {
    final now = _clock();
    final exists = _all.any((record) => record.id == item.id);
    await _commit([
      for (final record in _all)
        record.id == item.id
            ? record.copyWith(deleted: false, updatedAt: now)
            : record,
      if (!exists) item.copyWith(deleted: false, updatedAt: now),
    ]);
  }

  Future<void> _commit(List<PrayerRecord> all) async {
    _all = purgeOldTombstones(all, now: _clock())..sort(comparePrayerRecords);
    state = _visible(_all);
    await _prefs.setStringList(prefsKey, [
      for (final record in _all) record.toJsonString(),
    ]);
    _syncTrigger.schedule();
  }
}
