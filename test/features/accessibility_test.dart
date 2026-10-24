import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/daily_log_repository.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';

import '../helpers/app_harness.dart';

// Google Play's accessibility basics (Android's Accessibility Scanner):
// 48 dp touch targets, labelled controls, readable contrast; and screens
// that hold up at 200% text and on large screens in landscape (Android 16
// ignores the portrait lock there).

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
  await DailyLogRepository(db).setTotal(goal, today, 400, today);
}

const screens = {
  'Login': Routes.login,
  'Goal step': Routes.goal,
  'Horizon step': Routes.horizonStep,
  'Target step': Routes.targetStep,
  'Days step': Routes.daysStep,
  'Contract': Routes.contract,
  'Home': Routes.home,
  'Shelf': Routes.shelf,
  'Banked today': Routes.today,
  'Horizon': Routes.horizon,
  'Settings': Routes.settings,
};

Future<void> open(WidgetTester tester, String route) async {
  await pumpApp(tester, start: route, now: now, seed: seed);
  await settleAsync(tester);
}

void main() {
  for (final MapEntry(key: name, value: route) in screens.entries) {
    testWidgets('$name meets the tap target, label and contrast guidelines', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester, route);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
      await unmountApp(tester);
    });

    testWidgets('$name lays out at 200% text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, route);
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });

    testWidgets('$name lays out on a tablet in landscape', (tester) async {
      await open(tester, route);
      tester.view.physicalSize = const Size(2560, 1600);
      tester.view.devicePixelRatio = 2;
      await settleAsync(tester);
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });
  }
}
