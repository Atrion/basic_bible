/// Merge rules for the "extras" that sync alongside notes: app settings, the
/// reading position and the prayer list.
///
/// This file is plain Dart (no Flutter) so the rules can be tested in
/// isolation. Notes have their own merge in notes_sync_repository.dart.
library;

import 'dart:convert';

// ============================================================================
// Settings
// ============================================================================

/// Preference keys that follow the user from device to device. Anything not
/// listed here stays on the device: the sync mode, split-view state, history,
/// caches and the developer catalog URL.
const Set<String> kSyncedSettingKeys = {
  'themeMode',
  'languageCode',
  'reader_font_size',
  'reader_continuous_scrolling',
  'reader_layout_mode',
  'reader_show_book_introductions',
  'reader_show_chapter_headers',
  'reader_show_verse_selector',
  'reader_bold_divine_name',
  'reader_underline_proper_names',
  'reader_underline_word_metadata',
  'reader_bracket_translator_additions',
  'reader_use_source_bold_styling',
  'reader_show_source_details',
  'notes_confirm_remove_linked_verse',
  'notes_show_across_translations',
};

/// One setting: its value (bool, int, double, String or List&lt;String&gt;) and
/// the time (ms since epoch) it was last changed.
typedef SettingEntry = ({Object value, int stamp});

bool settingValuesEqual(Object a, Object b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  return a.runtimeType == b.runtimeType && a == b;
}

Map<String, Object?> _encodeEntry(SettingEntry entry) {
  final v = entry.value;
  final String type;
  if (v is bool) {
    type = 'b';
  } else if (v is int) {
    type = 'i';
  } else if (v is double) {
    type = 'd';
  } else if (v is String) {
    type = 's';
  } else if (v is List<String>) {
    type = 'l';
  } else {
    throw ArgumentError('Unsupported setting type: ${v.runtimeType}');
  }
  return {'t': type, 'v': v, 'at': entry.stamp};
}

Object? _decodeValue(Object? type, Object? value) {
  switch (type) {
    case 'b':
      return value is bool ? value : null;
    case 'i':
      return value is int ? value : null;
    case 'd':
      return value is num ? value.toDouble() : null;
    case 's':
      return value is String ? value : null;
    case 'l':
      return value is List && value.every((e) => e is String)
          ? List<String>.from(value)
          : null;
  }
  return null;
}

String encodeSettingsDoc(Map<String, SettingEntry> entries) => jsonEncode({
  'version': 1,
  'settings': {
    for (final e in entries.entries) e.key: _encodeEntry(e.value),
  },
});

/// Parses a settings document. Returns null when the whole document is not
/// usable (so a bad file is never "merged" and then overwritten); individual
/// bad or unknown entries are skipped.
Map<String, SettingEntry>? parseSettingsDoc(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['settings'] is! Map) return null;
    final result = <String, SettingEntry>{};
    (decoded['settings'] as Map).forEach((key, entry) {
      if (key is! String || !kSyncedSettingKeys.contains(key)) return;
      if (entry is! Map) return;
      final value = _decodeValue(entry['t'], entry['v']);
      final stamp = entry['at'];
      if (value == null || stamp is! int) return;
      result[key] = (value: value, stamp: stamp);
    });
    return result;
  } catch (_) {
    return null;
  }
}

class SettingsMergeResult {
  const SettingsMergeResult({
    required this.merged,
    required this.changesForLocal,
    required this.needsUpload,
  });

  /// The agreed value and change time for every setting.
  final Map<String, SettingEntry> merged;

  /// Settings whose merged value differs from this device (write to prefs).
  final Map<String, Object> changesForLocal;

  /// Whether the merged result differs from what is in the cloud.
  final bool needsUpload;
}

