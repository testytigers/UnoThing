import 'package:flutter/foundation.dart';

import '../../core/time/local_date.dart';
import 'day_status.dart';

@immutable
class DailyLog {
  const DailyLog({
    required this.date,
    required this.totalSeconds,
    required this.status,
  });

  final LocalDate date;
  final int totalSeconds;
  final DayStatus status;
}
