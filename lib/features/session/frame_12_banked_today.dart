import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/today.dart';
import '../../data/repositories/goal_repository.dart';
import '../../widgets/cup/cup_widget.dart';
import '../shelf/shelf_controller.dart';
import 'session_copy.dart';
import 'widgets/session_layout.dart';

/// Frame 12, Banked today. Keep pouring (still there after the target is
/// reached) and Adjust time are in the dock.
class BankedTodayScreen extends ConsumerWidget {
  const BankedTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider).value;
    final today = ref.watch(todayProvider);
    if (goal == null) return const Scaffold();
    final logs = ref
        .watch(logsInRangeProvider((goalId: goal.id, from: today, to: today)))
        .value;
    if (logs == null) return const Scaffold();
    final total = logs[today]?.totalSeconds ?? 0;
    final target = goal.dailyTargetSeconds;

    return SessionLayout(
      goalId: goal.id,
      date: today,
      seconds: total,
      cup: CupWidget(
        size: CupSize.large,
        fill: total / target,
        state: total > 0 ? CupState.filled : CupState.empty,
        showThresholds: true,
        dailyTargetSeconds: target,
      ),
      message: CoachBubble(
        text: bankedTodayLine(seconds: total, targetSeconds: target),
        mood: bankedTodayMood(seconds: total, targetSeconds: target),
      ),
    );
  }
}
