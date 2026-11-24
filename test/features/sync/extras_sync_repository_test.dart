import 'package:basic_bible/src/features/sync/data/drive_extras_api.dart';
import 'package:basic_bible/src/features/sync/data/extras_merge.dart';
import 'package:basic_bible/src/features/sync/data/extras_sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _File {
  _File(this.name, this.content, this.updatedAt, this.deleted);
  String name;
  String content;
  int? updatedAt;
  bool deleted;
}

/// A pretend Google Drive app-data folder shared by all "devices".
class FakeDrive implements DriveExtrasApi {
  final Map<String, _File> files = {};
  int _next = 0;
  int downloads = 0;
  int uploads = 0;

  @override
  Future<List<DriveExtraFile>> listExtraFiles(String accessToken) async => [
    for (final e in files.entries)
      DriveExtraFile(
        fileId: e.key,
        name: e.value.name,
        updatedAtMillis: e.value.updatedAt,
        isDeleted: e.value.deleted,
      ),
  ];

  @override
  Future<String> downloadExtra(String accessToken, String fileId) async {
    downloads++;
    return files[fileId]!.content;
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
    uploads++;
    final id = existingFileId ?? 'file-${_next++}';
    files[id] = _File(fileName, content, updatedAtMillis, isDeleted);
  }
}

/// Lets one SharedPreferences instance stand in for several devices.
class Devices {
  Devices(this.prefs);
  final SharedPreferences prefs;
  final Map<String, Map<String, Object>> _saved = {};
  String? _current;

  Future<void> use(String name) async {
    if (_current != null) {
      _saved[_current!] = {
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      };
    }
    await prefs.clear();
    for (final e in (_saved[name] ?? <String, Object>{}).entries) {
      final v = e.value;
      if (v is bool) {
        await prefs.setBool(e.key, v);
      } else if (v is int) {
        await prefs.setInt(e.key, v);
      } else if (v is double) {
        await prefs.setDouble(e.key, v);
      } else if (v is String) {
        await prefs.setString(e.key, v);
      } else if (v is List<String>) {
        await prefs.setStringList(e.key, v);
      }
    }
    _current = name;
  }
}

