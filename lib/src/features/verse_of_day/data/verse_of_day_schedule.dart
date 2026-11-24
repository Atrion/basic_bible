/// The Verse of the Day: one curated reference for every calendar date,
/// including February 29, so there is a different verse on each of the 365
/// (366 in a leap year) days. The same date always gives the same verse.
///
/// Only references are stored here. The text is read from the Bible the
/// reader already has, so it follows the chosen translation and works
/// offline. To change a verse, edit the reference for that date below; every
/// reference was checked against the KJV text, and a test keeps the list at
/// exactly 366 valid entries.
///
/// Reference format: `BOOK C:V`, `BOOK C:V-V` or, for one-chapter books,
/// `BOOK V-V` (BOOK is the 3-character book id, e.g. JHN, 1CO, PSA).
///
/// Themes (chosen with Gospel hall assemblies in mind): January the Person of
/// Christ; February the love and grace of God; March the cross and
/// redemption; April the resurrection; May new birth and assurance; June the
/// gospel; July holiness and the Christian walk; August prayer and the
/// Psalms; September the assembly, worship and the Lord's Supper; October
/// the Scriptures and endurance; November the Lord's return; December the
/// incarnation and the glory of Christ.
library;

import 'halifax_time.dart';

class VerseOfDayEntry {
  const VerseOfDayEntry({
    required this.bookId,
    required this.chapter,
    required this.firstVerse,
    required this.lastVerse,
  });

  final String bookId;
  final int chapter;
  final int firstVerse;
  final int lastVerse;

  bool get isRange => lastVerse > firstVerse;

  /// Parses `JHN 3:16`, `ROM 8:37-39` or `JUD 24-25`.
  factory VerseOfDayEntry.parse(String reference) {
    final match = RegExp(
      r'^(\w{3}) (?:(\d+):)?(\d+)(?:-(\d+))?$',
    ).firstMatch(reference.trim());
    if (match == null) {
      throw FormatException('Bad Verse of the Day reference', reference);
    }
    final first = int.parse(match.group(3)!);
    final last = match.group(4) == null ? first : int.parse(match.group(4)!);
    return VerseOfDayEntry(
      bookId: match.group(1)!,
      chapter: match.group(2) == null ? 1 : int.parse(match.group(2)!),
      firstVerse: first,
      lastVerse: last,
    );
  }

  @override
  String toString() =>
      '$bookId $chapter:$firstVerse${isRange ? '-$lastVerse' : ''}';
}

const List<int> _daysInMonthLeapYear = [
  31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31, //
];

/// 0-based position of [month]/[day] in a leap year (Feb 29 has its own).
int verseDayIndex(int month, int day) {
  if (month < 1 || month > 12) {
    throw RangeError.range(month, 1, 12, 'month');
  }
  if (day < 1 || day > _daysInMonthLeapYear[month - 1]) {
    throw RangeError.range(day, 1, _daysInMonthLeapYear[month - 1], 'day');
  }
  var index = day - 1;
  for (var m = 0; m < month - 1; m++) {
    index += _daysInMonthLeapYear[m];
  }
  return index;
}

VerseOfDayEntry verseForDate(int month, int day) =>
    VerseOfDayEntry.parse(kVerseOfTheDayReferences[verseDayIndex(month, day)]);

/// The verse for [instant], using the calendar date in Halifax, Nova Scotia
/// (America/Halifax). The verse changes at midnight Halifax time for everyone,
/// wherever their phone is.
VerseOfDayEntry verseForInstant(DateTime instant) {
  final date = halifaxDate(instant);
  return verseForDate(date.month, date.day);
}

