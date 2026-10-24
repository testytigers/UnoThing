import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/local_date.dart';
import '../../domain/models/goal.dart';
import '../db/app_database.dart';
import 'preferences_repository.dart';

class GoalRepository {
  GoalRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$GoalsTable, GoalRow> get _ordered =>
      _db.select(_db.goals)..orderBy([
        (t) => OrderingTerm(expression: t.position),
        (t) => OrderingTerm(expression: t.id),
      ]);

  /// Every goal, in Shelf order.
  Stream<List<Goal>> watchGoals() =>
      _ordered.watch().map((rows) => rows.map(_toModel).toList());

  Future<List<Goal>> getGoals() =>
      _ordered.get().then((rows) => rows.map(_toModel).toList());

  Future<Goal?> getGoal(int id) =>
      (_db.select(_db.goals)..where((t) => t.id.equals(id)))
          .getSingleOrNull()
          .then((row) => row == null ? null : _toModel(row));

  /// Adds a goal after the existing ones.
  Future<Goal> createGoal({
    required String title,
    required int horizonMonths,
    required int dailyTargetSeconds,
    required Set<int> activeWeekdays,
    required LocalDate startDate,
    int? reminderMinutes,
  }) {
    return _db.transaction(() async {
      final last = await (_db.selectOnly(
        _db.goals,
      )..addColumns([_db.goals.position.max()])).getSingle();
      final position = (last.read(_db.goals.position.max()) ?? -1) + 1;
      final id = await _db
          .into(_db.goals)
          .insert(
            GoalsCompanion.insert(
              title: title,
              horizonMonths: horizonMonths,
              dailyTargetSeconds: dailyTargetSeconds,
              activeWeekdaysMask: weekdaysToMask(activeWeekdays),
              startDate: startDate.toIso(),
              reminderMinutes: Value(reminderMinutes),
              position: Value(position),
            ),
          );
      return Goal(
        id: id,
        title: title,
        horizonMonths: horizonMonths,
        dailyTargetSeconds: dailyTargetSeconds,
        activeWeekdays: Set.unmodifiable(activeWeekdays),
        startDate: startDate,
        reminderMinutes: reminderMinutes,
        position: position,
      );
    });
  }

  /// The daily reminder time in minutes after midnight, or null for off.
  Future<void> setReminder(int goalId, int? minutes) =>
      (_db.update(_db.goals)..where((t) => t.id.equals(goalId))).write(
        GoalsCompanion(reminderMinutes: Value(minutes)),
      );

  /// Deletes one goal and everything tied to it (its days, its session).
  Future<void> deleteGoal(int goalId) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.activeSessions,
      )..where((t) => t.goalId.equals(goalId))).go();
      await (_db.delete(
        _db.dailyLogs,
      )..where((t) => t.goalId.equals(goalId))).go();
      await (_db.delete(_db.goals)..where((t) => t.id.equals(goalId))).go();
    });
  }

  /// Deletes every goal and everything tied to them.
  Future<void> resetAll() {
    return _db.transaction(() async {
      await _db.delete(_db.activeSessions).go();
      await _db.delete(_db.dailyLogs).go();
      await _db.delete(_db.goals).go();
    });
  }

  static Goal _toModel(GoalRow row) => Goal(
    id: row.id,
    title: row.title,
    horizonMonths: row.horizonMonths,
    dailyTargetSeconds: row.dailyTargetSeconds,
    activeWeekdays: Set.unmodifiable(maskToWeekdays(row.activeWeekdaysMask)),
    startDate: LocalDate.parse(row.startDate),
    reminderMinutes: row.reminderMinutes,
    position: row.position,
  );
}

int weekdaysToMask(Set<int> weekdays) {
  var mask = 0;
  for (final d in weekdays) {
    assert(d >= 1 && d <= 7);
    mask |= 1 << (d - 1);
  }
  return mask;
}

Set<int> maskToWeekdays(int mask) => {
  for (var d = 1; d <= 7; d++)
    if (mask & (1 << (d - 1)) != 0) d,
};

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(ref.watch(databaseProvider)),
);

/// Every goal, in Shelf order. Empty before onboarding / after a reset.
final goalsProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(goalRepositoryProvider).watchGoals(),
);

/// The goal the Shelf opened on last. Overridden in `main` from the stored
/// preference.
final initialShelfGoalProvider = Provider<int?>((ref) => null);

/// The goal on screen: the Shelf's page, and what the Horizon, a past day or
/// today's banked cup show.
class SelectedGoalNotifier extends Notifier<int?> {
  @override
  int? build() => ref.read(initialShelfGoalProvider);

  void select(int goalId) {
    if (state == goalId) return;
    state = goalId;
    ref
        .read(preferencesRepositoryProvider)
        .set(Pref.shelfGoal, '$goalId')
        .ignore();
  }
}

final selectedGoalIdProvider = NotifierProvider<SelectedGoalNotifier, int?>(
  SelectedGoalNotifier.new,
);

/// The selected goal (the first one if none was picked yet), or null before
/// onboarding / after a reset.
final goalProvider = Provider<AsyncValue<Goal?>>((ref) {
  final selected = ref.watch(selectedGoalIdProvider);
  return ref
      .watch(goalsProvider)
      .whenData(
        (goals) =>
            goals.where((g) => g.id == selected).firstOrNull ??
            goals.firstOrNull,
      );
});
