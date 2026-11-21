import 'package:basic_bible/src/features/prayer/application/prayer_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> freshPrefs([Map<String, Object> values = const {}]) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('adds names in order and ignores blank entries', () async {
    final notifier = PrayerListNotifier(await freshPrefs());

    expect(await notifier.add('  Mary  '), isTrue);
    expect(await notifier.add('Surgery on Friday'), isTrue);
    expect(await notifier.add('   '), isFalse);

    expect(notifier.state.map((item) => item.text), [
      'Mary',
      'Surgery on Friday',
    ]);
  });

  test('removes an entry and can put it back for undo', () async {
    final notifier = PrayerListNotifier(await freshPrefs());
    await notifier.add('Mary');
    await notifier.add('John');
    await notifier.add('Sarah');

    final john = notifier.state[1];
    await notifier.remove(john.id);
    expect(notifier.state.map((item) => item.text), ['Mary', 'Sarah']);

    await notifier.insertAt(1, john);
    expect(notifier.state.map((item) => item.text), [
      'Mary',
      'John',
      'Sarah',
    ]);
  });

  test('the list survives restarting the app', () async {
    final prefs = await freshPrefs();
    final first = PrayerListNotifier(prefs);
    await first.add('Mary');
    await first.add('John');
    await first.remove(first.state.first.id);

    final second = PrayerListNotifier(prefs);
    expect(second.state.map((item) => item.text), ['John']);
  });

  test('a corrupted stored entry does not break the rest of the list', () async {
    final prefs = await freshPrefs({
      PrayerListNotifier.prefsKey: [
        'not json at all',
        '{"id":"1","text":"Mary","createdAt":"2026-01-01T00:00:00.000"}',
        '{"id":"2"}',
      ],
    });

    final notifier = PrayerListNotifier(prefs);
    expect(notifier.state.map((item) => item.text), ['Mary']);
  });
}