// January: The Person of Christ and new life
const List<String> _january = [
  '2CO 5:17', // Jan 1
  'JHN 1:12', // Jan 2
  'JHN 1:14', // Jan 3
  'JHN 1:29', // Jan 4
  'JHN 3:3', // Jan 5
  'JHN 3:16', // Jan 6
  'JHN 3:36', // Jan 7
  'JHN 5:24', // Jan 8
  'JHN 6:35', // Jan 9
  'JHN 6:37', // Jan 10
  'JHN 6:47', // Jan 11
  'JHN 8:12', // Jan 12
  'JHN 8:36', // Jan 13
  'JHN 10:9', // Jan 14
  'JHN 10:10', // Jan 15
  'JHN 10:11', // Jan 16
  'JHN 10:27-28', // Jan 17
  'JHN 11:25-26', // Jan 18
  'JHN 12:32', // Jan 19
  'JHN 14:6', // Jan 20
  'JHN 14:27', // Jan 21
  'JHN 15:5', // Jan 22
  'JHN 15:13', // Jan 23
  'JHN 16:33', // Jan 24
  'JHN 17:3', // Jan 25
  'JHN 19:30', // Jan 26
  'JHN 20:31', // Jan 27
  'JHN 21:17', // Jan 28
  'PHP 2:5-8', // Jan 29
  'PHP 2:9-11', // Jan 30
  'HEB 1:3', // Jan 31
];

// February: The love of God and the grace of God
const List<String> _february = [
  'ROM 5:8', // Feb 1
  '1JN 4:9-10', // Feb 2
  '1JN 4:19', // Feb 3
  'EPH 2:4-5', // Feb 4
  'EPH 2:8-9', // Feb 5
  'TIT 3:5', // Feb 6
  'TIT 2:11', // Feb 7
  'ROM 3:23-24', // Feb 8
  'ROM 3:25', // Feb 9
  'ROM 4:5', // Feb 10
  'ROM 4:25', // Feb 11
  'ROM 5:1', // Feb 12
  'ROM 5:20', // Feb 13
  'ROM 8:1', // Feb 14
  'ROM 8:15-16', // Feb 15
  'ROM 8:28', // Feb 16
  'ROM 8:31-32', // Feb 17
  'ROM 8:35', // Feb 18
  'ROM 8:37-39', // Feb 19
  'ROM 10:9', // Feb 20
  'ROM 10:13', // Feb 21
  'ROM 11:33', // Feb 22
  'ROM 12:1', // Feb 23
  'ROM 14:8', // Feb 24
  'ROM 15:13', // Feb 25
  'GAL 2:20', // Feb 26
  'GAL 6:14', // Feb 27
  'EPH 1:7', // Feb 28
  'EPH 3:19', // Feb 29
];

// March: The cross, the blood and redemption
const List<String> _march = [
  'ISA 53:5', // Mar 1
  'ISA 53:6', // Mar 2
  'ISA 53:3', // Mar 3
  'ISA 53:11', // Mar 4
  'PSA 22:1', // Mar 5
  'PSA 22:16', // Mar 6
  'ZEC 12:10', // Mar 7
  'MAT 26:28', // Mar 8
  'MAT 27:46', // Mar 9
  'MRK 10:45', // Mar 10
  'LUK 23:34', // Mar 11
  'LUK 23:43', // Mar 12
  'LUK 24:46-47', // Mar 13
  '1PE 1:18-19', // Mar 14
  '1PE 2:24', // Mar 15
  '1PE 3:18', // Mar 16
  'HEB 9:12', // Mar 17
  'HEB 9:22', // Mar 18
  'HEB 9:26', // Mar 19
  'HEB 10:10', // Mar 20
  'HEB 10:12', // Mar 21
  'HEB 10:14', // Mar 22
  'HEB 10:19', // Mar 23
  'HEB 12:2', // Mar 24
  'HEB 13:12', // Mar 25
  'ROM 6:23', // Mar 26
  'ROM 8:3', // Mar 27
  '2CO 5:21', // Mar 28
  'GAL 3:13', // Mar 29
  'COL 1:20', // Mar 30
  'COL 2:14', // Mar 31
];

