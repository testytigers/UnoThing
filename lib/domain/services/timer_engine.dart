import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/active_session_repository.dart';
import '../../data/repositories/daily_log_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../models/active_session.dart';
import '../models/goal.dart';

/// Stopwatch rules. Time is never counted in memory: the value is always
/// derived from persisted timestamps, so it survives the process dying.
class TimerEngine {
  TimerEngine({required AppDatabase db, required this.clock})
    : _db = db,
      _sessions = ActiveSessionRepository(db),
      _logs = DailyLogRepository(db),
      _goals = GoalRepository(db);

  final AppDatabase _db;
  final Clock clock;
  final ActiveSessionRepository _sessions;
  final DailyLogRepository _logs;
  final GoalRepository _goals;

  DateTime get _now => clock.now();

  Future<ActiveSession?> current() => _sessions.get();

  /// Starts a session for [goal] on [date], resuming from that day's banked
  /// total. One goal pours at a time. The safety-net and cup-full alerts are
  /// pre-marked as fired when resuming at or above them.
  Future<ActiveSession> start(Goal goal, LocalDate date) async {
    final existing = await _sessions.get();
    if (existing != null) {
      throw StateError('A session is already active for ${existing.date}');
    }
    final session = await _fresh(goal, date, _now);
    await _sessions.save(session);
    return session;
  }

  Future<ActiveSession> _fresh(
    Goal goal,
    LocalDate date,
    DateTime startedAt,
  ) async {
    final base = await _logs.totalSecondsFor(goal.id, date);
    return ActiveSession(
      goalId: goal.id,
      date: date,
      baseSeconds: base,
      segmentStartedAt: startedAt,
      accumulatedSeconds: 0,
      safetyNetFired: base >= safetyNetSeconds,
      targetFired: base >= goal.dailyTargetSeconds,
    );
  }

  /// Folds the running segment into `accumulatedSeconds`.
  Future<ActiveSession> pause(ActiveSession session) async {
    if (!session.isRunning) return session;
    final paused = session.copyWith(
      accumulatedSeconds: session.unbankedAt(_now),
      segmentStartedAt: () => null,
    );
    await _sessions.save(paused);
    return paused;
  }

  Future<ActiveSession> resume(ActiveSession session) async {
    if (session.isRunning) return session;
    final running = session.copyWith(segmentStartedAt: () => _now);
    await _sessions.save(running);
    return running;
  }

  /// Persists that the safety-net haptic fired, so it never fires twice.
  Future<ActiveSession> markSafetyNetFired(ActiveSession session) async {
    final marked = session.copyWith(safetyNetFired: true);
    await _sessions.save(marked);
    return marked;
  }

  /// Persists that the cup-full alert fired, so it never fires twice.
  Future<ActiveSession> markTargetFired(ActiveSession session) async {
    final marked = session.copyWith(targetFired: true);
    await _sessions.save(marked);
    return marked;
  }

  /// Writes the stopwatch's current value as the day's new total and ends
  /// the session. Returns the banked total.
  Future<int> bank(ActiveSession session, Goal goal) {
    assert(goal.id == session.goalId);
    final now = _now;
    final value = math.min(session.valueAt(now), maxLoggableSeconds);
    return _db.transaction(() async {
      await _logs.setTotal(goal, session.date, value, LocalDate.from(now));
      await _sessions.clear();
      return value;
    });
  }

  /// Drops only the unbanked part; the day's banked total is untouched.
  Future<void> discard() => _sessions.clear();

  /// Brings a stored session up to date with the wall clock.
  ///
  /// - Running across midnight: the part up to 23:59:59 is banked to the old
  ///   date and the remainder continues as a new session on the next date,
  ///   repeated for every midnight passed. A session never continues past the
  ///   horizon's end (D6).
  /// - Paused on a past date: banked to its own date so no time is lost (D8).
  /// - Its goal was deleted: dropped.
  Future<ActiveSession?> reconcile() async {
    final stored = await _sessions.get();
    if (stored == null) return null;
    final goal = await _goals.getGoal(stored.goalId);
    if (goal == null) {
      await _sessions.clear();
      return null;
    }
    final now = _now;
    final today = LocalDate.from(now);
    if (!stored.date.isBefore(today)) return stored;

    return _db.transaction(() async {
      if (!stored.isRunning) {
        await _logs.setTotal(
          goal,
          stored.date,
          math.min(stored.valueAt(now), maxLoggableSeconds),
          today,
        );
        await _sessions.clear();
        return null;
      }

      var session = stored;
      while (session.date.isBefore(today)) {
        final midnight = session.date.endOfDayLocal;
        await _logs.setTotal(
          goal,
          session.date,
          math.min(session.valueAt(midnight), maxLoggableSeconds),
          today,
        );
        final next = session.date.addDays(1);
        if (next.isAfter(goal.endDate)) {
          await _sessions.clear();
          return null;
        }
        session = await _fresh(goal, next, midnight);
      }
      await _sessions.save(session);
      return session;
    });
  }
}

final timerEngineProvider = Provider<TimerEngine>(
  (ref) => TimerEngine(
    db: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);
