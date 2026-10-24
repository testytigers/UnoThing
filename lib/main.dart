import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'app/routes.dart';
import 'core/time/clock.dart';
import 'data/db/app_database.dart';
import 'data/repositories/goal_repository.dart';
import 'data/repositories/preferences_repository.dart';
import 'domain/models/active_session.dart';
import 'domain/services/timer_engine.dart';
import 'features/notifications/app_channels.dart';
import 'features/notifications/notification_scheduler.dart';
import 'features/notifications/notification_taps.dart';
import 'features/session/session_controller.dart';
import 'widgets/paint/royal_paint.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Phones stay portrait. Android 16+ ignores this on large screens
  // (tablets, unfolded foldables), where every screen also lays out in
  // landscape.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Dark status icons on the cream canvas, on screens without an AppBar too.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  await RoyalPaint.load();

  final db = AppDatabase();
  const clock = SystemClock();
  final goals = await GoalRepository(db).getGoals();
  final prefs = await PreferencesRepository(db).getAll();

  // Restore a session that survived the app being closed or killed, applying
  // any midnight that passed meanwhile.
  final ActiveSession? session = goals.isEmpty
      ? null
      : await TimerEngine(db: db, clock: clock).reconcile();

  final scheduler = LocalNotificationScheduler();
  final launch = await scheduler.launchTap();
  final shelfGoal =
      session?.goalId ??
      NotificationPayload.goalId(launch?.payload) ??
      int.tryParse(prefs[Pref.shelfGoal] ?? '');

  final start = switch ((goals.isEmpty, session)) {
    (true, _) => Routes.login,
    (_, ActiveSession(isRunning: true)) => Routes.session,
    (_, ActiveSession()) => Routes.sessionStop,
    _ => Routes.home,
  };

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      startupLocationProvider.overrideWithValue(start),
      initialSessionProvider.overrideWithValue(session),
      initialShelfGoalProvider.overrideWithValue(shelfGoal),
      notificationSchedulerProvider.overrideWithValue(scheduler),
    ],
  );
  await scheduler.init(onTap: (tap) => handleNotificationTap(container, tap));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TheOneThingApp(),
    ),
  );

  // "Start pouring" pressed while the app was closed.
  if (launch?.actionId == NotificationPayload.startAction && goals.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => handleNotificationTap(container, launch!),
    );
  }
}
