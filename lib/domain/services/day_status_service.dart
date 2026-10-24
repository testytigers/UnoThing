import '../../core/constants.dart';
import '../../core/time/local_date.dart';
import '../models/day_status.dart';
import '../models/goal.dart';

/// The status of [date] given its banked [totalSeconds]. Pure: the stored
/// status can always be recomputed from this.
///
/// Rules are evaluated top to bottom; the first match wins.
DayStatus dayStatus(
  LocalDate date,
  int totalSeconds,
  Goal goal,
  LocalDate today,
) {
  if (!goal.contains(date)) return DayStatus.outsideHorizon; // D7
  if (date.isAfter(today)) return DayStatus.future;
  if (!goal.isActiveDay(date)) return DayStatus.rest; // D2
  if (totalSeconds >= goal.dailyTargetSeconds) return DayStatus.targetReached;
  if (totalSeconds >= safetyNetSeconds) return DayStatus.saved;
  if (date == today) return DayStatus.pending;
  return DayStatus.spilled; // includes 1..299 s, D1
}
