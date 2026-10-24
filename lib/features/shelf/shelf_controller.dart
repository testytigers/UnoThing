import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/local_date.dart';
import '../../data/repositories/daily_log_repository.dart';
import '../../domain/models/daily_log.dart';
import '../../domain/models/day_status.dart';
import '../../domain/models/goal.dart';
import '../../domain/services/day_status_service.dart';
import '../../widgets/cup/day_cup.dart';
import '../session/session_controller.dart';

/// First and last Mondays of weeks that overlap the horizon.
(LocalDate, LocalDate) weekBounds(Goal goal) =>
    (goal.startDate.startOfWeek, goal.endDate.startOfWeek);

/// The week the Shelf opens on: today's week, clamped to the horizon. After
/// the horizon ends this is the final week, read-only (D6).
LocalDate defaultWeek(Goal goal, LocalDate today) {
  final (first, last) = weekBounds(goal);
  final week = today.startOfWeek;
  if (week.isBefore(first)) return first;
  if (week.isAfter(last)) return last;
  return week;
}

/// The Monday a goal's Shelf page navigated to, or null for [defaultWeek].
class ShelfWeekNotifier extends Notifier<LocalDate?> {
  ShelfWeekNotifier(this.goalId);

  final int goalId;

  @override
  LocalDate? build() => null;

  void show(LocalDate monday) => state = monday;
}

/// Per goal id.
final shelfWeekProvider =
    NotifierProvider.family<ShelfWeekNotifier, LocalDate?, int>(
      ShelfWeekNotifier.new,
    );

/// A goal's banked logs from `from` to `to` inclusive.
final logsInRangeProvider =
    StreamProvider.family<
      Map<LocalDate, DailyLog>,
      ({int goalId, LocalDate from, LocalDate to})
    >(
      (ref, q) => ref
          .watch(dailyLogRepositoryProvider)
          .watchRange(q.goalId, q.from, q.to),
    );

/// Builds [goal]'s cup for [date], counting a live session's unbanked time
/// when it pours into this goal.
DayCup dayCupFor({
  required LocalDate date,
  required Goal goal,
  required LocalDate today,
  required Map<LocalDate, DailyLog> logs,
  required SessionState session,
}) {
  final s = session.session;
  final live = s?.goalId == goal.id && s?.date == date ? session.value : null;
  final total = live ?? logs[date]?.totalSeconds ?? 0;
  return DayCup(
    date: date,
    status: dayStatus(date, total, goal, today),
    totalSeconds: total,
    dailyTargetSeconds: goal.dailyTargetSeconds,
    isActiveDay: goal.isActiveDay(date),
    running: live != null && session.isRunning,
  );
}

/// Whether saving [date] just completed its week: every pour day of that
/// Monday-to-Sunday week inside the horizon is saved, and [date] is the last
/// of them.
bool completesWeek(Goal goal, LocalDate date, Map<LocalDate, DailyLog> logs) {
  final monday = date.startOfWeek;
  final pourDays = [
    for (var i = 0; i < 7; i++)
      if (goal.contains(monday.addDays(i)) &&
          goal.isActiveDay(monday.addDays(i)))
        monday.addDays(i),
  ];
  if (pourDays.isEmpty || pourDays.last != date) return false;
  return pourDays.every((d) => logs[d]?.status.isSuccess ?? false);
}

/// Where a tap on a Shelf cup leads.
enum ShelfTap { none, startSession, openSession, bankedToday, pastDay }

/// Where a tap on [goalId]'s [cup] leads. While another goal pours, today's
/// cup opens only its banked view: one goal pours at a time.
ShelfTap shelfTapFor(
  DayCup cup,
  LocalDate today,
  SessionState session, {
  required int goalId,
}) {
  switch (cup.status) {
    case DayStatus.future:
    case DayStatus.rest:
    case DayStatus.outsideHorizon:
      return ShelfTap.none;
    case DayStatus.spilled:
      return ShelfTap.pastDay;
    case DayStatus.pending:
    case DayStatus.saved:
    case DayStatus.targetReached:
      if (cup.date != today) return ShelfTap.pastDay;
      final s = session.session;
      if (s?.goalId == goalId && s?.date == today) return ShelfTap.openSession;
      if (cup.totalSeconds > 0) return ShelfTap.bankedToday;
      return s == null ? ShelfTap.startSession : ShelfTap.none;
  }
}
