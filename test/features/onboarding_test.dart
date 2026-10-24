import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/features/onboarding/onboarding_controller.dart';
import 'package:the_one_thing/widgets/wheel_picker.dart';

import '../helpers/app_harness.dart';

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

OnboardingDraft _draft(WidgetTester tester) =>
    _container(tester).read(onboardingControllerProvider);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Walks the steps up to [route], filling each one on the way.
Future<void> _openStep(WidgetTester tester, String route) async {
  await pumpApp(tester, start: Routes.goal);
  await tester.enterText(find.byType(TextField), 'Learn Judo');
  await tester.pump();
  await tapPrimary(tester);
  expect(location(tester), Routes.horizonStep);
  if (route == Routes.horizonStep) return;
  await _tapVisible(tester, find.text('3 Months'));
  await tapPrimary(tester);
  expect(location(tester), Routes.targetStep);
  if (route == Routes.targetStep) return;
  await tapPrimary(tester);
  expect(location(tester), Routes.daysStep);
}

void main() {
  group('step 1, the goal', () {
    testWidgets('Next is disabled while empty or only spaces', (tester) async {
      await pumpApp(tester, start: Routes.goal);
      expect(find.text("What's your\none thing?"), findsOneWidget);
      expect(find.text('e.g. Learn Judo'), findsOneWidget);
      expect(find.text('1/5'), findsOneWidget);
      expect(primaryEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), '    ');
      await tester.pump();
      expect(primaryEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), 'Learn Judo');
      await tester.pump();
      expect(primaryEnabled(tester), isTrue);
    });

    testWidgets('title is capped at 60 characters', (tester) async {
      await pumpApp(tester, start: Routes.goal);
      await tester.enterText(find.byType(TextField), 'x' * 75);
      await tester.pump();
      expect(_draft(tester).title, hasLength(60));
    });
  });

  group('step 2, the horizon', () {
    testWidgets('Next is disabled until a horizon is chosen', (tester) async {
      await _openStep(tester, Routes.horizonStep);
      expect(find.text('2/5'), findsOneWidget);
      for (final label in [
        '1 Month',
        '3 Months',
        '6 Months',
        '9 Months',
        '1 Year',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      // Each choice shows its finish line (today: 6 Dec 2026).
      expect(find.text('Until 5 Mar 2027'), findsOneWidget);
      expect(primaryEnabled(tester), isFalse);

      await _tapVisible(tester, find.text('3 Months'));
      expect(_draft(tester).horizonMonths, 3);
      expect(find.text('A habit. Long enough to stick.'), findsOneWidget);
      expect(primaryEnabled(tester), isTrue);
    });
  });

  group('step 3, the daily amount', () {
    testWidgets('defaults to 25 min and all seven days', (tester) async {
      await _openStep(tester, Routes.targetStep);
      expect(find.text('3/5'), findsOneWidget);
      expect(_draft(tester).dailyTargetSeconds, 25 * 60);
      expect(_draft(tester).activeWeekdays, {1, 2, 3, 4, 5, 6, 7});
      expect(primaryEnabled(tester), isTrue);
    });

    testWidgets('picking an amount tells you what it adds up to', (
      tester,
    ) async {
      await _openStep(tester, Routes.targetStep);
      await _tapVisible(tester, find.text('45'));
      expect(_draft(tester).dailyTargetSeconds, 45 * 60);
      // 6 Dec 2026 to 5 Mar 2027, every day: 90 days x 45 min.
      expect(
        find.text("Solid! That's about 68 hours of Learn Judo by 5 Mar."),
        findsOneWidget,
      );
    });

    testWidgets('a custom amount under 5 minutes is blocked', (tester) async {
      await _openStep(tester, Routes.targetStep);
      await _tapVisible(tester, find.bySemanticsLabel('Custom amount'));
      // Drag the minutes wheel down 21 items: 25 -> 4.
      await tester.drag(
        find.descendant(
          of: find.byKey(const ValueKey('minutes')),
          matching: find.byType(ListWheelScrollView),
        ),
        const Offset(0, WheelPicker.itemExtent * 21),
      );
      await tester.pumpAndSettle();
      expect(_draft(tester).targetMinutes, 4);
      expect(find.text('At least 5 min a day.'), findsOneWidget);
      expect(primaryEnabled(tester, 'Done'), isFalse);
    });

    testWidgets('above 12 hours is blocked; exactly 12 hours is fine', (
      tester,
    ) async {
      await _openStep(tester, Routes.targetStep);
      final c = _container(tester).read(onboardingControllerProvider.notifier);
      c.setTargetHours(12);
      await tester.pumpAndSettle();
      expect(_draft(tester).targetValid, isFalse);
      c.setTargetMinutes(0);
      await tester.pumpAndSettle();
      expect(_draft(tester).targetValid, isTrue);
    });
  });

  group('step 4, the days', () {
    testWidgets('presets, and no days selected disables Next', (tester) async {
      await _openStep(tester, Routes.daysStep);
      expect(find.text('4/5'), findsOneWidget);

      await _tapVisible(tester, find.text('Weekdays'));
      expect(_draft(tester).activeWeekdays, {1, 2, 3, 4, 5});
      expect(find.textContaining('Weekdays on, weekends off.'), findsOneWidget);

      await _tapVisible(tester, find.text('Every day'));
      for (final day in [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ]) {
        await _tapVisible(tester, find.bySemanticsLabel(day));
      }
      expect(_draft(tester).activeWeekdays, isEmpty);
      expect(find.text('Pick at least one day.'), findsOneWidget);
      expect(primaryEnabled(tester), isFalse);

      await _tapVisible(tester, find.bySemanticsLabel('Sunday'));
      expect(_draft(tester).activeWeekdays, {7});
      expect(primaryEnabled(tester), isTrue);
    });
  });

  group('step 5, the contract', () {
    testWidgets('Seal is enabled only when checked', (tester) async {
      await pumpApp(tester, start: Routes.contract);
      expect(find.text('I commit...'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      expect(primaryEnabled(tester, 'Seal the pact'), isFalse);
      await tester.tap(
        find.text("I commit that I'll do my best to achieve my Goal!"),
      );
      await tester.pumpAndSettle();
      expect(primaryEnabled(tester, 'Seal the pact'), isTrue);
    });
  });

  testWidgets('full flow saves the goal at the end, lands on the Shelf, and '
      'clears onboarding from the back stack', (tester) async {
    final db = await pumpApp(
      tester,
      start: Routes.login,
      now: DateTime(2026, 12, 6, 21, 30),
    );

    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'me@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secret12');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await settleAsync(tester);
    expect(location(tester), Routes.goal);

    await tester.enterText(find.byType(TextField), '  Learn Judo  ');
    await tester.pump();
    await tapPrimary(tester);
    await _tapVisible(tester, find.text('3 Months'));
    await tapPrimary(tester);
    await tapPrimary(tester);
    await _tapVisible(tester, find.text('Weekdays'));
    await tapPrimary(tester);

    // Nothing is written before the contract is signed.
    expect(await tester.runAsync(() => GoalRepository(db).getGoals()), isEmpty);

    await tester.tap(
      find.text("I commit that I'll do my best to achieve my Goal!"),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seal the pact'));
    await settleAsync(tester);

    expect(location(tester), Routes.home);
    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    expect(router.canPop(), isFalse);

    final goal = (await tester.runAsync(() => GoalRepository(db).getGoals()))!
        .single;
    expect(goal.title, 'Learn Judo');
    expect(goal.horizonMonths, 3);
    expect(goal.dailyTargetSeconds, 1500);
    expect(goal.activeWeekdays, {1, 2, 3, 4, 5});
    expect(goal.startDate, const LocalDate(2026, 12, 6));
    await unmountApp(tester);
  });
}
