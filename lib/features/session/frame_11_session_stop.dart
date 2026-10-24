import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/cup/cup_widget.dart';
import 'session_controller.dart';
import 'session_copy.dart';
import 'widgets/session_layout.dart';

/// Frame 11, Session Stop. The timer is paused; Continue, Save session and
/// Discard are in the dock (`dock_actions.dart`).
class SessionStopScreen extends ConsumerWidget {
  const SessionStopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final goal = ref.watch(sessionGoalProvider);
    final session = state.session;
    if (session == null || goal == null) return const Scaffold();
    final value = state.value!;
    final target = goal.dailyTargetSeconds;

    return SessionLayout(
      goalId: goal.id,
      date: session.date,
      seconds: value,
      cup: CupWidget(
        size: CupSize.large,
        fill: value / target,
        state: value > 0 ? CupState.filled : CupState.empty,
        showThresholds: true,
        dailyTargetSeconds: target,
      ),
      message: const CoachBubble(text: stopSessionLine, mood: MascotMood.happy),
    );
  }
}
