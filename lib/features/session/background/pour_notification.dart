import '../../../core/utils/duration_format.dart';
import '../session_copy.dart';

/// Button ids on the pouring notification.
abstract final class PourAction {
  static const pause = 'pause';
  static const resume = 'resume';
  static const stop = 'stop';
}

/// Messages from the service isolate to the app.
abstract final class PourMessage {
  /// The session changed in the database (pause, resume, safety net,
  /// midnight); reload it.
  static const changed = 'changed';

  /// The user pressed Stop on the notification: show Frame 11.
  static const stop = 'stop';
}

/// Title and text of the ongoing pouring notification.
({String title, String text}) pourNotificationContent({
  required String goalTitle,
  required int seconds,
  required int targetSeconds,
  required bool running,
}) {
  final time = formatTimer(seconds);
  return (
    title: running ? '$goalTitle · $time' : 'Paused · $time',
    text: liveSessionLine(
      seconds: seconds,
      targetSeconds: targetSeconds,
      running: running,
    ),
  );
}

/// The one-off alert when the running day crosses the safety net.
const safetyNetNotificationTitle = 'Safety net reached';

/// The one-off alert when the running day reaches its target.
const cupFullNotificationTitle = 'Cup full!';

String cupFullNotificationBody(String goalTitle) =>
    "You hit today's goal for $goalTitle. Keep pouring or save it.";