// April: The resurrection and the living Lord
const List<String> _april = [
  '1CO 15:3-4', // Apr 1
  '1CO 15:20', // Apr 2
  '1CO 15:55-57', // Apr 3
  '1CO 15:58', // Apr 4
  'MAT 28:5-6', // Apr 5
  'MAT 28:18', // Apr 6
  'MAT 28:20', // Apr 7
  'MRK 16:6', // Apr 8
  'LUK 24:5-6', // Apr 9
  'LUK 24:32', // Apr 10
  'LUK 24:39', // Apr 11
  'JHN 20:19', // Apr 12
  'JHN 20:28', // Apr 13
  'JHN 20:29', // Apr 14
  'ACT 2:24', // Apr 15
  'ACT 2:36', // Apr 16
  'ACT 3:15', // Apr 17
  'ACT 4:12', // Apr 18
  'ACT 10:43', // Apr 19
  'ACT 13:38-39', // Apr 20
  'ACT 16:31', // Apr 21
  'ACT 17:30-31', // Apr 22
  'ROM 1:4', // Apr 23
  'ROM 6:4', // Apr 24
  'ROM 6:9', // Apr 25
  'ROM 8:11', // Apr 26
  'ROM 8:34', // Apr 27
  '1PE 1:3', // Apr 28
  'REV 1:17-18', // Apr 29
  'REV 1:5', // Apr 30
];

// May: The new birth, faith and assurance of salvation
const List<String> _may = [
  'JHN 1:13', // May 1
  'JHN 3:7', // May 2
  'JHN 3:14-15', // May 3
  'JHN 4:14', // May 4
  'JHN 6:40', // May 5
  'JHN 6:68', // May 6
  'JHN 7:37-38', // May 7
  'JHN 9:25', // May 8
  'JHN 10:29', // May 9
  '1JN 5:11-12', // May 10
  '1JN 5:13', // May 11
  '1JN 1:7', // May 12
  '1JN 1:9', // May 13
  '1JN 2:1-2', // May 14
  '1JN 3:1', // May 15
  '1JN 3:2', // May 16
  '1JN 3:14', // May 17
  '1JN 5:4', // May 18
  '1PE 1:23', // May 19
  '1PE 2:9', // May 20
  'EPH 1:13-14', // May 21
  'EPH 2:1', // May 22
  'EPH 2:13', // May 23
  'EPH 2:19', // May 24
  'PHP 1:6', // May 25
  'PHP 3:9', // May 26
  '2TI 1:9', // May 27
  '2TI 1:12', // May 28
  'HEB 7:25', // May 29
  'HEB 11:1', // May 30
  'HEB 11:6', // May 31
];

// June: The gospel and its proclamation
const List<String> _june = [
  'MAT 28:19', // Jun 1
  'MRK 16:15', // Jun 2
  'LUK 15:7', // Jun 3
  'LUK 15:10', // Jun 4
  'LUK 15:20', // Jun 5
  'LUK 18:13', // Jun 6
  'LUK 19:10', // Jun 7
  'LUK 5:32', // Jun 8
  'ACT 1:8', // Jun 9
  'ACT 2:38', // Jun 10
  'ACT 2:21', // Jun 11
  'ACT 5:31', // Jun 12
  'ACT 8:35', // Jun 13
  'ACT 20:21', // Jun 14
  'ACT 20:24', // Jun 15
  'ACT 26:18', // Jun 16
  'ROM 1:16', // Jun 17
  'ROM 1:17', // Jun 18
  'ROM 10:14-15', // Jun 19
  'ROM 10:17', // Jun 20
  '1CO 1:18', // Jun 21
  '1CO 1:21', // Jun 22
  '1CO 1:23-24', // Jun 23
  '1CO 2:2', // Jun 24
  '1CO 9:16', // Jun 25
  '2CO 4:5', // Jun 26
  '2CO 4:6', // Jun 27
  '2CO 5:20', // Jun 28
  '2CO 6:2', // Jun 29
  '2TI 4:2', // Jun 30
];