void main() {
  late SharedPreferences prefs;
  late FakeDrive drive;
  late Devices devices;
  var time = 1000;

  ExtrasSyncRepository repo() => ExtrasSyncRepository(
    prefs: prefs,
    accessToken: () async => 'token',
    api: drive,
    clock: () => time += 10,
  );

  Future<void> setUpDevices() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    drive = FakeDrive();
    devices = Devices(prefs);
    time = 1000;
  }

  List<String> prayerTexts() => [
    for (final raw in prefs.getStringList('prayer_list') ?? <String>[])
      if (!PrayerRecord.tryParse(raw)!.deleted) PrayerRecord.tryParse(raw)!.text,
  ];

  Future<void> addPrayer(String id, String text) async {
    final list = prefs.getStringList('prayer_list') ?? <String>[];
    final now = time += 10;
    await prefs.setStringList('prayer_list', [
      ...list,
      PrayerRecord(
        id: id,
        text: text,
        createdAt: now,
        updatedAt: now,
        deleted: false,
      ).toJsonString(),
    ]);
  }

  Future<void> removePrayer(String id) async {
    final now = time += 10;
    await prefs.setStringList('prayer_list', [
      for (final raw in prefs.getStringList('prayer_list') ?? <String>[])
        () {
          final r = PrayerRecord.tryParse(raw)!;
          return (r.id == id ? r.copyWith(deleted: true, updatedAt: now) : r)
              .toJsonString();
        }(),
    ]);
  }

  group('prayer list sync', () {
    test('names reach another device and removals follow', () async {
      await setUpDevices();
      await devices.use('phone');
      await addPrayer('1-0', 'Mary');
      await addPrayer('2-0', 'Surgery on Friday');
      final first = await repo().syncOnce();
      expect(first.prayerChanged, isFalse);
      expect(drive.uploads, 2);

      await devices.use('tablet');
      final onTablet = await repo().syncOnce();
      expect(onTablet.prayerChanged, isTrue);
      expect(prayerTexts(), ['Mary', 'Surgery on Friday']);

      await removePrayer('1-0');
      await repo().syncOnce();

      await devices.use('phone');
      final back = await repo().syncOnce();
      expect(back.prayerChanged, isTrue);
      expect(prayerTexts(), ['Surgery on Friday']);
    });

    test('an unchanged list costs no downloads and no uploads', () async {
      await setUpDevices();
      await devices.use('phone');
      await addPrayer('1-0', 'Mary');
      await repo().syncOnce();
      await devices.use('tablet');
      await repo().syncOnce();

      drive.downloads = 0;
      drive.uploads = 0;
      await repo().syncOnce();
      expect(drive.downloads, 0);
      expect(drive.uploads, 0);
    });

    test('names added on both devices at once both survive', () async {
      await setUpDevices();
      await devices.use('phone');
      await addPrayer('1-0', 'From the phone');
      await devices.use('tablet');
      await addPrayer('2-0', 'From the tablet');
      await repo().syncOnce(); // tablet uploads its name
      await devices.use('phone');
      await repo().syncOnce(); // phone uploads its own, downloads the tablet's
      await devices.use('tablet');
      await repo().syncOnce();
      expect(prayerTexts(), ['From the phone', 'From the tablet']);
    });
  });

  group('settings sync', () {
    test('settings follow the user to a new device', () async {
      await setUpDevices();
      await devices.use('phone');
      await prefs.setString('themeMode', 'dark');
      await prefs.setBool('reader_bold_divine_name', false);
      await prefs.setDouble('reader_font_size', 1.4);
      await repo().syncOnce();

      await devices.use('tablet');
      final result = await repo().syncOnce();
      expect(result.settingsChanged, isTrue);
      expect(prefs.getString('themeMode'), 'dark');
      expect(prefs.getBool('reader_bold_divine_name'), false);
      expect(prefs.getDouble('reader_font_size'), 1.4);
    });

    test('a later change on one device reaches the other', () async {
      await setUpDevices();
      await devices.use('phone');
      await prefs.setString('themeMode', 'dark');
      await repo().syncOnce();
      await devices.use('tablet');
      await repo().syncOnce();

      await prefs.setString('themeMode', 'light'); // changed on the tablet
      await repo().syncOnce();

      await devices.use('phone');
      final result = await repo().syncOnce();
      expect(result.settingsChanged, isTrue);
      expect(prefs.getString('themeMode'), 'light');
    });

    test('device-only settings are never uploaded', () async {
      await setUpDevices();
      await devices.use('phone');
      await prefs.setString('sync_mode', 'manual');
      await prefs.setString('themeMode', 'dark');
      await repo().syncOnce();
      final stored = drive.files.values
          .firstWhere((f) => f.name == 'settings.sync')
          .content;
      expect(stored.contains('sync_mode'), isFalse);
      expect(stored.contains('themeMode'), isTrue);
    });

    test('a damaged settings file in the cloud is left alone', () async {
      await setUpDevices();
      await devices.use('phone');
      await prefs.setString('themeMode', 'dark');
      drive.files['file-x'] = _File('settings.sync', 'garbage', 1, false);
      final result = await repo().syncOnce();
      expect(result.settingsChanged, isFalse);
      expect(drive.files['file-x']!.content, 'garbage');
    });
  });

  group('reading position sync', () {
    Future<void> read(String book, int chapter, int? verse) async {
      await prefs.setString('bible_book', book);
      await prefs.setInt('bible_chapter', chapter);
      if (verse != null) {
        await prefs.setInt('bible_verse', verse);
      } else {
        await prefs.remove('bible_verse');
      }
      await prefs.setInt('bible_position_updated_at', time += 10);
    }

    test('another device is offered the position once, not forced', () async {
      await setUpDevices();
      await devices.use('phone');
      await read('JHN', 3, 16);
      await repo().syncOnce();

      await devices.use('tablet');
      final offer = (await repo().syncOnce()).offeredPosition;
      expect(offer, isNotNull);
      expect(offer!.bookId, 'JHN');
      expect(offer.chapter, 3);
      expect(offer.verse, 16);
      // The tablet's own position was not touched.
      expect(prefs.getString('bible_book'), isNull);
      // Offered once only.
      expect((await repo().syncOnce()).offeredPosition, isNull);
    });

    test('the most recent reader wins and the other is offered it', () async {
      await setUpDevices();
      await devices.use('phone');
      await read('JHN', 3, null);
      await repo().syncOnce();
      await devices.use('tablet');
      await repo().syncOnce();
      await read('ROM', 8, 28); // tablet reads on, later
      await repo().syncOnce();

      await devices.use('phone');
      final offer = (await repo().syncOnce()).offeredPosition;
      expect(offer!.bookId, 'ROM');
      expect(offer.chapter, 8);
    });
  });
}
