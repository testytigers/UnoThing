import 'package:flutter/foundation.dart';

import '../../core/time/local_date.dart';

@immutable
class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.horizonMonths,
    required this.dailyTargetSeconds,
    required this.activeWeekdays,
    required this.startDate,
    this.reminderMinutes,
    this.position = 0,
  });

  final int id;
  final String title;

  /// One of 1, 3, 6, 9, 12.
  final int horizonMonths;
  final int dailyTargetSeconds;

  /// Subset of 1..7, Monday = 1.
  final Set<int> activeWeekdays;

  /// The local date the contract was signed.
  final LocalDate startDate;

  /// Daily reminder time, in minutes after local midnight. Null when off.
  final int? reminderMinutes;

  /// Order of the Shelf's pages, lowest first.
  final int position;

  /// `startDate + horizonMonths calendar months - 1 day`.
  LocalDate get endDate => horizonEndDate(startDate, horizonMonths);

  /// Days from start to end, inclusive.
  int get totalDays => startDate.daysUntil(endDate) + 1;

  bool contains(LocalDate date) =>
      !date.isBefore(startDate) && !date.isAfter(endDate);

  bool isActiveDay(LocalDate date) => activeWeekdays.contains(date.weekday);
}

LocalDate horizonEndDate(LocalDate start, int months) =>
    start.addMonths(months).addDays(-1);
