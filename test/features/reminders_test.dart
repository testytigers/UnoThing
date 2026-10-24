import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/daily_log_repository.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/data/repositories/preferences_repository.dart';
import 'package:the_one_thing/features/notifications/app_channels.dart';
import 'package:the_one_thing/features/notifications/notification_scheduler.dart';
import 'package:the_one_thing/features/notifications/notification_taps.dart';
import 'package:the_one_thing/features/notifications/reminder_planner.dart';
import 'package:the_one_thing/features/onboarding/onboarding_controller.dart';

import '../helpers/app_harness.dart';

const today = LocalDate(2026, 12, 9);
final now = DateTime(2026, 12, 9, 10);

Future<void> seed(AppDatabase db) async {
  final goal = await GoalRepository(db).createGoal(
    title: 'Learn Judo',
    horizonMonths: 3,
    dailyTargetSeconds: 1500,
    activeWeekdays: {1, 2, 3, 4, 5},
    startDate: const LocalDate(2026, 12, 1),
    reminderMinutes: 19 * 60,
  );
  await DailyLogRepository(db).setTotal(goal, today, 120, today);
}

Iterable<PlannedNotification> dueToday(NoopNotificationScheduler n) =>
    n.plan.where((p) => LocalDate.from(p.at) == today);

void main() {
  testWidgets("the plan follows the goals and today's cup", (tester) async {
    final notifications = NoopNotificationScheduler();
    final db = await pumpApp(
      tester,
      start: Routes.shelf,
      now: now,
      seed: seed,
      notifications: notifications,
      reminders: true,
    );
    await settleAsync(tester);
    expect(dueToday(notifications).map((n) => n.channel), [
      AppChannel.dailyReminders,
      AppChannel.lastCall,
    ]);

    // Saving today takes today's reminders off the plan and the shade.
    await tester.runAsync(() async {
      final goal = (await GoalRepository(db).getGoals()).single;
      await DailyLogRepository(db).setTotal(goal, today, 400, today);
    });
    await settleAsync(tester);
    expect(dueToday(notifications), isEmpty);
    expect(notifications.withdrawn, contains(ReminderIds.daily(1, 0)));
    expect(notifications.withdrawn, contains(ReminderIds.lastCall(0)));

    // Switching the last call off drops it from the rest of the week.
    await tester.runAsync(
      () => PreferencesRepository(db).setBool(Pref.lastCall, false),
    );
    await settleAsync(tester);
    expect(
      notifications.plan.where((n) => n.channel == AppChannel.lastCall),
      isEmpty,
    );
    await unmountApp(tester);
  });

  testWidgets('Settings: switching a reminder off, and notifications blocked', (
    tester,
  ) async {
    final notifications = NoopNotificationScheduler()..granted = false;
    final db = await pumpApp(
      tester,
      start: Routes.settings,
      now: now,
      seed: seed,
      notifications: notifications,
    );
    await settleAsync(tester);
    expect(
      find.text("Notifications are off, so reminders can't reach you."),
      findsOneWidget,
    );
    expect(find.text('Every pour day at 7:00 PM'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await settleAsync(tester);
    final goal = (await tester.runAsync(() => GoalRepository(db).getGoals()))!
        .single;
    expect(goal.reminderMinutes, isNull);
    expect(find.text('Off'), findsOneWidget);

    // Turning on asks; still refused, the system settings open instead.
    await tester.tap(find.text('Turn on'));
    await settleAsync(tester);
    expect(notifications.permissionRequests, 1);
    await unmountApp(tester);
  });

  testWidgets('Settings offers on-time reminders through the system page', (
    tester,
  ) async {
    final notifications = NoopNotificationScheduler();
    await pumpApp(
      tester,
      start: Routes.settings,
      now: now,
      seed: seed,
      notifications: notifications,
    );
    await settleAsync(tester);
    expect(
      find.text(
        'Allow "Alarms & reminders", or they may come up to an hour late',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('On-time reminders'));
    await settleAsync(tester);
    expect(notifications.exactRequests, 1);
    await unmountApp(tester);
  });

  testWidgets('the contract offers a 7 PM reminder and asks in context', (
    tester,
  ) async {
    final notifications = NoopNotificationScheduler()..granted = false;
    final db = await pumpApp(
      tester,
      start: Routes.contract,
      now: now,
      notifications: notifications,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(onboardingControllerProvider.notifier)
      ..setTitle('Learn Judo')
      ..setHorizon(3)
      ..setCommitted(true);
    await tester.pumpAndSettle();
    expect(find.text('Every pour day at 7:00 PM'), findsOneWidget);

    await tester.tap(find.text('Seal the pact'));
    await settleAsync(tester);
    final goal = (await tester.runAsync(() => GoalRepository(db).getGoals()))!
        .single;
    expect(goal.reminderMinutes, 19 * 60);
    expect(notifications.permissionRequests, 1);
    await unmountApp(tester);
  });

  testWidgets('"Start pouring" on a reminder starts that goal', (tester) async {
    await pumpApp(tester, start: Routes.shelf, now: now, seed: seed);
    await settleAsync(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    await tester.runAsync(
      () => handleNotificationTap(
        container,
        NotificationTap(
          payload: NotificationPayload.goal(1),
          actionId: NotificationPayload.startAction,
        ),
      ),
    );
    await settleAsync(tester, settle: false);
    expect(location(tester), Routes.session);
    // Banked 2:00 earlier today: it resumes from there.
    expect(find.text('02:00'), findsOneWidget);
    await unmountApp(tester);
  });
}
