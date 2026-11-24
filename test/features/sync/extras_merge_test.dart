import 'package:basic_bible/src/features/sync/data/extras_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settings merge', () {
    test('a new device adopts the settings already in the cloud', () {
      final result = mergeSettings(
        local: {'themeMode': 'light'},
        localStamps: {},
        base: null,
        remote: {'themeMode': (value: 'dark', stamp: 100)},
        now: 500,
      );
      expect(result.changesForLocal, {'themeMode': 'dark'});
      expect(result.needsUpload, isFalse);
      expect(result.merged['themeMode']!.value, 'dark');
    });

    test('a first upload is stamped with the current time', () {
      final result = mergeSettings(
        local: {'reader_bold_divine_name': true},
        localStamps: {},
        base: null,
        remote: {},
        now: 500,
      );
      expect(result.needsUpload, isTrue);
      expect(result.changesForLocal, isEmpty);
      expect(result.merged['reader_bold_divine_name']!.stamp, 500);
    });

    test('a second new device does not overwrite the first one', () {
      // Device A uploads at time 500.
      final a = mergeSettings(
        local: {'themeMode': 'dark'},
        localStamps: {},
        base: null,
        remote: {},
        now: 500,
      );
      // Device B (defaults only, never synced) syncs later.
      final b = mergeSettings(
        local: {'themeMode': 'light'},
        localStamps: {},
        base: null,
        remote: a.merged,
        now: 900,
      );
      expect(b.changesForLocal, {'themeMode': 'dark'});
      expect(b.needsUpload, isFalse);
    });

    test('a change made here since the last sync is uploaded', () {
      final result = mergeSettings(
        local: {'themeMode': 'dark'},
        localStamps: {'themeMode': 10},
        base: {'themeMode': 'light'},
        remote: {'themeMode': (value: 'light', stamp: 50)},
        now: 200,
      );
      expect(result.changesForLocal, isEmpty);
      expect(result.needsUpload, isTrue);
      expect(result.merged['themeMode']!.value, 'dark');
      expect(result.merged['themeMode']!.stamp, 200);
    });

    test('a newer change from another device is applied here', () {
      final result = mergeSettings(
        local: {'themeMode': 'light'},
        localStamps: {'themeMode': 10},
        base: {'themeMode': 'light'},
        remote: {'themeMode': (value: 'dark', stamp: 150)},
        now: 200,
      );
      expect(result.changesForLocal, {'themeMode': 'dark'});
      expect(result.needsUpload, isFalse);
    });

    test('different settings changed on different devices are both kept', () {
      final result = mergeSettings(
        local: {'themeMode': 'dark', 'languageCode': 'en'},
        localStamps: {'themeMode': 10, 'languageCode': 10},
        base: {'themeMode': 'light', 'languageCode': 'en'},
        remote: {
          'themeMode': (value: 'light', stamp: 10),
          'languageCode': (value: 'fr', stamp: 300),
        },
        now: 200,
      );
      expect(result.merged['themeMode']!.value, 'dark');
      expect(result.merged['languageCode']!.value, 'fr');
      expect(result.changesForLocal, {'languageCode': 'fr'});
      expect(result.needsUpload, isTrue);
    });

    test('settings the device has not set yet are filled in from the cloud', () {
      final result = mergeSettings(
        local: {},
        localStamps: {},
        base: null,
        remote: {'reader_font_size': (value: 1.5, stamp: 7)},
        now: 100,
      );
      expect(result.changesForLocal, {'reader_font_size': 1.5});
    });

    test('identical settings change nothing', () {
      final result = mergeSettings(
        local: {'reader_layout_mode': 'split', 'x_list': <String>['a']}
            ..remove('x_list'),
        localStamps: {'reader_layout_mode': 40},
        base: {'reader_layout_mode': 'split'},
        remote: {'reader_layout_mode': (value: 'split', stamp: 40)},
        now: 100,
      );
      expect(result.changesForLocal, isEmpty);
      expect(result.needsUpload, isFalse);
    });

    test('every value type survives the cloud document', () {
      const entries = <String, SettingEntry>{
        'reader_bold_divine_name': (value: true, stamp: 1),
        'reader_layout_mode': (value: 'split', stamp: 2),
        'reader_font_size': (value: 1.25, stamp: 3),
      };
      final parsed = parseSettingsDoc(encodeSettingsDoc(entries))!;
      expect(parsed['reader_bold_divine_name']!.value, true);
      expect(parsed['reader_layout_mode']!.value, 'split');
      expect(parsed['reader_font_size']!.value, 1.25);
      expect(parsed['reader_font_size']!.stamp, 3);
    });

    test('unknown settings and bad entries in the cloud are ignored', () {
      final parsed = parseSettingsDoc(
        '{"version":1,"settings":{'
        '"sync_mode":{"t":"s","v":"manual","at":1},'
        '"themeMode":{"t":"s","v":"dark","at":2},'
        '"languageCode":{"t":"i","v":"en","at":3}}}',
      )!;
      expect(parsed.keys.toList(), ['themeMode']);
    });

    test('a document that is not usable is rejected, not merged', () {
      expect(parseSettingsDoc('not json'), isNull);
      expect(parseSettingsDoc('{"settings": 5}'), isNull);
    });

    test('only app settings are synced, not device state', () {
      expect(kSyncedSettingKeys.contains('themeMode'), isTrue);
      expect(kSyncedSettingKeys.contains('sync_mode'), isFalse);
      expect(kSyncedSettingKeys.contains('split_view_enabled'), isFalse);
      expect(kSyncedSettingKeys.contains('reference_history'), isFalse);
      expect(
        kSyncedSettingKeys.contains('advanced_translation_catalog_url_override'),
        isFalse,
      );
    });
  });

  group('reading position', () {
    PositionSnapshot pos(String book, int chapter, int at,
            {int? verse, String translation = 'kjv'}) =>
        PositionSnapshot(
          translationId: translation,
          bookId: book,
          chapter: chapter,
          verse: verse,
          updatedAt: at,
        );

    test('uploads when nothing is in the cloud yet', () {
      expect(
        decidePosition(local: pos('JHN', 3, 100), remote: null, lastOfferedStamp: null),
        PositionAction.push,
      );
      expect(
        decidePosition(local: null, remote: null, lastOfferedStamp: null),
        PositionAction.none,
      );
    });

    test('offers a newer position from another device, once', () {
      final local = pos('GEN', 1, 100);
      final remote = pos('JHN', 3, 200, verse: 16);
      expect(
        decidePosition(local: local, remote: remote, lastOfferedStamp: null),
        PositionAction.offerRemote,
      );
      expect(
        decidePosition(local: local, remote: remote, lastOfferedStamp: 200),
        PositionAction.none,
      );
    });

    test('uploads when this device read more recently', () {
      expect(
        decidePosition(
          local: pos('JHN', 3, 300),
          remote: pos('GEN', 1, 200),
          lastOfferedStamp: null,
        ),
        PositionAction.push,
      );
    });

    test('does nothing when both devices are at the same place', () {
      expect(
        decidePosition(
          local: pos('JHN', 3, 300, verse: 16),
          remote: pos('JHN', 3, 200, verse: 16),
          lastOfferedStamp: null,
        ),
        PositionAction.none,
      );
    });

    test('a new device with no saved position is offered the cloud one', () {
      expect(
        decidePosition(
          local: null,
          remote: pos('PSA', 23, 50),
          lastOfferedStamp: null,
        ),
        PositionAction.offerRemote,
      );
    });

    test('a position round-trips through its document', () {
      final snapshot = pos('ROM', 8, 123, verse: 28, translation: 'asv');
      final parsed = PositionSnapshot.tryParse(snapshot.toJsonString())!;
      expect(parsed.samePlaceAs(snapshot), isTrue);
      expect(parsed.updatedAt, 123);
      expect(PositionSnapshot.tryParse('nope'), isNull);
    });
  });

  group('prayer list merge', () {
    PrayerRecord rec(String id, int created, int updated,
            {bool deleted = false, String? text}) =>
        PrayerRecord(
          id: id,
          text: text ?? 'Person $id',
          createdAt: created,
          updatedAt: updated,
          deleted: deleted,
        );

    test('names added on each device end up on both', () {
      final result = mergePrayer(
        local: [rec('a', 1, 1)],
        remote: [rec('b', 2, 2)],
      );
      expect(result.merged.map((r) => r.id).toList(), ['a', 'b']);
      expect(result.toApplyLocally.map((r) => r.id).toList(), ['b']);
      expect(result.toUpload.map((r) => r.id).toList(), ['a']);
    });

    test('a removal on another device removes the name here', () {
      final result = mergePrayer(
        local: [rec('a', 1, 1)],
        remote: [rec('a', 1, 5, deleted: true)],
      );
      expect(result.merged.single.deleted, isTrue);
      expect(result.toApplyLocally.single.deleted, isTrue);
      expect(result.toUpload, isEmpty);
    });

    test('adding a name back after removing it wins', () {
      final result = mergePrayer(
        local: [rec('a', 1, 9)], // undone at time 9
        remote: [rec('a', 1, 5, deleted: true)],
      );
      expect(result.merged.single.deleted, isFalse);
      expect(result.toUpload.single.updatedAt, 9);
      expect(result.toApplyLocally, isEmpty);
    });

    test('a removal wins a tie', () {
      final result = mergePrayer(
        local: [rec('a', 1, 5)],
        remote: [rec('a', 1, 5, deleted: true)],
      );
      expect(result.merged.single.deleted, isTrue);
    });

    test('identical lists need no work', () {
      final result = mergePrayer(
        local: [rec('a', 1, 1), rec('b', 2, 2)],
        remote: [rec('b', 2, 2), rec('a', 1, 1)],
      );
      expect(result.toApplyLocally, isEmpty);
      expect(result.toUpload, isEmpty);
    });

    test('names keep the order they were added in on every device', () {
      final result = mergePrayer(
        local: [rec('z', 5, 5), rec('m', 1, 1)],
        remote: [rec('k', 3, 3)],
      );
      expect(result.merged.map((r) => r.id).toList(), ['m', 'k', 'z']);
    });

    test('old removal markers are dropped, recent ones kept', () {
      final now = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch;
      final old = now - const Duration(days: 90).inMilliseconds;
      final recent = now - const Duration(days: 10).inMilliseconds;
      final kept = purgeOldTombstones(
        [
          rec('old', 1, old, deleted: true),
          rec('recent', 1, recent, deleted: true),
          rec('live', 1, old),
        ],
        now: now,
      );
      expect(kept.map((r) => r.id).toList(), ['recent', 'live']);
    });

    test('entries saved by the first version of the list still load', () {
      final record = PrayerRecord.tryParse(
        '{"id":"1-0","text":"Mary","createdAt":"2026-01-01T00:00:00.000"}',
      )!;
      expect(record.text, 'Mary');
      expect(record.deleted, isFalse);
      expect(record.updatedAt, record.createdAt);
      expect(record.createdAt, greaterThan(0));
    });

    test('damaged entries are skipped', () {
      expect(PrayerRecord.tryParse('not json'), isNull);
      expect(PrayerRecord.tryParse('{"id":"1"}'), isNull);
      expect(PrayerRecord.tryParse('{"id":"1","text":"   "}'), isNull);
    });
  });
}
