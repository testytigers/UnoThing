import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/core/time/clock.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/daily_log_repository.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/domain/models/day_status.dart';
import 'package:the_one_thing/domain/models/goal.dart';
import 'package:the_one_thing/domain/services/timer_engine.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late FakeClock clock;
  late TimerEngine engine;
  late DailyLogRepository logs;
  late Goal goal;

  const day1 = LocalDate(2026, 12, 6);
  const day2 = LocalDate(2026, 12, 7);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime(2026, 12, 6, 9));
    engine = TimerEngine(db: db, clock: clock);
    logs = DailyLogRepository(db);
    goal = await GoalRepository(db).createGoal(
      title: 'Learn Judo',
      horizonMonths: 1,
      dailyTargetSeconds: 1500,
      activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
      startDate: const LocalDate(2026, 12, 1),
    );
  });

  tearDown(() => db.close());

  test('counts from timestamps, not ticks', () async {
    final s = await engine.start(goal, day1);
    clock.advance(const Duration(minutes: 1, seconds: 30));
    expect(s.valueAt(clock.now()), 90);
  });

  test('resuming a day starts from its banked total (00:05:06)', () async {
    await logs.setTotal(goal, day1, 306, day1);
    final s = await engine.start(goal, day1);
    expect(s.valueAt(clock.now()), 306);
    clock.advance(const Duration(seconds: 4));
    expect(s.valueAt(clock.now()), 310);
  });

  test('pause freezes the value, resume continues it', () async {
    var s = await engine.start(goal, day1);
    clock.advance(const Duration(seconds: 50));
    s = await engine.pause(s);
    expect(s.isRunning, isFalse);
    clock.advance(const Duration(minutes: 10));
    expect(s.valueAt(clock.now()), 50);
    s = await engine.resume(s);
    clock.advance(const Duration(seconds: 25));
    expect(s.valueAt(clock.now()), 75);
  });

  test('bank writes the current value as the day total and ends', () async {
    final s = await engine.start(goal, day1);
    clock.advance(const Duration(minutes: 26));
    expect(await engine.bank(s, goal), 1560);
    final log = (await logs.getLog(goal.id, day1))!;
    expect(log.totalSeconds, 1560);
    expect(log.status, DayStatus.targetReached);
    expect(await engine.current(), isNull);
  });

  test('discard after resuming keeps the earlier banked total', () async {
    await logs.setTotal(goal, day1, 306, day1);
    await engine.start(goal, day1);
    clock.advance(const Duration(minutes: 3));
    await engine.discard();
    expect(await logs.totalSecondsFor(goal.id, day1), 306);
    expect(await engine.current(), isNull);
  });

  test('only one session at a time', () async {
    await engine.start(goal, day1);
    expect(() => engine.start(goal, day1), throwsStateError);
  });

  group('safety net', () {
    test('not yet fired for a fresh day', () async {
      expect((await engine.start(goal, day1)).safetyNetFired, isFalse);
    });

    test('pre-marked when resuming at or above 300 s', () async {
      await logs.setTotal(goal, day1, 300, day1);
      expect((await engine.start(goal, day1)).safetyNetFired, isTrue);
    });

    test('marking persists', () async {
      final s = await engine.start(goal, day1);
      await engine.markSafetyNetFired(s);
      expect((await engine.current())!.safetyNetFired, isTrue);
    });
  });

  group('cup full', () {
    test('not yet fired below the target', () async {
      await logs.setTotal(goal, day1, 1499, day1);
      expect((await engine.start(goal, day1)).targetFired, isFalse);
    });

    test('pre-marked when resuming at the target', () async {
      await logs.setTotal(goal, day1, 1500, day1);
      expect((await engine.start(goal, day1)).targetFired, isTrue);
    });

    test('marking persists', () async {
      final s = await engine.start(goal, day1);
      await engine.markTargetFired(s);
      expect((await engine.current())!.targetFired, isTrue);
    });
  });

  group('several goals', () {
    late Goal read;

    setUp(() async {
      read = await GoalRepository(db).createGoal(
        title: 'Read',
        horizonMonths: 1,
        dailyTargetSeconds: 600,
        activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
        startDate: const LocalDate(2026, 12, 1),
      );
    });

    test('a session banks only into its own goal', () async {
      await logs.setTotal(read, day1, 120, day1);
      final s = await engine.start(goal, day1);
      expect(s.goalId, goal.id);
      clock.advance(const Duration(minutes: 6));
      await engine.bank(s, goal);
      expect(await logs.totalSecondsFor(goal.id, day1), 360);
      expect(await logs.totalSecondsFor(read.id, day1), 120);
    });

    test('resumes from its own goal\'s total', () async {
      await logs.setTotal(read, day1, 700, day1);
      final s = await engine.start(goal, day1);
      expect(s.baseSeconds, 0);
      expect(s.targetFired, isFalse);
    });

    test('midnight rolls the session over on its own goal', () async {
      clock.set(DateTime(2026, 12, 6, 23, 50));
      await engine.start(read, day1);
      clock.set(DateTime(2026, 12, 7, 0, 10));
      final s = (await engine.reconcile())!;
      expect(s.goalId, read.id);
      expect(await logs.totalSecondsFor(read.id, day1), 600);
      expect(await logs.totalSecondsFor(goal.id, day1), 0);
      // A fresh day: the cup-full alert is armed again.
      expect(s.targetFired, isFalse);
    });

    test('a session whose goal was deleted is dropped', () async {
      await engine.start(read, day1);
      await GoalRepository(db).deleteGoal(read.id);
      expect(await engine.reconcile(), isNull);
      expect(await engine.current(), isNull);
    });
  });

  test('survives the process dying: a new engine restores the value', () async {
    await logs.setTotal(goal, day1, 120, day1);
    await engine.start(goal, day1);
    clock.advance(const Duration(minutes: 2));
    final restarted = TimerEngine(db: db, clock: clock);
    final restored = (await restarted.reconcile())!;
    expect(restored.isRunning, isTrue);
    expect(restored.valueAt(clock.now()), 240);
  });

  group('midnight rollover', () {
    test(
      'banks up to 23:59:59 to the old date and continues on the new',
      () async {
        clock.set(DateTime(2026, 12, 6, 23, 50));
        await engine.start(goal, day1);
        clock.set(DateTime(2026, 12, 7, 0, 10));

        final s = (await engine.reconcile())!;
        expect(await logs.totalSecondsFor(goal.id, day1), 600);
        expect(s.date, day2);
        expect(s.baseSeconds, 0);
        expect(s.isRunning, isTrue);
        expect(s.valueAt(clock.now()), 600);
      },
    );

    test('adds to time already banked on the old date', () async {
      await logs.setTotal(goal, day1, 100, day1);
      clock.set(DateTime(2026, 12, 6, 23, 55));
      await engine.start(goal, day1);
      clock.set(DateTime(2026, 12, 7, 0, 1));
      await engine.reconcile();
      expect(await logs.totalSecondsFor(goal.id, day1), 100 + 300);
    });

    test('carries accumulated time from before a pause', () async {
      clock.set(DateTime(2026, 12, 6, 23, 0));
      var s = await engine.start(goal, day1);
      clock.set(DateTime(2026, 12, 6, 23, 10));
      s = await engine.pause(s);
      clock.set(DateTime(2026, 12, 6, 23, 50));
      await engine.resume(s);
      clock.set(DateTime(2026, 12, 7, 0, 5));
      final next = (await engine.reconcile())!;
      expect(await logs.totalSecondsFor(goal.id, day1), 600 + 600);
      expect(next.valueAt(clock.now()), 300);
    });

    test('new day session re-arms the safety net', () async {
      clock.set(DateTime(2026, 12, 6, 23, 0));
      await engine.start(goal, day1);
      clock.set(DateTime(2026, 12, 7, 0, 1));
      final next = (await engine.reconcile())!;
      expect(next.safetyNetFired, isFalse);
    });

    test('several midnights are each banked', () async {
      clock.set(DateTime(2026, 12, 6, 23, 59));
      await engine.start(goal, day1);
      clock.set(DateTime(2026, 12, 8, 0, 2));
      final s = (await engine.reconcile())!;
      expect(await logs.totalSecondsFor(goal.id, day1), 60);
      expect(await logs.totalSecondsFor(goal.id, day2), 86400);
      expect(s.date, const LocalDate(2026, 12, 8));
      expect(s.valueAt(clock.now()), 120);
    });

    test(
      'a paused session from a past day is banked to that day (D8)',
      () async {
        var s = await engine.start(goal, day1);
        clock.advance(const Duration(minutes: 7));
        s = await engine.pause(s);
        clock.set(DateTime(2026, 12, 7, 8));
        expect(await engine.reconcile(), isNull);
        expect(await logs.totalSecondsFor(goal.id, day1), 420);
      },
    );

    test('never continues past the end of the horizon (D6)', () async {
      final end = goal.endDate; // 2026-12-31
      clock.set(DateTime(end.year, end.month, end.day, 23, 30));
      await engine.start(goal, end);
      clock.set(DateTime(2027, 1, 1, 0, 30));
      expect(await engine.reconcile(), isNull);
      expect(await logs.totalSecondsFor(goal.id, end), 1800);
    });

    test('same-day session is left untouched', () async {
      final s = await engine.start(goal, day1);
      clock.advance(const Duration(hours: 1));
      expect(await engine.reconcile(), s);
    });
  });
}
