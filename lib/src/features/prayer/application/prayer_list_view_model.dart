import 'dart:convert';

import 'package:basic_bible/src/services/shared_preferences_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One entry on the prayer list: a person, event or request to remember.
class PrayerItem {
  const PrayerItem({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Returns null for anything that is not a valid stored entry, so one bad
  /// value can never stop the whole list from loading.
  static PrayerItem? tryFromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final id = decoded['id'];
      final text = decoded['text'];
      if (id is! String || text is! String || text.trim().isEmpty) return null;
      return PrayerItem(
        id: id,
        text: text,
        createdAt:
            DateTime.tryParse('${decoded['createdAt']}') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

final prayerListProvider =
    StateNotifierProvider<PrayerListNotifier, List<PrayerItem>>((ref) {
      return PrayerListNotifier(ref.read(sharedPreferencesProvider));
    });

/// The user's prayer list, kept on the device in SharedPreferences.
class PrayerListNotifier extends StateNotifier<List<PrayerItem>> {
  PrayerListNotifier(this._prefs) : super(_load(_prefs));

  static const String prefsKey = 'prayer_list';

  final SharedPreferences _prefs;
  int _counter = 0;

  static List<PrayerItem> _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(prefsKey) ?? const <String>[];
    return raw.map(PrayerItem.tryFromJson).whereType<PrayerItem>().toList();
  }

  /// Adds [text] to the end of the list. Returns false if it was blank.
  Future<bool> add(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final item = PrayerItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    state = [...state, item];
    await _persist();
    return true;
  }

  Future<void> remove(String id) async {
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
    await _persist();
  }

  /// Puts [item] back at [index] (used by "Undo" after a removal).
  Future<void> insertAt(int index, PrayerItem item) async {
    if (state.any((existing) => existing.id == item.id)) return;
    final next = [...state];
    next.insert(index.clamp(0, next.length), item);
    state = next;
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs.setStringList(prefsKey, [
      for (final item in state) jsonEncode(item.toJson()),
    ]);
  }
}
