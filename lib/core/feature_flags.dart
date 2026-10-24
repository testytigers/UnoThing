/// Switches for features that ship hidden or in testing.
abstract final class FeatureFlags {
  /// Several goals at once (Pro), with the Shelf's habit pages and the Pro
  /// preview switch in Settings. On while it's being tested; to hide it,
  /// set the default to false or build with `--dart-define=MULTI_HABIT=false`.
  static const multiHabit = bool.fromEnvironment(
    'MULTI_HABIT',
    defaultValue: true,
  );
}
