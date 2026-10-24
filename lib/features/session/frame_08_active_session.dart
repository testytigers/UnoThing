import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/cup/cup_widget.dart';
import 'session_controller.dart';
import 'session_copy.dart';
import 'widgets/session_layout.dart';

/// Frame 8, Active Session: Pause and Finish are in the dock. Back keeps the
/// session running and returns to the Shelf.
class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  bool _banner = false;
  Timer? _bannerTimer;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _celebrate() {
    setState(() => _banner = true);
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _banner = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The safety net was just crossed in this session.
    ref.listen(sessionControllerProvider, (prev, next) {
      final was = prev?.session?.safetyNetFired ?? true;
      final now = next.session?.safetyNetFired ?? false;
      if (!was && now) _celebrate();
    });

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
        running: state.isRunning,
        showThresholds: true,
        dailyTargetSeconds: target,
      ),
      // Crossing the safety net, the mascot on top says so for a moment.
      message: _banner
          ? const CoachBubble(text: safetyNetBanner, mood: MascotMood.sparkle)
          : CoachBubble(
              text: liveSessionLine(
                seconds: value,
                targetSeconds: target,
                running: state.isRunning,
              ),
              mood: liveSessionMood(
                seconds: value,
                targetSeconds: target,
                running: state.isRunning,
              ),
            ),
    );
  }
}
