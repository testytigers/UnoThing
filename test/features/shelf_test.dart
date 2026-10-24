import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/clock.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/active_session_repository.dart';
import 'package:the_one_thing/data/repositories/daily_log_repository.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/data/repositories/preferences_repository.dart';
import 'package:the_one_thing/domain/models/daily_log.dart';
import 'package:the_one_thing/domain/models/active_session.dart';
import 'package:the_one_thing/domain/models/day_status.dart';
import 'package:the_one_thing/domain/models/goal.dart';
import 'package:the_one_thing/features/session/session_controller.dart';
import 'package:the_one_thing/features/shelf/shelf_controller.dart';
import 'package:the_one_thing/widgets/cup/day_cup.dart';

import '../helpers/app_harness.dart';

// Goal: Tue 2026-12-01 + 3 months, Mon-Fri, 25 min. Today: Wed 2026-12-09.
const today = LocalDate(2026, 12, 9);
final now = DateTime(2026, 12, 9, 10);

Future<void> seed(AppDatabase db) async {
  final goal = await GoalRepository(db).createGoal(
    title: 'Learn Judo',
    horizonMonths: 3,
    dailyTargetSeconds: 1500,
    activeWeekdays: {1, 2, 3, 4, 5},
    startDate: const LocalDate(2026, 12, 1),
  );
  final logs = DailyLogRepository(db);
  await logs.setTotal(goal, const LocalDate(2026, 12, 7), 306, today);
  await logs.setTotal(goal, const LocalDate(2026, 12, 8), 0, today);
}

/// [seed], plus a second goal (Pro) with today already saved.
Future<void> seedTwo(AppDatabase db) async {
  await seed(db);
  final read = await GoalRepository(db).createGoal(
    title: 'Read',
    horizonMonths: 1,
    dailyTargetSeconds: 600,
    activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
    startDate: const LocalDate(2026, 12, 1),
  );
  await DailyLogRepository(db).setTotal(read, today, 420, today);
  await PreferencesRepository(db).setBool(Pref.proPreview, true);
}

DayCup cup(LocalDate date, DayStatus status, [int total = 0]) => DayCup(
  date: date,
  status: status,
  totalSeconds: total,
  dailyTargetSeconds: 1500,
);

