import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_one_thing/app/app.dart';
import 'package:the_one_thing/app/router.dart';
import 'package:the_one_thing/core/time/clock.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/features/notifications/notification_scheduler.dart';
import 'package:the_one_thing/features/notifications/reminders_controller.dart';
import 'package:the_one_thing/features/session/background/pour_service.dart';
import 'package:the_one_thing/widgets/primary_button.dart';

/// Pumps the whole app on an in-memory database with a fixed clock.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  required String start,
  DateTime? now,
  FakeClock? clock,
  Future<void> Function(AppDatabase db)? seed,
  List<Override> overrides = const [],
  PourService? pour,
  NotificationScheduler? notifications,
  bool reminders = false,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // A real phone screen (Pixel-class, 412 x 915 dp) instead of 800 x 600.
  tester.view.physicalSize = const Size(1236, 2745);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        startupLocationProvider.overrideWithValue(start),
        clockProvider.overrideWithValue(
          clock ?? FakeClock(now ?? DateTime(2026, 12, 6, 9)),
        ),
        pourServiceProvider.overrideWithValue(pour ?? NoopPourService()),
        notificationSchedulerProvider.overrideWithValue(
          notifications ?? NoopNotificationScheduler(),
        ),
        // The reminders follow database streams from the app root; tests
        // that want them pass `reminders: true` and end with [unmountApp].
        if (!reminders)
          remindersControllerProvider.overrideWith(_NoReminders.new),
        ...overrides,
      ],
      child: const TheOneThingApp(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(db.close);
  return db;
}

/// Whether the primary button labelled [label] is enabled.
bool primaryEnabled(WidgetTester tester, [String label = 'Next']) {
  final button = tester.widget<PrimaryButton>(
    find.ancestor(of: find.text(label), matching: find.byType(PrimaryButton)),
  );
  return button.onPressed != null;
}

Future<void> tapPrimary(WidgetTester tester, [String label = 'Next']) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

String location(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).state.matchedLocation;
}

/// Lets real async work (database, hashing) finish, then settles frames.
Future<void> settleAsync(WidgetTester tester, {bool settle = true}) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (settle) await tester.pumpAndSettle();
}

/// Unmounts the app and flushes drift's stream-close timer. Call at the end
/// of tests that reach screens watching database streams.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

class _NoReminders extends RemindersController {
  @override
  void build() {}
}
