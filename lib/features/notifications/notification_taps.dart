import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/routes.dart';
import '../../core/time/today.dart';
import '../../data/repositories/daily_log_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/day_status.dart';
import '../../domain/services/day_status_service.dart';
import '../session/session_controller.dart';
import 'app_channels.dart';
import 'notification_scheduler.dart';

/// Opens what a notification is about: the Shelf on its goal, or, from the
/// "Start pouring" button, a new session on it (as the Shelf's button would).
Future<void> handleNotificationTap(
  ProviderContainer container,
  NotificationTap tap,
) async {
  final router = container.read(routerProvider);
  final goalId = NotificationPayload.goalId(tap.payload);
  if (goalId != null) {
    container.read(selectedGoalIdProvider.notifier).select(goalId);
  }
  final sessions = container.read(sessionControllerProvider.notifier);
  final active = container.read(sessionControllerProvider);
  if (active.session != null) {
    // Already pouring: back to it.
    router.go(active.isRunning ? Routes.session : Routes.sessionStop);
    return;
  }
  if (tap.actionId == NotificationPayload.startAction && goalId != null) {
    final goal = await container.read(goalRepositoryProvider).getGoal(goalId);
    final today = container.read(todayProvider);
    if (goal != null) {
      final total = await container
          .read(dailyLogRepositoryProvider)
          .totalSecondsFor(goal.id, today);
      final status = dayStatus(today, total, goal, today);
      if (status == DayStatus.pending ||
          status == DayStatus.saved ||
          status == DayStatus.targetReached) {
        await sessions.start(goal, today);
        router.go(Routes.session);
        return;
      }
    }
  }
  router.go(Routes.shelf);
}