void main() {
  group('tap rules', () {
    final idle = SessionState(null, now);
    const yesterday = LocalDate(2026, 12, 8);

    test('today, pending with 0 seconds starts a session', () {
      expect(
        shelfTapFor(cup(today, DayStatus.pending), today, idle, goalId: 1),
        ShelfTap.startSession,
      );
    });

    test('today with banked time opens Frame 12', () {
      expect(
        shelfTapFor(cup(today, DayStatus.pending, 120), today, idle, goalId: 1),
        ShelfTap.bankedToday,
      );
      expect(
        shelfTapFor(cup(today, DayStatus.saved, 400), today, idle, goalId: 1),
        ShelfTap.bankedToday,
      );
      expect(
        shelfTapFor(
          cup(today, DayStatus.targetReached, 1600),
          today,
          idle,
          goalId: 1,
        ),
        ShelfTap.bankedToday,
      );
    });

    test('today with an active session reopens it', () {
      final active = SessionState(
        ActiveSession(
          goalId: 1,
          date: today,
          baseSeconds: 0,
          segmentStartedAt: now,
          accumulatedSeconds: 0,
          safetyNetFired: false,
        ),
        now,
      );
      expect(
        shelfTapFor(cup(today, DayStatus.pending, 5), today, active, goalId: 1),
        ShelfTap.openSession,
      );
    });

    test("while another goal pours, today's cup only shows its bank", () {
      final elsewhere = SessionState(
        ActiveSession(
          goalId: 2,
          date: today,
          baseSeconds: 0,
          segmentStartedAt: now,
          accumulatedSeconds: 0,
          safetyNetFired: false,
        ),
        now,
      );
      expect(
        shelfTapFor(cup(today, DayStatus.pending), today, elsewhere, goalId: 1),
        ShelfTap.none,
      );
      expect(
        shelfTapFor(
          cup(today, DayStatus.saved, 400),
          today,
          elsewhere,
          goalId: 1,
        ),
        ShelfTap.bankedToday,
      );
    });

    test('past saved, target reached and spilled open the day', () {
      for (final s in [
        DayStatus.saved,
        DayStatus.targetReached,
        DayStatus.spilled,
      ]) {
        expect(
          shelfTapFor(cup(yesterday, s, 400), today, idle, goalId: 1),
          ShelfTap.pastDay,
        );
      }
    });

    test('future, rest and outside-horizon days do nothing', () {
      for (final s in [
        DayStatus.future,
        DayStatus.rest,
        DayStatus.outsideHorizon,
      ]) {
        expect(
          shelfTapFor(cup(yesterday, s), today, idle, goalId: 1),
          ShelfTap.none,
        );
      }
    });
  });

  group('default week', () {
    final goal = Goal(
      id: 1,
      title: 'x',
      horizonMonths: 1,
      dailyTargetSeconds: 1500,
      activeWeekdays: const {1, 2, 3, 4, 5},
      startDate: const LocalDate(2026, 12, 1), // ends 2026-12-31 (Thu)
    );

    test("is today's week inside the horizon", () {
      expect(defaultWeek(goal, today), const LocalDate(2026, 12, 7));
    });

    test('is the final week after the horizon ends (D6)', () {
      expect(
        defaultWeek(goal, const LocalDate(2027, 2, 10)),
        const LocalDate(2026, 12, 28),
      );
    });

    test('bounds cover only weeks overlapping the horizon', () {
      expect(weekBounds(goal), (
        const LocalDate(2026, 11, 30),
        const LocalDate(2026, 12, 28),
      ));
    });
  });

  group('a completed week', () {
    final goal = Goal(
      id: 1,
      title: 'x',
      horizonMonths: 3,
      dailyTargetSeconds: 1500,
      activeWeekdays: const {1, 3, 5},
      startDate: const LocalDate(2026, 12, 1),
    );
    DailyLog saved(LocalDate d) =>
        DailyLog(date: d, totalSeconds: 400, status: DayStatus.saved);
    // Mon 7, Wed 9, Fri 11 December.
    const mon = LocalDate(2026, 12, 7);
    const wed = LocalDate(2026, 12, 9);
    const fri = LocalDate(2026, 12, 11);

    test('is the last pour day of the week, with every pour day saved', () {
      final logs = {
        for (final d in [mon, wed, fri]) d: saved(d),
      };
      expect(completesWeek(goal, fri, logs), isTrue);
    });

    test('not before the last pour day', () {
      final logs = {
        for (final d in [mon, wed]) d: saved(d),
      };
      expect(completesWeek(goal, wed, logs), isFalse);
    });

    test('not with a spilled pour day earlier in the week', () {
      final logs = {
        mon: const DailyLog(
          date: mon,
          totalSeconds: 0,
          status: DayStatus.spilled,
        ),
        wed: saved(wed),
        fri: saved(fri),
      };
      expect(completesWeek(goal, fri, logs), isFalse);
    });

    test('counts only pour days inside the horizon (first week)', () {
      // Starts Tue 1 Dec: Mon 30 Nov is outside, so Wed 2 and Fri 4 count.
      const wed2 = LocalDate(2026, 12, 2);
      const fri4 = LocalDate(2026, 12, 4);
      final logs = {
        for (final d in [wed2, fri4]) d: saved(d),
      };
      expect(completesWeek(goal, fri4, logs), isTrue);
    });
  });

  testWidgets('shows the current week, today highlighted, and real cups', (
    tester,
  ) async {
    await pumpApp(tester, start: Routes.shelf, now: now, seed: seed);
    await settleAsync(tester);

    expect(find.text('7-13 Dec'), findsOneWidget);
    for (final d in ['7', '8', '9', '10', '11', '12', '13']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(find.textContaining('Day 9 of 90'), findsOneWidget);
    expect(
      find.bySemanticsLabel('7 December, 5 minutes, saved'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('8 December, 0 minutes, spilled'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('9 December, 0 minutes, today').first,
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('10 December, 0 minutes, upcoming'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('12 December, 0 minutes, rest day'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('week arrows stop at the weeks that overlap the horizon', (
    tester,
  ) async {
    await pumpApp(tester, start: Routes.shelf, now: now, seed: seed);
    await settleAsync(tester);

    await tester.tap(find.bySemanticsLabel('Previous week'));
    await settleAsync(tester);
    expect(find.text('30 Nov - 6 Dec'), findsOneWidget);
    // 30 Nov is before the start: outside the horizon, never spilled (D7).
    expect(
      find.bySemanticsLabel('30 November, 0 minutes, outside the horizon'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('2 December, 0 minutes, spilled'),
      findsOneWidget,
    );

    // Already at the first week: Previous does nothing.
    await tester.tap(find.bySemanticsLabel('Previous week'));
    await settleAsync(tester);
    expect(find.text('30 Nov - 6 Dec'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Next week'));
    await settleAsync(tester);
    await tester.tap(find.bySemanticsLabel('Next week'));
    await settleAsync(tester);
    expect(find.text('14-20 Dec'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('tapping a spilled day opens Frame 14, a saved day Frame 13', (
    tester,
  ) async {
    await pumpApp(tester, start: Routes.shelf, now: now, seed: seed);
    await settleAsync(tester);

    await tester.tap(find.bySemanticsLabel('8 December, 0 minutes, spilled'));
    await settleAsync(tester);
    expect(find.text('Spilled milk'), findsOneWidget);
    expect(
      find.text(
        "You missed this day. No use crying over it: let's not miss another.",
      ),
      findsOneWidget,
    );
    expect(find.text('00:00'), findsOneWidget);
    expect(location(tester), Routes.day('2026-12-08'));

    await tester.pageBack();
    await settleAsync(tester);
    await tester.tap(find.bySemanticsLabel('7 December, 5 minutes, saved'));
    await settleAsync(tester);
    expect(
      find.text('Good job, you made it to the min required.'),
      findsOneWidget,
    );
    expect(find.text('05:06'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('future and rest days do nothing', (tester) async {
    await pumpApp(tester, start: Routes.shelf, now: now, seed: seed);
    await settleAsync(tester);
    await tester.tap(find.bySemanticsLabel('10 December, 0 minutes, upcoming'));
    await tester.tap(find.bySemanticsLabel('12 December, 0 minutes, rest day'));
    await settleAsync(tester);
    expect(location(tester), Routes.shelf);
    await unmountApp(tester);
  });

  testWidgets('logo opens the Horizon with X/Y days (D4)', (tester) async {
    await pumpApp(tester, start: Routes.shelf, now: now, seed: seed);
    await settleAsync(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('Open the Horizon')));
    await settleAsync(tester);
    expect(find.text('Horizon'), findsOneWidget);
    // 1 saved day out of Dec 1 .. Feb 28 = 90 days.
    expect(find.text('1/90 days'), findsOneWidget);
    await unmountApp(tester);
  });

  group('Home and the dock', () {
    testWidgets('Home lists each goal with today and the pact', (tester) async {
      await pumpApp(tester, start: Routes.home, now: now, seed: seedTwo);
      await settleAsync(tester);
      expect(find.text('Your habits'), findsOneWidget);
      expect(find.text('1 of 2 saved today. Keep going!'), findsOneWidget);
      expect(find.text('Learn Judo'), findsOneWidget);
      expect(find.text('0 / 25 min today'), findsOneWidget);
      expect(find.text('Day 9 of 90'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('7 / 10 min today · Saved'), findsOneWidget);
      expect(find.text('Day 9 of 31'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('a card opens its Shelf; Back returns Home', (tester) async {
      await pumpApp(tester, start: Routes.home, now: now, seed: seedTwo);
      await settleAsync(tester);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Read\.')));
      await settleAsync(tester);
      expect(location(tester), Routes.shelf);
      expect(find.text('Read'), findsOneWidget);
      // Read's own week: seven pour days, today saved.
      expect(
        find.bySemanticsLabel('9 December, 7 minutes, saved').first,
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Home'));
      await settleAsync(tester);
      expect(location(tester), Routes.home);
      await unmountApp(tester);
    });

    testWidgets("a free member's New habit shows what Pro adds", (
      tester,
    ) async {
      await pumpApp(tester, start: Routes.home, now: now, seed: seed);
      await settleAsync(tester);
      expect(find.text('Your one thing'), findsOneWidget);
      await tester.tap(find.text('New habit'));
      await settleAsync(tester);
      expect(find.text('The One Thing Pro'), findsOneWidget);
      await tester.tap(find.text('Try Pro (test build)'));
      await settleAsync(tester);
      // Unlocked: straight on to the next goal's first step.
      expect(location(tester), Routes.goal);
      expect(find.text("What's your\nnext thing?"), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the dock pours in place and turns into the live timer', (
      tester,
    ) async {
      final clock = FakeClock(now);
      await pumpApp(tester, start: Routes.shelf, clock: clock, seed: seed);
      await settleAsync(tester);
      expect(find.bySemanticsLabel('Horizon'), findsOneWidget);
      expect(find.bySemanticsLabel('Reminder'), findsOneWidget);

      await tester.tap(find.text('Start pouring'));
      await settleAsync(tester, settle: false);
      expect(location(tester), Routes.shelf);
      clock.advance(const Duration(seconds: 42));
      await tester.pump(const Duration(seconds: 1));
      await settleAsync(tester, settle: false);
      expect(
        find.bySemanticsLabel('Learn Judo, 00:42. Open the session'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Horizon'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Pause'));
      await settleAsync(tester);
      expect(find.bySemanticsLabel('Resume'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Finish'));
      await settleAsync(tester);
      expect(location(tester), Routes.sessionStop);
      expect(find.text('Save session'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('while one goal pours, the others point back to it', (
      tester,
    ) async {
      const paused = ActiveSession(
        goalId: 1,
        date: today,
        baseSeconds: 0,
        segmentStartedAt: null,
        accumulatedSeconds: 90,
        safetyNetFired: false,
      );
      await pumpApp(
        tester,
        start: Routes.shelf,
        now: now,
        seed: (db) async {
          await seedTwo(db);
          await ActiveSessionRepository(db).save(paused);
        },
        overrides: [
          initialSessionProvider.overrideWithValue(paused),
          initialShelfGoalProvider.overrideWithValue(2),
        ],
      );
      await settleAsync(tester);
      expect(find.text('Read'), findsOneWidget);
      expect(
        find.text("You're pouring into Learn Judo right now."),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(RegExp('Open the session')));
      await settleAsync(tester);
      expect(location(tester), Routes.sessionStop);
      await unmountApp(tester);
    });
  });
}