// July: Holiness, separation and the Christian walk
const List<String> _july = [
  'ROM 6:11', // Jul 1
  'ROM 6:13', // Jul 2
  'ROM 6:22', // Jul 3
  'ROM 8:6', // Jul 4
  'ROM 8:14', // Jul 5
  'ROM 12:2', // Jul 6
  'ROM 12:10', // Jul 7
  'ROM 12:21', // Jul 8
  'ROM 13:12', // Jul 9
  'ROM 13:14', // Jul 10
  '1CO 6:19-20', // Jul 11
  '1CO 10:13', // Jul 12
  '1CO 10:31', // Jul 13
  '1CO 16:13-14', // Jul 14
  '2CO 6:17-18', // Jul 15
  '2CO 7:1', // Jul 16
  '2CO 12:9', // Jul 17
  'GAL 5:16', // Jul 18
  'GAL 5:22-23', // Jul 19
  'GAL 6:9', // Jul 20
  'EPH 4:1', // Jul 21
  'EPH 4:30', // Jul 22
  'EPH 4:32', // Jul 23
  'EPH 5:2', // Jul 24
  'EPH 5:8', // Jul 25
  'EPH 5:15-16', // Jul 26
  'EPH 6:10', // Jul 27
  'EPH 6:11', // Jul 28
  'PHP 4:8', // Jul 29
  'COL 3:2', // Jul 30
  'COL 3:17', // Jul 31
];

// August: Prayer, trust and the Psalms
const List<String> _august = [
  'PSA 1:2', // Aug 1
  'PSA 16:11', // Aug 2
  'PSA 18:2', // Aug 3
  'PSA 19:14', // Aug 4
  'PSA 23:1', // Aug 5
  'PSA 23:4', // Aug 6
  'PSA 27:1', // Aug 7
  'PSA 27:14', // Aug 8
  'PSA 32:1', // Aug 9
  'PSA 34:8', // Aug 10
  'PSA 34:18', // Aug 11
  'PSA 37:4', // Aug 12
  'PSA 40:1-2', // Aug 13
  'PSA 46:1', // Aug 14
  'PSA 46:10', // Aug 15
  'PSA 51:10', // Aug 16
  'PSA 55:22', // Aug 17
  'PSA 62:1', // Aug 18
  'PSA 73:25-26', // Aug 19
  'PSA 84:11', // Aug 20
  'PSA 90:12', // Aug 21
  'PSA 91:1-2', // Aug 22
  'PSA 100:4-5', // Aug 23
  'PSA 103:1-2', // Aug 24
  'PSA 103:12', // Aug 25
  'PSA 107:1', // Aug 26
  'PSA 118:24', // Aug 27
  'PSA 119:105', // Aug 28
  'PSA 121:1-2', // Aug 29
  'PSA 130:3-4', // Aug 30
  'PSA 139:23-24', // Aug 31
];

// September: The assembly: gathering, worship and the Lord's Supper
const List<String> _september = [
  'MAT 18:20', // Sep 1
  'ACT 2:42', // Sep 2
  'ACT 2:46-47', // Sep 3
  'ACT 20:7', // Sep 4
  '1CO 11:23-24', // Sep 5
  '1CO 11:25-26', // Sep 6
  '1CO 10:16-17', // Sep 7
  'LUK 22:19', // Sep 8
  'JHN 4:23', // Sep 9
  'JHN 4:24', // Sep 10
  'HEB 10:24-25', // Sep 11
  'HEB 13:15', // Sep 12
  'HEB 13:16', // Sep 13
  '1PE 2:5', // Sep 14
  'REV 1:6', // Sep 15
  'EPH 4:3', // Sep 16
  'EPH 4:4-6', // Sep 17
  'EPH 4:15-16', // Sep 18
  'EPH 5:25', // Sep 19
  'EPH 5:27', // Sep 20
  '1CO 12:12', // Sep 21
  '1CO 12:27', // Sep 22
  '1CO 14:26', // Sep 23
  '1CO 14:40', // Sep 24
  'COL 3:15', // Sep 25
  'COL 3:16', // Sep 26
  '1TH 5:11', // Sep 27
  '1TH 5:16-18', // Sep 28
  'PSA 133:1', // Sep 29
  'PSA 122:1', // Sep 30
];

