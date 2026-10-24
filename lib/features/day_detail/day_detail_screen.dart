import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/time/local_date.dart';
import '../../core/time/today.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/day_status.dart';
import '../../domain/services/day_status_service.dart';
import '../../widgets/cup/cup_widget.dart';
import '../session/widgets/session_layout.dart';
import '../shelf/shelf_controller.dart';

/// A past day. Shows Frame 13 (saved / on target) or Frame 14 (spilled)
/// from the day's live status, so Adjust time switches between them in place.
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.date});

  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider).value;
    final today = ref.watch(todayProvider);
    if (goal == null) return const Scaffold();
    final logs = ref
        .watch(logsInRangeProvider((goalId: goal.id, from: date, to: date)))
        .value;
    if (logs == null) return const Scaffold();
    final total = logs[date]?.totalSeconds ?? 0;
    final status = dayStatus(date, total, goal, today);
    final spilled = status == DayStatus.spilled;

    final message = switch (status) {
      // Frame 14
      DayStatus.spilled => SessionMessage(
        title: 'Spilled milk',
        titleColor: context.tokens.dangerInk,
        mood: MascotMood.disappointed,
        body:
            "You missed this day. No use crying over it: "
            "let's not miss another.",
      ),
      // Frame 13
      DayStatus.targetReached => const SessionMessage(
        title: 'On target',
        mood: MascotMood.cool,
        body: "A full cup. That's what showing up looks like.",
      ),
      DayStatus.saved => const SessionMessage(
        title: 'Saved by the net',
        mood: MascotMood.happy,
        body: 'Good job, you made it to the min required.',
      ),
      _ => null,
    };

    return SessionLayout(
      goalId: goal.id,
      date: date,
      seconds: total,
      alertTimer: spilled,
      cup: CupWidget(
        size: CupSize.large,
        fill: total / goal.dailyTargetSeconds,
        state: spilled ? CupState.spilled : CupState.filled,
      ),
      message: message,
    );
  }
}
