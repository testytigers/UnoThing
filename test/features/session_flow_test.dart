import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/clock.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/daily_log_repository.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/features/session/session_controller.dart';
import 'package:the_one_thing/widgets/primary_button.dart';

import '../helpers/app_harness.dart';

const today = LocalDate(2026, 12, 9);

Future<void> seed(AppDatabase db) => GoalRepository(db).createGoal(
  title: 'Learn Judo',
  horizonMonths: 3,
  dailyTargetSeconds: 1500,
  activeWeekdays: {1, 2, 3, 4, 5},
  startDate: const LocalDate(2026, 12, 1),
);

/// Moves the fake clock forward and lets the display ticker catch up.
Future<void> elapse(WidgetTester tester, FakeClock clock, Duration d) async {
  clock.advance(d);
  await tester.pump(const Duration(seconds: 1));
  await settleAsync(tester, settle: false);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<int> banked(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() async {
      final goal = (await GoalRepository(db).getGoals()).single;
      return DailyLogRepository(db).totalSecondsFor(goal.id, today);
    }))!;

void main() {
  testWidgets(
    'start, safety net once, stop, bank 00:05:06, continue from 00:05:06, '
    'discard keeps the banked total',
    (tester) async {
      final clock = FakeClock(DateTime(2026, 12, 9, 10));
      var alerts = 0;
      final db = await pumpApp(
        tester,
        start: Routes.shelf,
        clock: clock,
        seed: seed,
        overrides: [
          safetyNetAlertProvider.overrideWithValue(() async => alerts++),
        ],
      );
      await settleAsync(tester);

      // Tap today's empty cup: a session starts (Frame 8).
      await tester.tap(
        find.bySemanticsLabel('9 December, 0 minutes, today').first,
      );
      await settleAsync(tester, settle: false);
      expect(location(tester), Routes.session);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('9 Dec'), findsOneWidget);

      await elapse(tester, clock, const Duration(seconds: 299));
      expect(find.text('04:59'), findsOneWidget);
      expect(alerts, 0);

      // Crossing 5:00 fires the safety net exactly once.
      await elapse(tester, clock, const Duration(seconds: 7));
      expect(find.text('05:06'), findsOneWidget);
      expect(alerts, 1);
      await elapse(tester, clock, const Duration(seconds: 30));
      expect(alerts, 1);
      clock.advance(const Duration(seconds: -30)); // back to 00:05:06

      // Stop pauses and opens Frame 11.
      await tester.tap(find.bySemanticsLabel('Finish'));
      await settleAsync(tester);
      expect(location(tester), Routes.sessionStop);
      // Frame 11's choices are in the dock.
      expect(find.bySemanticsLabel('Continue'), findsOneWidget);
      expect(find.bySemanticsLabel('Discard'), findsOneWidget);
      expect(find.text('Save session'), findsOneWidget);
      clock.advance(const Duration(minutes: 5)); // paused: no change
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('05:06'), findsOneWidget);

      // Bank -> Shelf (Frame 10), total written.
      await tester.tap(find.text('Save session'));
      await settleAsync(tester);
      expect(location(tester), Routes.shelf);
      expect(await banked(tester, db), 306);
      expect(
        find.bySemanticsLabel('9 December, 5 minutes, saved').first,
        findsOneWidget,
      );

      // Today with banked time opens Frame 12.
      await tester.tap(
        find.bySemanticsLabel('9 December, 5 minutes, saved').first,
      );
      await settleAsync(tester);
      expect(location(tester), Routes.today);
      expect(find.text('05:06'), findsOneWidget);
      expect(find.bySemanticsLabel('Adjust time'), findsOneWidget);

      // Continue resumes from the banked total, and the safety net does not
      // fire again.
      await tester.tap(find.text('Keep pouring'));
      await settleAsync(tester, settle: false);
      expect(location(tester), Routes.session);
      expect(find.text('05:06'), findsOneWidget);
      await elapse(tester, clock, const Duration(seconds: 50));
      expect(find.text('05:56'), findsOneWidget);
      expect(alerts, 1);

      // Stop, then Discard (50 s unbanked, no confirmation needed).
      await tester.tap(find.bySemanticsLabel('Finish'));
      await settleAsync(tester);
      await tester.tap(find.bySemanticsLabel('Discard'));
      await settleAsync(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(location(tester), Routes.shelf);
      expect(await banked(tester, db), 306);

      await unmountApp(tester);
    },
  );

  testWidgets('discarding more than 60 s of unbanked time asks first', (
    tester,
  ) async {
    final clock = FakeClock(DateTime(2026, 12, 9, 10));
    await pumpApp(
      tester,
      start: Routes.shelf,
      clock: clock,
      seed: seed,
      overrides: [safetyNetAlertProvider.overrideWithValue(() async {})],
    );
    await settleAsync(tester);
    await tester.tap(
      find.bySemanticsLabel('9 December, 0 minutes, today').first,
    );
    await settleAsync(tester, settle: false);
    await elapse(tester, clock, const Duration(seconds: 61));
    await tester.tap(find.bySemanticsLabel('Finish'));
    await settleAsync(tester);

    await tester.tap(find.bySemanticsLabel('Discard'));
    await settleAsync(tester);
    expect(find.text('Let this pour go?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await settleAsync(tester);
    expect(location(tester), Routes.sessionStop);
    expect(find.text('01:01'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Edit Log on a spilled day turns it into Saved', (tester) async {
    final clock = FakeClock(DateTime(2026, 12, 9, 10));
    await pumpApp(tester, start: Routes.shelf, clock: clock, seed: seed);
    await settleAsync(tester);

    await tester.tap(find.bySemanticsLabel('8 December, 0 minutes, spilled'));
    await settleAsync(tester);
    expect(find.text('Spilled milk'), findsOneWidget);

    await tester.tap(find.text('Adjust time'));
    await settleAsync(tester);
    final fields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '12');
    await tester.enterText(fields.at(1), '30');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settleAsync(tester);

    expect(find.text('Spilled milk'), findsNothing);
    expect(
      find.text('Good job, you made it to the min required.'),
      findsOneWidget,
    );
    expect(find.text('12:30'), findsOneWidget);

    // Setting 0 on a past active day spills it again.
    await tester.tap(find.text('Adjust time'));
    await settleAsync(tester);
    await tester.enterText(fields.at(0), '0');
    await tester.enterText(fields.at(1), '0');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settleAsync(tester);
    expect(find.text('Spilled milk'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Edit Log rejects seconds over 59', (tester) async {
    final clock = FakeClock(DateTime(2026, 12, 9, 10));
    await pumpApp(tester, start: Routes.shelf, clock: clock, seed: seed);
    await settleAsync(tester);
    await tester.tap(find.bySemanticsLabel('8 December, 0 minutes, spilled'));
    await settleAsync(tester);
    await tester.tap(find.text('Adjust time'));
    await settleAsync(tester);
    final fields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(1), '75');
    await tester.pump();
    expect(find.text('Seconds must be between 0 and 59.'), findsOneWidget);
    final save = tester.widget<PrimaryButton>(
      find.ancestor(
        of: find.text('Save'),
        matching: find.byType(PrimaryButton),
      ),
    );
    expect(save.onPressed, isNull);
    await unmountApp(tester);
  });
}
