import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/theme.dart';

/// Android notification channels, one per kind, so people can silence one
/// kind in the system settings and keep the others. The ongoing "Pouring"
/// channel belongs to the foreground service.
enum AppChannel {
  sessionMoments(
    'session_moments',
    'Session moments',
    'The safety net and a full cup while you pour with the app closed.',
    Importance.high,
    AndroidNotificationCategory.status,
  ),
  dailyReminders(
    'daily_reminders',
    'Daily reminders',
    'Your reminder to pour, at the time you picked.',
    Importance.high,
    AndroidNotificationCategory.reminder,
  ),
  lastCall(
    'last_call',
    'Last call',
    "An evening nudge when today's cup isn't saved yet.",
    Importance.high,
    AndroidNotificationCategory.reminder,
  ),
  milestones(
    'milestones',
    'Milestones',
    'Halfway, the final week and the last day of a pact.',
    Importance.defaultImportance,
    AndroidNotificationCategory.event,
  );

  const AppChannel(
    this.id,
    this.title,
    this.description,
    this.importance,
    this.category,
  );

  final String id;
  final String title;
  final String description;
  final Importance importance;
  final AndroidNotificationCategory category;

  /// Channel ids from earlier versions, removed at startup.
  static const retired = ['safety_net'];

  AndroidNotificationDetails details({
    List<AndroidNotificationAction>? actions,
  }) => AndroidNotificationDetails(
    id,
    title,
    channelDescription: description,
    importance: importance,
    priority: importance == Importance.high
        ? Priority.high
        : Priority.defaultPriority,
    category: category,
    icon: 'ic_stat_pour',
    color: AppTokens.light.brand,
    actions: actions,
  );
}

/// What a notification tap should do, carried as its payload.
abstract final class NotificationPayload {
  /// Just open the app.
  static const open = 'open';

  /// Open the Shelf on a goal.
  static String goal(int goalId) => 'goal:$goalId';

  /// The goal id in a [goal] payload, or null.
  static int? goalId(String? payload) {
    if (payload == null || !payload.startsWith('goal:')) return null;
    return int.tryParse(payload.substring(5));
  }

  /// The "Start pouring" action button.
  static const startAction = 'start';
}
