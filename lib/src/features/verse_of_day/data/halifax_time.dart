/// Date and time in Halifax, Nova Scotia (America/Halifax), without a
/// timezone database.
///
/// Halifax is UTC-4 (Atlantic Standard Time) and UTC-3 (Atlantic Daylight
/// Time) from 02:00 local on the second Sunday in March until 02:00 local on
/// the first Sunday in November. Those are the current Canadian rules.
library;

const Duration _standardOffset = Duration(hours: -4);
const Duration _daylightOffset = Duration(hours: -3);

/// Day of the month of the [n]th (1-based) Sunday in [month] of [year].
int _nthSunday(int year, int month, int n) {
  final first = DateTime.utc(year, month, 1);
  final daysToSunday = (DateTime.sunday - first.weekday) % 7;
  return 1 + daysToSunday + (n - 1) * 7;
}

/// Whether daylight saving time is in effect in Halifax at [instant].
bool isHalifaxDaylightTime(DateTime instant) {
  final utc = instant.toUtc();
  // 02:00 AST (UTC-4) is 06:00 UTC; 02:00 ADT (UTC-3) is 05:00 UTC.
  final start = DateTime.utc(utc.year, 3, _nthSunday(utc.year, 3, 2), 6);
  final end = DateTime.utc(utc.year, 11, _nthSunday(utc.year, 11, 1), 5);
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// The Halifax wall-clock time at [instant], as a UTC-flagged DateTime (so its
/// fields read as the clock in Halifax would).
DateTime halifaxWallClock(DateTime instant) {
  final utc = instant.toUtc();
  return utc.add(isHalifaxDaylightTime(utc) ? _daylightOffset : _standardOffset);
}

/// The calendar date in Halifax at [instant].
({int year, int month, int day}) halifaxDate(DateTime instant) {
  final wall = halifaxWallClock(instant);
  return (year: wall.year, month: wall.month, day: wall.day);
}

/// How long until the next midnight in Halifax (when the verse changes).
Duration timeUntilHalifaxMidnight(DateTime instant) {
  final wall = halifaxWallClock(instant);
  final nextMidnightWall = DateTime.utc(wall.year, wall.month, wall.day + 1);
  // Midnight is never inside the 02:00 transition hour, so one check is
  // enough to pick the right offset.
  final asDaylight = nextMidnightWall.subtract(_daylightOffset);
  final nextMidnight = isHalifaxDaylightTime(asDaylight)
      ? asDaylight
      : nextMidnightWall.subtract(_standardOffset);
  return nextMidnight.difference(instant.toUtc());
}
