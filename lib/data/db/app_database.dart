import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Goals, DailyLogs, ActiveSessions, LocalAccounts, Preferences],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'the_one_thing'));

  /// 1: one goal. 2: several goals (Pro), reminders, preferences.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Version 1 kept a single goal: its days and session become its own.
        final only = await customSelect(
          'SELECT id FROM goals ORDER BY id LIMIT 1',
        ).getSingleOrNull();
        final goalId = only?.read<int>('id');
        await m.addColumn(goals, goals.reminderMinutes);
        await m.addColumn(goals, goals.position);
        if (goalId == null) {
          await customStatement('DELETE FROM daily_logs');
          await customStatement('DELETE FROM active_sessions');
        }
        await m.alterTable(
          TableMigration(
            dailyLogs,
            columnTransformer: {dailyLogs.goalId: Constant(goalId ?? 0)},
            newColumns: [dailyLogs.goalId],
          ),
        );
        await m.alterTable(
          TableMigration(
            activeSessions,
            columnTransformer: {activeSessions.goalId: Constant(goalId ?? 0)},
            newColumns: [activeSessions.goalId, activeSessions.targetFired],
          ),
        );
        await m.createTable(preferences);
      }
    },
  );
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
