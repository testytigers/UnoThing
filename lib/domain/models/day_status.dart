enum DayStatus {
  /// Outside the goal's horizon (before start or after end). Not in the
  /// spec's table; see open decision D7.
  outsideHorizon,
  future,
  rest,
  targetReached,
  saved,
  pending,
  spilled;

  /// A day that met at least the safety net.
  bool get isSuccess => this == targetReached || this == saved;
}
