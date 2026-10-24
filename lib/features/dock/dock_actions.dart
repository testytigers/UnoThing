import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/time/local_date.dart';
import '../../core/time/today.dart';
import '../../data/repositories/daily_log_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/day_status.dart';
import '../../domain/models/goal.dart';
import '../../domain/services/day_status_service.dart';
import '../../widgets/edit_log_sheet.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/reminder_tile.dart';
import '../notifications/reminders_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../pro/pro.dart';
import '../pro/pro_sheet.dart';
import '../session/session_controller.dart';
import '../session/session_copy.dart';
import '../shelf/shelf_controller.dart';

/// What the dock (and a few screens) can do, in one place.
///
/// Dialogs and sheets open on the root navigator: the dock sits above the
/// pages, outside any route.

/// Discard asks for confirmation only above this much unbanked time.
const confirmDiscardAboveSeconds = 60;

BuildContext? get _navigatorContext => rootNavigatorKey.currentContext;

/// Whether [goal] can pour today: a pour day inside the horizon.
bool canPourToday(Goal goal, LocalDate today, int todaySeconds) {
  final status = dayStatus(today, todaySeconds, goal, today);
  return status == DayStatus.pending ||
      status == DayStatus.saved ||
      status == DayStatus.targetReached;
}

/// Starts pouring into [goal] right where you are; the dock turns into the
/// live timer.
Future<void> startPouring(WidgetRef ref, Goal goal) async {
  ref.read(selectedGoalIdProvider.notifier).select(goal.id);
  HapticFeedback.mediumImpact();
  await ref
      .read(sessionControllerProvider.notifier)
      .start(goal, ref.read(todayProvider));
}

/// Starts [goal] and opens the full session screen (Frame 8).
Future<void> startAndOpen(WidgetRef ref, Goal goal) async {
  await startPouring(ref, goal);
  ref.read(routerProvider).go(Routes.session);
}

Future<void> togglePause(WidgetRef ref) async {
  final controller = ref.read(sessionControllerProvider.notifier);
  if (ref.read(sessionControllerProvider).isRunning) {
    await controller.pause();
  } else {
    await controller.resume();
  }
}

/// The running session's screen: Frame 8 while running, 11 while paused.
void openSession(WidgetRef ref) {
  final state = ref.read(sessionControllerProvider);
  final s = state.session;
  if (s == null) return;
  ref.read(selectedGoalIdProvider.notifier).select(s.goalId);
  ref
      .read(routerProvider)
      .go(state.isRunning ? Routes.session : Routes.sessionStop);
}

/// Finish: pause and show the choices (Frame 11).
Future<void> finishSession(WidgetRef ref) async {
  final s = ref.read(sessionControllerProvider).session;
  if (s == null) return;
  await ref.read(sessionControllerProvider.notifier).pause();
  ref.read(selectedGoalIdProvider.notifier).select(s.goalId);
  ref.read(routerProvider).go(Routes.sessionStop);
}

/// Continue from Frame 11.
Future<void> continueSession(WidgetRef ref) async {
  await ref.read(sessionControllerProvider.notifier).resume();
  ref.read(routerProvider).go(Routes.session);
}

bool _saving = false;

/// Save session: banks it, back to the goal's Shelf where the cup rises,
/// with a toast (a full week gets its own).
Future<void> saveSession(WidgetRef ref) async {
  if (_saving) return;
  _saving = true;
  try {
    final state = ref.read(sessionControllerProvider);
    final session = state.session;
    if (session == null) return;
    final added = session.unbankedAt(state.now);
    final goal = await ref.read(goalRepositoryProvider).getGoal(session.goalId);
    await ref.read(sessionControllerProvider.notifier).bank();
    final monday = session.date.startOfWeek;
    final week = goal == null
        ? null
        : await ref
              .read(dailyLogRepositoryProvider)
              .getRange(goal.id, monday, monday.addDays(6));
    if (week != null && completesWeek(goal!, session.date, week)) {
      showAppToast(weekCompleteToast, mood: MascotMood.cool);
    } else {
      showAppToast(bankedToast(added));
    }
    ref.read(selectedGoalIdProvider.notifier).select(session.goalId);
    ref.read(routerProvider).go(Routes.shelf);
  } finally {
    _saving = false;
  }
}

/// Discard: drops the unbanked part, asking first above a minute.
Future<void> discardSession(WidgetRef ref) async {
  final state = ref.read(sessionControllerProvider);
  final unbanked = state.session?.unbankedAt(state.now) ?? 0;
  final context = _navigatorContext;
  if (unbanked > confirmDiscardAboveSeconds && context != null) {
    final t = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Mascot(mood: MascotMood.disappointed, size: 84),
        title: const Text('Let this pour go?'),
        content: const Text(
          "This session's time will be lost. "
          'Everything you banked before stays safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: t.ink),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: t.dangerInk),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  await ref.read(sessionControllerProvider.notifier).discard();
  ref.read(routerProvider).go(Routes.shelf);
}

/// Adjust time for [goal] on [date] (Edit Log).
Future<void> adjustTime(WidgetRef ref, Goal goal, LocalDate date) async {
  final context = _navigatorContext;
  if (context == null) return;
  final seconds = await ref
      .read(dailyLogRepositoryProvider)
      .totalSecondsFor(goal.id, date);
  if (!context.mounted) return;
  await showEditLogSheet(
    context,
    goal: goal,
    date: date,
    currentSeconds: seconds,
  );
}

/// [goal]'s daily reminder, in a small sheet.
Future<void> editReminder(WidgetRef ref, Goal goal) async {
  final context = _navigatorContext;
  if (context == null) return;
  await showModalBottomSheet<void>(
    context: context,
    builder: (_) => _ReminderSheet(goalId: goal.id),
  );
}

class _ReminderSheet extends ConsumerWidget {
  const _ReminderSheet({required this.goalId});

  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final goal = (ref.watch(goalsProvider).value ?? const <Goal>[])
        .where((g) => g.id == goalId)
        .firstOrNull;
    if (goal == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reminder', style: AppText.headline.copyWith(color: t.ink)),
            const SizedBox(height: AppSpacing.md),
            ReminderTile.daily(
              context: context,
              title: goal.title,
              minutes: goal.reminderMinutes,
              onChanged: (minutes) async {
                await ref
                    .read(goalRepositoryProvider)
                    .setReminder(goal.id, minutes);
                if (minutes != null) {
                  await ref
                      .read(notificationsEnabledProvider.notifier)
                      .ensure();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// New habit: the onboarding steps for another goal (Pro), or first what
/// Pro adds.
Future<void> addHabit(WidgetRef ref) async {
  final context = _navigatorContext;
  if (context == null) return;
  if (!ref.read(proProvider) && !await showProSheet(context)) return;
  ref.read(onboardingControllerProvider.notifier).startNew();
  ref.read(routerProvider).push(Routes.goal);
}
