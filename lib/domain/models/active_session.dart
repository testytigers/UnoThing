import 'package:flutter/foundation.dart';

import '../../core/time/local_date.dart';

/// A stopwatch session, persisted so it survives the app being killed.
///
/// value = baseSeconds + accumulatedSeconds + (now - segmentStartedAt, if running)
@immutable
class ActiveSession {
  const ActiveSession({
    required this.goalId,
    required this.date,
    required this.baseSeconds,
    required this.segmentStartedAt,
    required this.accumulatedSeconds,
    required this.safetyNetFired,
    this.targetFired = false,
  });

  /// The goal being poured into.
  final int goalId;

  /// The local date this session's time belongs to.
  final LocalDate date;

  /// The day's banked total when the session started.
  final int baseSeconds;

  /// Wall clock start of the running segment. Null while paused.
  final DateTime? segmentStartedAt;

  /// Seconds from earlier running segments of this session.
  final int accumulatedSeconds;

  /// Whether the safety-net haptic has already fired for this session (or
  /// must not fire because the session resumed at or above the safety net).
  final bool safetyNetFired;

  /// Whether the "cup full" alert has fired for this session (or must not,
  /// because it resumed at or above the daily target).
  final bool targetFired;

  bool get isRunning => segmentStartedAt != null;

  /// Current stopwatch value in whole seconds.
  int valueAt(DateTime now) => baseSeconds + unbankedAt(now);

  /// Seconds added by this session that are not yet banked.
  int unbankedAt(DateTime now) {
    final started = segmentStartedAt;
    if (started == null) return accumulatedSeconds;
    final running = now.difference(started).inSeconds;
    return accumulatedSeconds + (running < 0 ? 0 : running);
  }

  ActiveSession copyWith({
    LocalDate? date,
    int? baseSeconds,
    DateTime? Function()? segmentStartedAt,
    int? accumulatedSeconds,
    bool? safetyNetFired,
    bool? targetFired,
  }) {
    return ActiveSession(
      goalId: goalId,
      date: date ?? this.date,
      baseSeconds: baseSeconds ?? this.baseSeconds,
      segmentStartedAt: segmentStartedAt != null
          ? segmentStartedAt()
          : this.segmentStartedAt,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      safetyNetFired: safetyNetFired ?? this.safetyNetFired,
      targetFired: targetFired ?? this.targetFired,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ActiveSession &&
      other.goalId == goalId &&
      other.date == date &&
      other.baseSeconds == baseSeconds &&
      // Same instant, whether stored as UTC or local, at storage precision.
      other.segmentStartedAt?.millisecondsSinceEpoch ==
          segmentStartedAt?.millisecondsSinceEpoch &&
      other.accumulatedSeconds == accumulatedSeconds &&
      other.safetyNetFired == safetyNetFired &&
      other.targetFired == targetFired;

  @override
  int get hashCode => Object.hash(
    goalId,
    date,
    baseSeconds,
    segmentStartedAt?.millisecondsSinceEpoch,
    accumulatedSeconds,
    safetyNetFired,
    targetFired,
  );
}
