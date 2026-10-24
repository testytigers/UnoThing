import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/local_date.dart';
import '../../domain/models/active_session.dart';
import '../db/app_database.dart';

class ActiveSessionRepository {
  ActiveSessionRepository(this._db);

  final AppDatabase _db;

  Future<ActiveSession?> get() =>
      _db.select(_db.activeSessions).getSingleOrNull().then(_toModel);

  Stream<ActiveSession?> watch() =>
      _db.select(_db.activeSessions).watchSingleOrNull().map(_toModel);

  Future<void> save(ActiveSession session) {
    return _db
        .into(_db.activeSessions)
        .insertOnConflictUpdate(
          ActiveSessionsCompanion.insert(
            id: const Value(1),
            goalId: session.goalId,
            date: session.date.toIso(),
            baseSeconds: session.baseSeconds,
            segmentStartedAtMs: Value(
              session.segmentStartedAt?.toUtc().millisecondsSinceEpoch,
            ),
            accumulatedSeconds: session.accumulatedSeconds,
            safetyNetFired: Value(session.safetyNetFired),
            targetFired: Value(session.targetFired),
          ),
        );
  }

  Future<void> clear() => _db.delete(_db.activeSessions).go();

  static ActiveSession? _toModel(ActiveSessionRow? row) {
    if (row == null) return null;
    final startedMs = row.segmentStartedAtMs;
    return ActiveSession(
      goalId: row.goalId,
      date: LocalDate.parse(row.date),
      baseSeconds: row.baseSeconds,
      segmentStartedAt: startedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startedMs, isUtc: true),
      accumulatedSeconds: row.accumulatedSeconds,
      safetyNetFired: row.safetyNetFired,
      targetFired: row.targetFired,
    );
  }
}

final activeSessionRepositoryProvider = Provider<ActiveSessionRepository>(
  (ref) => ActiveSessionRepository(ref.watch(databaseProvider)),
);
