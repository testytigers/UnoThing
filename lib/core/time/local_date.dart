import 'package:flutter/foundation.dart';

/// A calendar date with no time or zone. Arithmetic runs on UTC midnights so
/// daylight saving transitions never shift a day.
@immutable
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  /// The local calendar date of [dateTime].
  factory LocalDate.from(DateTime dateTime) {
    final d = dateTime.toLocal();
    return LocalDate(d.year, d.month, d.day);
  }

  /// Parses `yyyy-MM-dd`.
  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) throw FormatException('Not a date', iso);
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  static LocalDate _fromUtc(DateTime d) => LocalDate(d.year, d.month, d.day);

  /// 1 = Monday ... 7 = Sunday.
  int get weekday => _utc.weekday;

  LocalDate addDays(int days) => _fromUtc(_utc.add(Duration(days: days)));

  /// Adds calendar months, clamping the day to the target month's length
  /// (Jan 31 + 1 month = Feb 28, or Feb 29 in a leap year).
  LocalDate addMonths(int months) {
    final index = year * 12 + (month - 1) + months;
    final y = index ~/ 12;
    final m = index % 12 + 1;
    final lastDay = DateTime.utc(y, m + 1, 0).day;
    return LocalDate(y, m, day > lastDay ? lastDay : day);
  }

  /// Whole days from this date to [other] (positive if [other] is later).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  /// Monday of this date's week.
  LocalDate get startOfWeek => addDays(1 - weekday);

  /// Local midnight at the start of this date.
  DateTime get startOfDayLocal => DateTime(year, month, day);

  /// Local midnight at the start of the next date.
  DateTime get endOfDayLocal => DateTime(year, month, day + 1);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
