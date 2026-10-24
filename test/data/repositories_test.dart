import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/active_session_repository.dart';
import 'package:the_one_thing/data/repositories/auth_repository.dart';
import 'package:the_one_thing/data/repositories/daily_log_repository.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/data/repositories/preferences_repository.dart';
import 'package:the_one_thing/domain/models/active_session.dart';
import 'package:the_one_thing/domain/models/day_status.dart';
import 'package:the_one_thing/domain/models/goal.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late GoalRepository goals;
  late DailyLogRepository logs;
  late ActiveSessionRepository sessions;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    goals = GoalRepository(db);
    logs = DailyLogRepository(db);
    sessions = ActiveSessionRepository(db);
  });

  tearDown(() => db.close());

  const today = LocalDate(2026, 12, 9);

  Future<Goal> createGoal([String title = 'Learn Judo']) => goals.createGoal(
    title: title,
    horizonMonths: 3,
    dailyTargetSeconds: 1500,
    activeWeekdays: {1, 2, 3, 4, 5},
    startDate: const LocalDate(2026, 12, 1),
  );

  test('goal round trips, including weekdays and start date', () async {
    final created = await createGoal();
    final g = (await goals.getGoal(created.id))!;
    expect(g.title, 'Learn Judo');
    expect(g.activeWeekdays, {1, 2, 3, 4, 5});
    expect(g.startDate, const LocalDate(2026, 12, 1));
    expect(g.endDate, const LocalDate(2027, 2, 28));
    expect(g.reminderMinutes, isNull);
  });

  test('goals are kept side by side, in the order they were added', () async {
    await createGoal('Learn Judo');
    await createGoal('Read');
    final all = await goals.getGoals();
    expect(all.map((g) => g.title), ['Learn Judo', 'Read']);
    expect(all.map((g) => g.position), [0, 1]);
  });

  test('the reminder time is stored and cleared', () async {
    final g = await createGoal();
    await goals.setReminder(g.id, 19 * 60 + 30);
    expect((await goals.getGoal(g.id))!.reminderMinutes, 1170);
    await goals.setReminder(g.id, null);
    expect((await goals.getGoal(g.id))!.reminderMinutes, isNull);
  });

  test('setTotal stores seconds and the recomputed status', () async {
    final g = await createGoal();
    const day = LocalDate(2026, 12, 8);

    await logs.setTotal(g, day, 306, today);
    expect((await logs.getLog(g.id, day))!.status, DayStatus.saved);
    expect(await logs.totalSecondsFor(g.id, day), 306);

    await logs.setTotal(g, day, 0, today);
    expect((await logs.getLog(g.id, day))!.status, DayStatus.spilled);

    await logs.setTotal(g, day, 1500, today);
    expect((await logs.getLog(g.id, day))!.status, DayStatus.targetReached);
  });

  test('each goal keeps its own day', () async {
    final judo = await createGoal('Learn Judo');
    final read = await createGoal('Read');
    const day = LocalDate(2026, 12, 8);
    await logs.setTotal(judo, day, 306, today);
    await logs.setTotal(read, day, 1500, today);
    expect(await logs.totalSecondsFor(judo.id, day), 306);
    expect(await logs.totalSecondsFor(read.id, day), 1500);
    expect(await logs.watchDay(day).first, {judo.id: 306, read.id: 1500});
  });

  test('watchRange returns only days in range', () async {
    final g = await createGoal();
    await logs.setTotal(g, const LocalDate(2026, 12, 2), 400, today);
    await logs.setTotal(g, const LocalDate(2026, 12, 8), 400, today);
    final map = await logs
        .watchRange(
          g.id,
          const LocalDate(2026, 12, 7),
          const LocalDate(2026, 12, 13),
        )
        .first;
    expect(map.keys, [const LocalDate(2026, 12, 8)]);
  });

  test('active session persists running and paused states', () async {
    final started = DateTime.utc(2026, 12, 9, 10, 0, 0);
    final s = ActiveSession(
      goalId: 1,
      date: today,
      baseSeconds: 306,
      segmentStartedAt: started,
      accumulatedSeconds: 12,
      safetyNetFired: true,
    );
    await sessions.save(s);
    expect(await sessions.get(), s);

    await sessions.save(s.copyWith(segmentStartedAt: () => null));
    expect((await sessions.get())!.isRunning, isFalse);
    expect(await db.select(db.activeSessions).get(), hasLength(1));

    await sessions.clear();
    expect(await sessions.get(), isNull);
  });

  ActiveSession pausedSession(int goalId) => ActiveSession(
    goalId: goalId,
    date: today,
    baseSeconds: 0,
    segmentStartedAt: null,
    accumulatedSeconds: 0,
    safetyNetFired: false,
  );

  test('deleteGoal removes only that goal, its days and its session', () async {
    final judo = await createGoal('Learn Judo');
    final read = await createGoal('Read');
    await logs.setTotal(judo, today, 400, today);
    await logs.setTotal(read, today, 500, today);
    await sessions.save(pausedSession(read.id));
    await goals.deleteGoal(read.id);
    expect((await goals.getGoals()).map((g) => g.id), [judo.id]);
    expect(await logs.getLog(read.id, today), isNull);
    expect(await logs.totalSecondsFor(judo.id, today), 400);
    expect(await sessions.get(), isNull);
  });

  test('resetAll deletes every goal, log and session', () async {
    final g = await createGoal();
    await logs.setTotal(g, today, 400, today);
    await sessions.save(pausedSession(g.id));
    await goals.resetAll();
    expect(await goals.getGoals(), isEmpty);
    expect(await logs.getLog(g.id, today), isNull);
    expect(await sessions.get(), isNull);
  });

  test('preferences store, overwrite and remove values', () async {
    final prefs = PreferencesRepository(db);
    expect(AppPreferences.from(await prefs.getAll()), const AppPreferences());
    await prefs.setBool(Pref.proPreview, true);
    await prefs.setBool(Pref.lastCall, false);
    final read = AppPreferences.from(await prefs.getAll());
    expect(read.proPreview, isTrue);
    expect(read.lastCall, isFalse);
    expect(read.milestones, isTrue);
    await prefs.set(Pref.proPreview, null);
    expect(AppPreferences.from(await prefs.getAll()).proPreview, isFalse);
  });

  group('local auth (D3)', () {
    test('create then sign in, case-insensitive email', () async {
      final auth = LocalAuthRepository(db);
      await auth.createAccount(email: 'Me@Example.com', password: 'secret12');
      await auth.signIn(email: ' me@example.com ', password: 'secret12');
    });

    test('wrong password and unknown email are rejected', () async {
      final auth = LocalAuthRepository(db);
      await auth.createAccount(email: 'me@example.com', password: 'secret12');
      expect(
        auth.signIn(email: 'me@example.com', password: 'nope'),
        throwsA(isA<AuthException>()),
      );
      expect(
        auth.signIn(email: 'other@example.com', password: 'secret12'),
        throwsA(isA<AuthException>()),
      );
    });

    test('duplicate account is rejected and password is not stored', () async {
      final auth = LocalAuthRepository(db);
      await auth.createAccount(email: 'me@example.com', password: 'secret12');
      expect(
        auth.createAccount(email: 'me@example.com', password: 'x'),
        throwsA(isA<AuthException>()),
      );
      final row = await db.select(db.localAccounts).getSingle();
      expect(row.passwordHash, isNot(contains('secret12')));
    });
  });
}
