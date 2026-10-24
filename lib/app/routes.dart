/// Route paths. Frame numbers match the "Android Compact - N" wireframe labels.
///
/// Home lists the goals; one goal's pages are nested under its Shelf, so
/// `go(...)` always leaves Home and the Shelf underneath and Back returns
/// through them.
abstract final class Routes {
  static const login = '/login'; // Frame 1
  static const goal = '/onboarding/goal'; // Frame 2
  static const horizonStep = '/onboarding/horizon'; // Frame 3
  static const targetStep = '/onboarding/target'; // Frame 4
  static const daysStep = '/onboarding/days'; // Frame 5
  static const contract = '/onboarding/contract'; // Frame 6
  static const home = '/home'; // every goal
  static const settings = '/home/settings'; // D5
  static const shelf = '/home/habit'; // Frames 7 and 10, the selected goal
  static const horizon = '/home/habit/horizon'; // Frame 15
  static const session = '/home/habit/session'; // Frame 8
  static const sessionStop = '/home/habit/stop'; // Frame 11
  static const today = '/home/habit/today'; // Frame 12

  /// Frame 13 (past day) or Frame 14 (spilled), chosen by the day's live
  /// status, for an ISO date such as `2026-12-06`.
  static String day(String isoDate) => '/home/habit/day/$isoDate';
}
