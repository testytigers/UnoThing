import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../core/time/today.dart';
import '../../data/repositories/daily_log_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../session/session_controller.dart';
import 'notification_scheduler.dart';
import 'reminder_planner.dart';

/// Every goal's banked seconds on a date.
final dayTotalsProvider = StreamProvider.family<Map<int, int>, LocalDate>(
  (ref, date) => ref.watch(dailyLogRepositoryProvider).watchDay(date),
);

/// Keeps the scheduled reminders in step with the goals, today's cups, the
/// running session and the reminder switches. Watched by the app root.
class RemindersController extends Notifier<void> {
  Timer? _debounce;
  AppLifecycleListener? _lifecycle;
  List<PlannedNotification>? _scheduled;
  Set<int> _withdrawn = const {};
  bool? _exact;

  NotificationScheduler get _scheduler =>
      ref.read(notificationSchedulerProvider);

  @override
  void build() {
    ref.watch(goalsProvider);
    ref.watch(dayTotalsProvider(ref.watch(todayProvider)));
    ref.watch(sessionControllerProvider.select((s) => s.session));
    ref.watch(appPreferencesProvider);
    // Allowed on-the-minute timing since the last plan: schedule again.
    final exact = ref.watch(exactRemindersProvider);
    final timingChanged = _exact != null && _exact != exact;
    _exact = exact;
    _lifecycle?.dispose();
    // Back in the app: the clock or the time zone may have moved on.
    _lifecycle = AppLifecycleListener(onResume: () => _replan(force: true));
    ref.onDispose(() {
      _debounce?.cancel();
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    _replan(force: timingChanged);
  }

  /// Rebuilds the plan once things settle (a save touches several rows).
  void _replan({bool force = false}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_apply(force: force));
    });
  }

  Future<void> _apply({required bool force}) async {
    final goals = ref.read(goalsProvider).value;
    final today = ref.read(todayProvider);
    final totals = ref.read(dayTotalsProvider(today)).value;
    if (goals == null || totals == null) return;
    final prefs = ref.read(appPreferencesProvider);
    final session = ref.read(sessionControllerProvider).session;

    final plan = planReminders(
      goals: goals,
      now: ref.read(clockProvider).now(),
      todaySeconds: totals,
      session: session,
      lastCall: prefs.lastCall,
      milestones: prefs.milestones,
    );

    // A day saved since a reminder showed: take it off the shade.
    final saved = {
      for (final g in goals)
        if ((totals[g.id] ?? 0) >= safetyNetSeconds) ReminderIds.daily(g.id, 0),
    };
    if (!plan.any((n) => n.id == ReminderIds.lastCall(0)) &&
        goals.every((g) => (totals[g.id] ?? 0) >= safetyNetSeconds)) {
      saved.add(ReminderIds.lastCall(0));
    }

    try {
      final fresh = saved.difference(_withdrawn);
      if (fresh.isNotEmpty) await _scheduler.withdraw(fresh.toList());
      _withdrawn = saved;
      if (force || !listEquals(plan, _scheduled)) {
        await _scheduler.replace(plan);
        _scheduled = plan;
      }
    } on Object catch (e) {
      debugPrint('Scheduling reminders failed: $e');
    }
  }
}

final remindersControllerProvider = NotifierProvider<RemindersController, void>(
  RemindersController.new,
);

/// Whether notifications are allowed. Rechecked when the app resumes (the
/// person may have just changed it in the system settings).
class NotificationsEnabledNotifier extends Notifier<bool> {
  AppLifecycleListener? _lifecycle;

  @override
  bool build() {
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() => _lifecycle?.dispose());
    unawaited(refresh());
    return true;
  }

  Future<void> refresh() async {
    final enabled = await ref.read(notificationSchedulerProvider).enabled();
    if (ref.mounted) state = enabled;
  }

  /// Asks once in context (the person just turned a reminder on). True if
  /// notifications may now be shown.
  Future<bool> ensure() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    final granted =
        await scheduler.enabled() || await scheduler.requestPermission();
    if (ref.mounted) state = granted;
    return granted;
  }
}

/// Whether reminders may fire on the minute (Android's "Alarms &
/// reminders"). Rechecked on resume: it's granted on a system page.
class ExactRemindersNotifier extends Notifier<bool> {
  AppLifecycleListener? _lifecycle;

  @override
  bool build() {
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() => _lifecycle?.dispose());
    unawaited(refresh());
    return false;
  }

  Future<void> refresh() async {
    final allowed = await ref
        .read(notificationSchedulerProvider)
        .exactAllowed();
    if (ref.mounted) state = allowed;
  }

  /// Opens the system page; the answer arrives on resume.
  Future<void> request() =>
      ref.read(notificationSchedulerProvider).requestExact();
}

final exactRemindersProvider = NotifierProvider<ExactRemindersNotifier, bool>(
  ExactRemindersNotifier.new,
);

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
      NotificationsEnabledNotifier.new,
    );
