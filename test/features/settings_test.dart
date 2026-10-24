import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/data/repositories/preferences_repository.dart';

import '../helpers/app_harness.dart';

final now = DateTime(2026, 12, 9, 10);

Future<void> seedTwo(AppDatabase db) async {
  for (final title in ['Learn Judo', 'Read']) {
    await GoalRepository(db).createGoal(
      title: title,
      horizonMonths: 3,
      dailyTargetSeconds: 1500,
      activeWeekdays: {1, 2, 3, 4, 5},
      startDate: const LocalDate(2026, 12, 1),
    );
  }
}

void main() {
  testWidgets('deleting one goal keeps the others', (tester) async {
    final db = await pumpApp(
      tester,
      start: Routes.settings,
      now: now,
      seed: seedTwo,
    );
    await settleAsync(tester);
    await tester.scrollUntilVisible(find.text('Reset everything'), 200);
    expect(find.text('Reset everything'), findsOneWidget);

    await tester.ensureVisible(find.text('Delete Read'));
    await tester.tap(find.text('Delete Read'));
    await settleAsync(tester);
    expect(find.text('Delete Read?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settleAsync(tester);

    final goals = (await tester.runAsync(() => GoalRepository(db).getGoals()))!;
    expect(goals.map((g) => g.title), ['Learn Judo']);
    expect(location(tester), Routes.settings);
    // One goal left: the reset speaks of one goal again.
    await tester.scrollUntilVisible(find.text('Reset goal'), 200);
    expect(find.text('Reset goal'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the Pro preview switch unlocks Pro for testing', (tester) async {
    final db = await pumpApp(
      tester,
      start: Routes.settings,
      now: now,
      seed: seedTwo,
    );
    await settleAsync(tester);
    await tester.scrollUntilVisible(find.text('Pro preview').last, 200);
    await tester.tap(find.text('Pro preview').last);
    await settleAsync(tester);
    final prefs = (await tester.runAsync(
      () => PreferencesRepository(db).getAll(),
    ))!;
    expect(AppPreferences.from(prefs).proPreview, isTrue);
    await unmountApp(tester);
  });
}
