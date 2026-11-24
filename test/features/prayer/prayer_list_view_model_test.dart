import 'package:basic_bible/src/features/prayer/application/prayer_list_view_model.dart';
import 'package:basic_bible/src/features/sync/application/auto_sync_scheduler.dart';
import 'package:basic_bible/src/features/sync/data/extras_merge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingTrigger implements NoteSyncTrigger {
  int count = 0;
  @override
  void schedule() => count++;
}

void main() {
  var time = 1000;
  int clock() => time += 1;

  Future<SharedPreferences> freshPrefs([
    Map<String, Object> values = const {},
  ]) {
    SharedPreferences.setMockInitialValues(values);
    time = 1000;
    return SharedPreferences.getInstance();
  }

  test('adds names in order and ignores blank entries', () async {
    final notifier = PrayerListNotifier(await freshPrefs(), clock: clock);

    expect(await notifier.add('  Mary  '), isTrue);
    expect(await notifier.add('Surgery on Friday'), isTrue);
    expect(await notifier.add('   '), isFalse);

    expect(notifier.state.map((item) => item.text), [
      'Mary',
      'Surgery on Friday',
    ]);
  });

  test('removes an entry and puts it back in its place for undo', () async {
    final notifier = PrayerListNotifier(await freshPrefs(), clock: clock);
    await notifier.add('Mary');
    await notifier.add('John');
    await notifier.add('Sarah');

    final john = notifier.state[1];
    await notifier.remove(john.id);
    expect(notifier.state.map((item) => item.text), ['Mary', 'Sarah']);

    await notifier.restore(john);
    expect(notifier.state.map((item) => item.text), [
      'Mary',
      'John',
      'Sarah',
    ]);
  });

  test('the list survives restarting the app', () async {
    final prefs = await freshPrefs();
    final first = PrayerListNotifier(prefs, clock: clock);
    await first.add('Mary');
    await first.add('John');
    await first.remove(first.state.first.id);

    final second = PrayerListNotifier(prefs, clock: clock);
    expect(second.state.map((item) => item.text), ['John']);
  });

  test('a removal is kept as a hidden marker so it can sync', () async {
    final prefs = await freshPrefs();
    final notifier = PrayerListNotifier(prefs, clock: clock);
    await notifier.add('Mary');
    await notifier.remove(notifier.state.single.id);

    expect(notifier.state, isEmpty);
    final stored = prefs
        .getStringList(PrayerListNotifier.prefsKey)!
        .map(PrayerRecord.tryParse)
        .single!;
    expect(stored.deleted, isTrue);
  });

  test('every change asks for a sync', () async {
    final trigger = _CountingTrigger();
    final notifier = PrayerListNotifier(
      await freshPrefs(),
      syncTrigger: trigger,
      clock: clock,
    );
    await notifier.add('Mary');
    await notifier.remove(notifier.state.single.id);
    expect(trigger.count, 2);
  });

  test('reload picks up changes made by a sync', () async {
    final prefs = await freshPrefs();
    final notifier = PrayerListNotifier(prefs, clock: clock);
    await prefs.setStringList(PrayerListNotifier.prefsKey, [
      const PrayerRecord(
        id: 'remote-1',
        text: 'From another device',
        createdAt: 5,
        updatedAt: 5,
        deleted: false,
      ).toJsonString(),
    ]);
    notifier.reload();
    expect(notifier.state.map((item) => item.text), ['From another device']);
  });

  test('a corrupted stored entry does not break the rest of the list', () async {
    final prefs = await freshPrefs({
      PrayerListNotifier.prefsKey: [
        'not json at all',
        '{"id":"1","text":"Mary","createdAt":"2026-01-01T00:00:00.000"}',
        '{"id":"2"}',
      ],
    });

    final notifier = PrayerListNotifier(prefs, clock: clock);
    expect(notifier.state.map((item) => item.text), ['Mary']);
  });
}
