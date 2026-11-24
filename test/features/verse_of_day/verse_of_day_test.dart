import 'package:basic_bible/src/features/verse_of_day/data/halifax_time.dart';
import 'package:basic_bible/src/features/verse_of_day/data/verse_of_day_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Verse of the Day list', () {
    test('has one valid reference for each of the 366 calendar dates', () {
      expect(kVerseOfTheDayReferences, hasLength(366));
      for (final reference in kVerseOfTheDayReferences) {
        final entry = VerseOfDayEntry.parse(reference);
        expect(entry.chapter, greaterThan(0), reason: reference);
        expect(entry.lastVerse, greaterThanOrEqualTo(entry.firstVerse));
      }
    });

    test('never repeats a verse, even inside a range', () {
      final seen = <String>{};
      for (final reference in kVerseOfTheDayReferences) {
        final entry = VerseOfDayEntry.parse(reference);
        for (var v = entry.firstVerse; v <= entry.lastVerse; v++) {
          final key = '${entry.bookId} ${entry.chapter}:$v';
          expect(seen.add(key), isTrue, reason: 'repeated: $key');
        }
      }
    });

    test('maps calendar dates to positions, with February 29 included', () {
      expect(verseDayIndex(1, 1), 0);
      expect(verseDayIndex(2, 29), 59);
      expect(verseDayIndex(3, 1), 60);
      expect(verseDayIndex(12, 31), 365);
      expect(() => verseDayIndex(2, 30), throwsRangeError);
      expect(() => verseDayIndex(13, 1), throwsRangeError);
    });

    test('some dates are chosen on purpose', () {
      expect(verseForDate(1, 1).toString(), '2CO 5:17');
      expect(verseForDate(9, 1).toString(), 'MAT 18:20');
      expect(verseForDate(12, 25).toString(), 'LUK 2:11');
      // One-chapter books are stored without a chapter number.
      final jude = verseForDate(11, 30);
      expect(jude.bookId, 'JUD');
      expect(jude.chapter, 1);
      expect(jude.firstVerse, 24);
      expect(jude.lastVerse, 25);
    });

    test('rejects a malformed reference', () {
      expect(() => VerseOfDayEntry.parse('John 3:16'), throwsFormatException);
    });
  });

  group('Halifax time', () {
    test('daylight saving starts and ends at the right instants in 2026', () {
      expect(isHalifaxDaylightTime(DateTime.utc(2026, 3, 8, 5, 59, 59)), isFalse);
      expect(isHalifaxDaylightTime(DateTime.utc(2026, 3, 8, 6)), isTrue);
      expect(isHalifaxDaylightTime(DateTime.utc(2026, 11, 1, 4, 59, 59)), isTrue);
      expect(isHalifaxDaylightTime(DateTime.utc(2026, 11, 1, 5)), isFalse);
      expect(isHalifaxDaylightTime(DateTime.utc(2026, 7, 1)), isTrue);
      expect(isHalifaxDaylightTime(DateTime.utc(2026, 1, 1)), isFalse);
    });

    test('daylight saving follows the second Sunday in March in other years', () {
      // 2027: second Sunday in March is the 14th; first Sunday in Nov is the 7th.
      expect(isHalifaxDaylightTime(DateTime.utc(2027, 3, 14, 5, 59)), isFalse);
      expect(isHalifaxDaylightTime(DateTime.utc(2027, 3, 14, 6)), isTrue);
      expect(isHalifaxDaylightTime(DateTime.utc(2027, 11, 7, 4, 59)), isTrue);
      expect(isHalifaxDaylightTime(DateTime.utc(2027, 11, 7, 5)), isFalse);
    });

    test('the date changes at midnight in Halifax in summer (UTC-3)', () {
      final before = halifaxDate(DateTime.utc(2026, 7, 1, 2, 59, 59));
      final after = halifaxDate(DateTime.utc(2026, 7, 1, 3));
      expect((before.month, before.day), (6, 30));
      expect((after.month, after.day), (7, 1));
    });

    test('the date changes at midnight in Halifax in winter (UTC-4)', () {
      final before = halifaxDate(DateTime.utc(2026, 1, 1, 3, 59, 59));
      final after = halifaxDate(DateTime.utc(2026, 1, 1, 4));
      expect((before.year, before.month, before.day), (2025, 12, 31));
      expect((after.year, after.month, after.day), (2026, 1, 1));
    });

    test('the verse switches exactly at Halifax midnight', () {
      final lastSecond = verseForInstant(DateTime.utc(2026, 12, 25, 3, 59, 59));
      final firstSecond = verseForInstant(DateTime.utc(2026, 12, 25, 4));
      expect(lastSecond.toString(), verseForDate(12, 24).toString());
      expect(firstSecond.toString(), 'LUK 2:11');
    });

    test('February 29 has its own verse in leap years only', () {
      final leapDay = verseForInstant(DateTime.utc(2028, 2, 29, 15));
      expect(leapDay.toString(), verseForDate(2, 29).toString());
      final march1 = verseForInstant(DateTime.utc(2027, 3, 1, 15));
      expect(march1.toString(), verseForDate(3, 1).toString());
    });

    test('time until Halifax midnight, including the clock-change days', () {
      expect(
        timeUntilHalifaxMidnight(DateTime.utc(2026, 7, 1, 2, 59, 59)),
        const Duration(seconds: 1),
      );
      // 01:00 AST on the day clocks fall back: 23 real hours to midnight.
      expect(
        timeUntilHalifaxMidnight(DateTime.utc(2026, 11, 1, 5)),
        const Duration(hours: 23),
      );
      // 01:00 AST on the day clocks spring forward: 22 real hours to midnight.
      expect(
        timeUntilHalifaxMidnight(DateTime.utc(2026, 3, 8, 5)),
        const Duration(hours: 22),
      );
    });
  });
}