// October: The Scriptures, wisdom and endurance
const List<String> _october = [
  '2TI 3:16-17', // Oct 1
  '2TI 2:15', // Oct 2
  '2PE 1:21', // Oct 3
  'PSA 119:9', // Oct 4
  'PSA 119:11', // Oct 5
  'PSA 119:130', // Oct 6
  'PSA 19:7', // Oct 7
  'PRO 3:5-6', // Oct 8
  'PRO 4:23', // Oct 9
  'PRO 9:10', // Oct 10
  'PRO 14:12', // Oct 11
  'PRO 18:10', // Oct 12
  'PRO 18:24', // Oct 13
  'PRO 29:25', // Oct 14
  'ISA 26:3', // Oct 15
  'ISA 40:31', // Oct 16
  'ISA 41:10', // Oct 17
  'ISA 43:2', // Oct 18
  'ISA 55:1', // Oct 19
  'ISA 55:6-7', // Oct 20
  'ISA 55:8-9', // Oct 21
  'ISA 55:11', // Oct 22
  'JER 29:11', // Oct 23
  'JER 33:3', // Oct 24
  'LAM 3:22-23', // Oct 25
  'MIC 6:8', // Oct 26
  'HAB 3:17-18', // Oct 27
  'ZEP 3:17', // Oct 28
  'MAL 3:6', // Oct 29
  'JAS 1:5', // Oct 30
  'JAS 1:22', // Oct 31
];

// November: The Lord's return and the believer's hope
const List<String> _november = [
  'JHN 14:1-3', // Nov 1
  'ACT 1:11', // Nov 2
  '1TH 4:16-17', // Nov 3
  '1TH 4:13-14', // Nov 4
  '1TH 5:9', // Nov 5
  '1TH 5:23', // Nov 6
  '1CO 15:51-52', // Nov 7
  'PHP 3:20-21', // Nov 8
  'TIT 2:13', // Nov 9
  'HEB 9:28', // Nov 10
  'PSA 46:9', // Nov 11
  'JAS 5:8', // Nov 12
  '1PE 5:4', // Nov 13
  '1JN 2:28', // Nov 14
  'REV 22:20', // Nov 15
  'REV 22:17', // Nov 16
  'REV 21:3-4', // Nov 17
  'REV 21:5', // Nov 18
  'REV 21:23', // Nov 19
  'REV 22:3-4', // Nov 20
  'REV 7:9-10', // Nov 21
  'REV 7:17', // Nov 22
  'REV 5:9', // Nov 23
  'REV 5:12', // Nov 24
  'REV 5:13', // Nov 25
  'REV 4:11', // Nov 26
  'REV 3:20', // Nov 27
  'REV 3:21', // Nov 28
  '2TI 4:8', // Nov 29
  'JUD 24-25', // Nov 30
];

// December: The incarnation and the glory of Christ
const List<String> _december = [
  'ISA 9:6', // Dec 1
  'ISA 7:14', // Dec 2
  'MIC 5:2', // Dec 3
  'MAL 4:2', // Dec 4
  'LUK 1:31-32', // Dec 5
  'LUK 1:46-47', // Dec 6
  'LUK 1:68', // Dec 7
  'LUK 1:78-79', // Dec 8
  'MAT 1:21', // Dec 9
  'MAT 1:23', // Dec 10
  'MAT 2:2', // Dec 11
  'MAT 2:10-11', // Dec 12
  'JHN 1:9', // Dec 13
  'JHN 1:10-11', // Dec 14
  'GAL 4:4-5', // Dec 15
  '1TI 1:15', // Dec 16
  '1TI 2:5', // Dec 17
  '1TI 3:16', // Dec 18
  '2CO 8:9', // Dec 19
  '2CO 9:15', // Dec 20
  'COL 2:9', // Dec 21
  'COL 1:18', // Dec 22
  'COL 1:27', // Dec 23
  'LUK 2:10', // Dec 24
  'LUK 2:11', // Dec 25
  'LUK 2:14', // Dec 26
  'LUK 2:30', // Dec 27
  'HEB 2:9', // Dec 28
  'HEB 2:14-15', // Dec 29
  'HEB 4:15-16', // Dec 30
  'HEB 13:8', // Dec 31
];

/// All 366 references, January 1 first and December 31 last.
const List<String> kVerseOfTheDayReferences = [
  ..._january,
  ..._february,
  ..._march,
  ..._april,
  ..._may,
  ..._june,
  ..._july,
  ..._august,
  ..._september,
  ..._october,
  ..._november,
  ..._december,
];