/// Three-way merge of settings, per setting, newest change wins.
///
/// [local] holds the values set on this device. [base] is what was agreed at
/// the last successful sync (null if never). A setting that differs from
/// [base] was changed on this device since then and is stamped [now]. On the
/// very first sync nothing is stamped, so settings already in the cloud win
/// over a new device's defaults while a device with settings the cloud lacks
/// uploads them.
SettingsMergeResult mergeSettings({
  required Map<String, Object> local,
  required Map<String, int> localStamps,
  required Map<String, Object>? base,
  required Map<String, SettingEntry> remote,
  required int now,
}) {
  final merged = <String, SettingEntry>{};
  final changesForLocal = <String, Object>{};
  var needsUpload = false;

  final keys = {...local.keys, ...remote.keys};
  for (final key in keys) {
    final localValue = local[key];
    final remoteEntry = remote[key];

    int? localStamp;
    if (localValue != null) {
      final baseValue = base?[key];
      if (base != null && (baseValue == null || !settingValuesEqual(baseValue, localValue))) {
        localStamp = now; // changed on this device since the last sync
      } else {
        localStamp = localStamps[key] ?? 0;
      }
    }

    if (localValue == null && remoteEntry != null) {
      merged[key] = remoteEntry;
      changesForLocal[key] = remoteEntry.value;
    } else if (remoteEntry == null && localValue != null) {
      // Not in the cloud yet. A value with no known change time (a first
      // upload) is stamped now, so it is newer than any device that has only
      // defaults and wins when another device syncs for the first time.
      merged[key] = (value: localValue, stamp: localStamp! > 0 ? localStamp : now);
      needsUpload = true;
    } else if (localValue != null && remoteEntry != null) {
      if (settingValuesEqual(localValue, remoteEntry.value)) {
        final stamp = localStamp! > remoteEntry.stamp ? localStamp : remoteEntry.stamp;
        merged[key] = (value: localValue, stamp: stamp);
        if (stamp != remoteEntry.stamp) needsUpload = true;
      } else if (remoteEntry.stamp > localStamp!) {
        merged[key] = remoteEntry;
        changesForLocal[key] = remoteEntry.value;
      } else {
        merged[key] = (value: localValue, stamp: localStamp);
        needsUpload = true;
      }
    }
  }
  return SettingsMergeResult(
    merged: merged,
    changesForLocal: changesForLocal,
    needsUpload: needsUpload,
  );
}

// ============================================================================
// Reading position
// ============================================================================

class PositionSnapshot {
  const PositionSnapshot({
    required this.translationId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.updatedAt,
  });

  final String translationId;
  final String bookId;
  final int chapter;
  final int? verse;

  /// When the position was last changed (ms since epoch).
  final int updatedAt;

  bool samePlaceAs(PositionSnapshot other) =>
      translationId == other.translationId &&
      bookId == other.bookId &&
      chapter == other.chapter &&
      verse == other.verse;

  String toJsonString() => jsonEncode({
    'version': 1,
    'translation': translationId,
    'book': bookId,
    'chapter': chapter,
    'verse': verse,
    'at': updatedAt,
  });

  static PositionSnapshot? tryParse(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final translation = m['translation'];
      final book = m['book'];
      final chapter = m['chapter'];
      final verse = m['verse'];
      final at = m['at'];
      if (translation is! String ||
          book is! String ||
          chapter is! int ||
          at is! int ||
          (verse != null && verse is! int)) {
        return null;
      }
      return PositionSnapshot(
        translationId: translation,
        bookId: book,
        chapter: chapter,
        verse: verse as int?,
        updatedAt: at,
      );
    } catch (_) {
      return null;
    }
  }
}

enum PositionAction { none, push, offerRemote }

/// What to do about the reading position.
///
/// The position is never changed behind the reader's back: a newer position
/// from another device is only *offered* ("Continue reading..."), once per
/// distinct remote change ([lastOfferedStamp]).
PositionAction decidePosition({
  required PositionSnapshot? local,
  required PositionSnapshot? remote,
  required int? lastOfferedStamp,
}) {
  if (remote == null) {
    return local != null && local.updatedAt > 0
        ? PositionAction.push
        : PositionAction.none;
  }
  if (local == null || local.updatedAt <= 0) {
    return lastOfferedStamp == remote.updatedAt
        ? PositionAction.none
        : PositionAction.offerRemote;
  }
  if (local.samePlaceAs(remote)) return PositionAction.none;
  if (remote.updatedAt > local.updatedAt) {
    return lastOfferedStamp == remote.updatedAt
        ? PositionAction.none
        : PositionAction.offerRemote;
  }
  if (remote.updatedAt < local.updatedAt) return PositionAction.push;
  return PositionAction.none;
}

