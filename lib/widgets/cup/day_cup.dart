import '../../core/time/local_date.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/day_status.dart';
import 'cup_painter.dart';

/// The Hero tag shared by a goal's cup for [date] on the Shelf and on the
/// session screens.
String cupHeroTag(int goalId, LocalDate date) => 'cup-$goalId-${date.toIso()}';

/// How one day renders as a cup.
class DayCup {
  const DayCup({
    required this.date,
    required this.status,
    required this.totalSeconds,
    required this.dailyTargetSeconds,
    this.isActiveDay = true,
    this.running = false,
  });

  final LocalDate date;
  final DayStatus status;
  final int totalSeconds;
  final int dailyTargetSeconds;

  /// Whether the day's weekday is an active day. Future rest days keep the
  /// FUTURE status but draw as rest cups, so rest days are visible ahead (D2).
  final bool isActiveDay;

  /// A session is pouring into this day right now.
  final bool running;

  double get fill => totalSeconds / dailyTargetSeconds;

  CupState get state => switch (status) {
    DayStatus.future => isActiveDay ? CupState.ghost : CupState.rest,
    DayStatus.rest || DayStatus.outsideHorizon => CupState.rest,
    DayStatus.spilled => CupState.spilled,
    DayStatus.targetReached || DayStatus.saved => CupState.filled,
    DayStatus.pending =>
      totalSeconds > 0 || running ? CupState.filled : CupState.empty,
  };

  String get statusWord => switch (status) {
    DayStatus.future => isActiveDay ? 'upcoming' : 'rest day',
    DayStatus.rest => 'rest day',
    DayStatus.outsideHorizon => 'outside the horizon',
    DayStatus.spilled => 'spilled',
    DayStatus.targetReached => 'target reached',
    DayStatus.saved => 'saved',
    DayStatus.pending => running ? 'in progress' : 'today',
  };

  /// e.g. "6 December, 12 minutes, saved".
  String get semanticLabel {
    final minutes = totalSeconds ~/ 60;
    return '${longDate(date)}, $minutes '
        '${minutes == 1 ? 'minute' : 'minutes'}, $statusWord';
  }
}
