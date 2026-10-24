import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/local_date.dart';
import '../../domain/models/daily_log.dart';
import '../../domain/models/day_status.dart';
import '../../domain/models/goal.dart';
import '../../domain/services/day_status_service.dart';
import '../db/app_database.dart';

class DailyLogRepository {
  DailyLogRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$DailyLogsTable, DailyLogRow> _day(
    int goalId,
    LocalDate date,
  ) =>
      _db.select(_db.dailyLogs)
        ..where((t) => t.goalId.equals(goalId) & t.date.equals(date.toIso()));

  /// [goalId]'s banked logs from [from] to [to] inclusive, keyed by date.
  /// Days without a row have 0 seconds.
  Stream<Map<LocalDate, DailyLog>> watchRange(
    int goalId,
    LocalDate from,
    LocalDate to,
  ) {
    final query = _db.select(_db.dailyLogs)
      ..where(
        (t) =>
            t.goalId.equals(goalId) &
            t.date.isBetweenValues(from.toIso(), to.toIso()),
      );
    return query.watch().map(
      (rows) => {for (final r in rows) LocalDate.parse(r.date): _toModel(r)},
    );
  }

  Future<Map<LocalDate, DailyLog>> getRange(
    int goalId,
    LocalDate from,
    LocalDate to,
  ) => watchRange(goalId, from, to).first;

  /// Every goal's banked seconds on [date], keyed by goal id.
  Stream<Map<int, int>> watchDay(LocalDate date) {
    final query = _db.select(_db.dailyLogs)
      ..where((t) => t.date.equals(date.toIso()));
    return query.watch().map(
      (rows) => {for (final r in rows) r.goalId: r.totalSeconds},
    );
  }

  Future<DailyLog?> getLog(int goalId, LocalDate date) async {
    final row = await _day(goalId, date).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<int> totalSecondsFor(int goalId, LocalDate date) async =>
      (await getLog(goalId, date))?.totalSeconds ?? 0;

  /// Overwrites [goal]'s total on [date] and stores the recomputed status.
  Future<DailyLog> setTotal(
    Goal goal,
    LocalDate date,
    int totalSeconds,
    LocalDate today,
  ) async {
    assert(totalSeconds >= 0);
    final status = dayStatus(date, totalSeconds, goal, today);
    await _db
        .into(_db.dailyLogs)
        .insertOnConflictUpdate(
          DailyLogsCompanion.insert(
            goalId: goal.id,
            date: date.toIso(),
            totalSeconds: totalSeconds,
            status: status.name,
          ),
        );
    return DailyLog(date: date, totalSeconds: totalSeconds, status: status);
  }

  static DailyLog _toModel(DailyLogRow row) => DailyLog(
    date: LocalDate.parse(row.date),
    totalSeconds: row.totalSeconds,
    status: DayStatus.values.byName(row.status),
  );
}

final dailyLogRepositoryProvider = Provider<DailyLogRepository>(
  (ref) => DailyLogRepository(ref.watch(databaseProvider)),
);