// ============================================================================
// Prayer list
// ============================================================================

/// A prayer list entry, including removed ones ("tombstones") so a removal
/// reaches the other devices.
class PrayerRecord {
  const PrayerRecord({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
  });

  final String id;
  final String text;
  final int createdAt;
  final int updatedAt;
  final bool deleted;

  PrayerRecord copyWith({String? text, int? updatedAt, bool? deleted}) =>
      PrayerRecord(
        id: id,
        text: text ?? this.text,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  bool sameContentAs(PrayerRecord o) =>
      id == o.id &&
      text == o.text &&
      createdAt == o.createdAt &&
      updatedAt == o.updatedAt &&
      deleted == o.deleted;

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'deleted': deleted,
  };

  /// Reads an entry written by this version or by the first version of the
  /// prayer list (which had only id, text and an ISO createdAt).
  static PrayerRecord? tryFromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final id = decoded['id'];
    final text = decoded['text'];
    if (id is! String || id.isEmpty || text is! String) return null;
    final createdRaw = decoded['createdAt'];
    final created = createdRaw is int
        ? createdRaw
        : (createdRaw is String
              ? DateTime.tryParse(createdRaw)?.millisecondsSinceEpoch
              : null);
    final createdAt = created ?? 0;
    final updatedRaw = decoded['updatedAt'];
    final deleted = decoded['deleted'] == true;
    if (!deleted && text.trim().isEmpty) return null;
    return PrayerRecord(
      id: id,
      text: text,
      createdAt: createdAt,
      updatedAt: updatedRaw is int ? updatedRaw : createdAt,
      deleted: deleted,
    );
  }

  static PrayerRecord? tryParse(String raw) {
    try {
      return tryFromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  String toJsonString() => jsonEncode(toJson());
}

class PrayerMergeResult {
  const PrayerMergeResult({
    required this.merged,
    required this.toApplyLocally,
    required this.toUpload,
  });

  final List<PrayerRecord> merged;

  /// Records that are new or changed compared with this device.
  final List<PrayerRecord> toApplyLocally;

  /// Records that are new or changed compared with the cloud.
  final List<PrayerRecord> toUpload;
}

/// Per entry, the most recent change wins; a removal beats an edit made at
/// the same instant.
PrayerMergeResult mergePrayer({
  required List<PrayerRecord> local,
  required List<PrayerRecord> remote,
}) {
  final localById = {for (final r in local) r.id: r};
  final remoteById = {for (final r in remote) r.id: r};
  final merged = <PrayerRecord>[];
  final toApply = <PrayerRecord>[];
  final toUpload = <PrayerRecord>[];

  for (final id in {...localById.keys, ...remoteById.keys}) {
    final l = localById[id];
    final r = remoteById[id];
    if (l == null) {
      merged.add(r!);
      toApply.add(r);
    } else if (r == null) {
      merged.add(l);
      toUpload.add(l);
    } else {
      final PrayerRecord winner;
      if (l.updatedAt != r.updatedAt) {
        winner = l.updatedAt > r.updatedAt ? l : r;
      } else if (l.deleted != r.deleted) {
        winner = l.deleted ? l : r;
      } else {
        winner = l;
      }
      merged.add(winner);
      if (!winner.sameContentAs(l)) toApply.add(winner);
      if (!winner.sameContentAs(r)) toUpload.add(winner);
    }
  }
  merged.sort(comparePrayerRecords);
  return PrayerMergeResult(
    merged: merged,
    toApplyLocally: toApply,
    toUpload: toUpload,
  );
}

/// Oldest first; the id breaks ties so every device shows the same order.
int comparePrayerRecords(PrayerRecord a, PrayerRecord b) {
  final byTime = a.createdAt.compareTo(b.createdAt);
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

/// Drops removal markers older than [keepFor] (every device has had time to
/// see them by then).
List<PrayerRecord> purgeOldTombstones(
  List<PrayerRecord> records, {
  required int now,
  Duration keepFor = const Duration(days: 60),
}) {
  final cutoff = now - keepFor.inMilliseconds;
  return [
    for (final r in records)
      if (!(r.deleted && r.updatedAt < cutoff)) r,
  ];
}
