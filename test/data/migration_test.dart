import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/active_session_repository.dart';
import 'package:the_one_thing/data/repositories/daily_log_repository.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/data/repositories/preferences_repository.dart';
import 'package:the_one_thing/domain/models/day_status.dart';

/// The tables exactly as version 1 created them.
void _createV1(Database raw) {
  raw
    ..execute(
      'CREATE TABLE "goals" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"title" TEXT NOT NULL, "horizon_months" INTEGER NOT NULL, '
      '"daily_target_seconds" INTEGER NOT NULL, '
      '"active_weekdays_mask" INTEGER NOT NULL, "start_date" TEXT NOT NULL)',
    )
    ..execute(
      'CREATE TABLE "daily_logs" ("date" TEXT NOT NULL, '
      '"total_seconds" INTEGER NOT NULL, "status" TEXT NOT NULL, '
      'PRIMARY KEY ("date"))',
    )
    ..execute(
      'CREATE TABLE "active_sessions" ("id" INTEGER NOT NULL DEFAULT 1, '
      '"date" TEXT NOT NULL, "base_seconds" INTEGER NOT NULL, '
      '"segment_started_at_ms" INTEGER NULL, '
      '"accumulated_seconds" INTEGER NOT NULL, '
      '"safety_net_fired" INTEGER NOT NULL DEFAULT 0 CHECK '
      '("safety_net_fired" IN (0, 1)), PRIMARY KEY ("id"))',
    )
    ..execute(
      'CREATE TABLE "local_accounts" ("email" TEXT NOT NULL, '
      '"password_hash" TEXT NOT NULL, "salt" TEXT NOT NULL, '
      'PRIMARY KEY ("email"))',
    );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('version 1 data moves to version 2 under its only goal', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          if (raw.userVersion != 0) return;
          _createV1(raw);
          raw
            ..execute(
              "INSERT INTO goals (title, horizon_months, daily_target_seconds, "
              "active_weekdays_mask, start_date) "
              "VALUES ('Learn Judo', 3, 1500, 31, '2026-12-01')",
            )
            ..execute(
              "INSERT INTO daily_logs VALUES ('2026-12-02', 306, 'saved'), "
              "('2026-12-03', 1600, 'targetReached')",
            )
            ..execute(
              "INSERT INTO active_sessions (id, date, base_seconds, "
              "segment_started_at_ms, accumulated_seconds, safety_net_fired) "
              "VALUES (1, '2026-12-09', 306, NULL, 40, 1)",
            )
            ..execute(
              "INSERT INTO local_accounts VALUES ('me@example.com', 'h', 's')",
            )
            ..userVersion = 1;
        },
      ),
    );
    addTearDown(db.close);

    final goals = await GoalRepository(db).getGoals();
    expect(goals, hasLength(1));
    final goal = goals.single;
    expect(goal.title, 'Learn Judo');
    expect(goal.activeWeekdays, {1, 2, 3, 4, 5});
    expect(goal.reminderMinutes, isNull);
    expect(goal.position, 0);

    final logs = DailyLogRepository(db);
    final dec2 = (await logs.getLog(goal.id, const LocalDate(2026, 12, 2)))!;
    expect(dec2.totalSeconds, 306);
    expect(dec2.status, DayStatus.saved);
    expect(
      await logs.totalSecondsFor(goal.id, const LocalDate(2026, 12, 3)),
      1600,
    );

    final session = (await ActiveSessionRepository(db).get())!;
    expect(session.goalId, goal.id);
    expect(session.baseSeconds, 306);
    expect(session.accumulatedSeconds, 40);
    expect(session.safetyNetFired, isTrue);
    expect(session.targetFired, isFalse);

    // The new table is there, with its defaults.
    final prefs = await PreferencesRepository(db).getAll();
    expect(AppPreferences.from(prefs), const AppPreferences());
    expect(await db.select(db.localAccounts).get(), hasLength(1));

    // And a second goal can now sit beside the first.
    final read = await GoalRepository(db).createGoal(
      title: 'Read',
      horizonMonths: 1,
      dailyTargetSeconds: 600,
      activeWeekdays: {6, 7},
      startDate: const LocalDate(2026, 12, 9),
    );
    expect(read.position, 1);
  });

  test('version 1 days without a goal are dropped', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          if (raw.userVersion != 0) return;
          _createV1(raw);
          raw
            ..execute(
              "INSERT INTO daily_logs VALUES ('2026-12-02', 306, 'saved')",
            )
            ..userVersion = 1;
        },
      ),
    );
    addTearDown(db.close);
    expect(await GoalRepository(db).getGoals(), isEmpty);
    expect(await db.select(db.dailyLogs).get(), isEmpty);
  });
}
