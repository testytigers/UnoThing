import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/time/local_date.dart';
import '../../domain/models/active_session.dart';
import '../../domain/models/goal.dart';
import 'app_channels.dart';

/// One notification to schedule.
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.at,
    required this.channel,
    required this.title,
    required this.body,
    required this.payload,
    this.startAction = false,
  });

  /// Stable per goal, kind and day, so a shown one can be withdrawn.
  final int id;

  /// Local wall-clock time.
  final DateTime at;
  final AppChannel channel;
  final String title;
  final String body;
  final String payload;

  /// Shows a "Start pouring" button.
  final bool startAction;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.at == at &&
      other.channel == channel &&
      other.title == title &&
      other.body == body &&
      other.payload == payload &&
      other.startAction == startAction;

  @override
  int get hashCode =>
      Object.hash(id, at, channel, title, body, payload, startAction);

  @override
  String toString() => 'PlannedNotification($id, $at, ${channel.name}, $title)';
}

/// How far ahead reminders are planned. The plan is rebuilt every time the
/// app opens or a day changes, so this only matters to someone who stops
/// opening the app: after a week the reminders go quiet.
const reminderPlanDays = 7;

/// The evening last call, local time.
const lastCallMinutes = 21 * 60;

/// Milestones arrive in the morning.
const milestoneMinutes = 9 * 60;

/// Notification ids, by kind. A shown notification with the same id is
/// replaced, and [todayIds] withdraws today's once the day is saved.
abstract final class ReminderIds {
  static int daily(int goalId, int dayOffset) =>
      10000 + (goalId % 1000) * 10 + dayOffset;
  static int lastCall(int dayOffset) => 20000 + dayOffset;
  static int milestone(int goalId, int kind) =>
      30000 + (goalId % 1000) * 10 + kind;
}

/// Every reminder and milestone due from [now] on.
///
/// - Daily reminder: on each pour day inside the horizon, at the goal's
///   time; today's is skipped once the day is saved or while pouring.
/// - Last call: at 9 PM on a day some goal still needs saving, for every
///   such goal at once.
/// - Milestones: halfway, the start of the final week, and the last day.
List<PlannedNotification> planReminders({
  required List<Goal> goals,
  required DateTime now,
  required Map<int, int> todaySeconds,
  required ActiveSession? session,
  required bool lastCall,
  required bool milestones,
}) {
  final today = LocalDate.from(now);
  final plan = <PlannedNotification>[];

  bool needsSaving(Goal goal, LocalDate day) {
    if (!goal.contains(day) || !goal.isActiveDay(day)) return false;
    if (day != today) return true;
    final pouring = session?.goalId == goal.id && session?.date == today;
    return !pouring && (todaySeconds[goal.id] ?? 0) < safetyNetSeconds;
  }

  DateTime at(LocalDate day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  for (var offset = 0; offset < reminderPlanDays; offset++) {
    final day = today.addDays(offset);

    for (final goal in goals) {
      final minutes = goal.reminderMinutes;
      if (minutes == null || !needsSaving(goal, day)) continue;
      final when = at(day, minutes);
      if (!when.isAfter(now)) continue;
      plan.add(
        PlannedNotification(
          id: ReminderIds.daily(goal.id, offset),
          at: when,
          channel: AppChannel.dailyReminders,
          title: goal.title,
          body: dailyReminderBody(day),
          payload: NotificationPayload.goal(goal.id),
          startAction: true,
        ),
      );
    }

    if (lastCall) {
      final when = at(day, lastCallMinutes);
      final open = goals.where((g) => needsSaving(g, day)).toList();
      if (when.isAfter(now) && open.isNotEmpty) {
        plan.add(
          PlannedNotification(
            id: ReminderIds.lastCall(offset),
            at: when,
            channel: AppChannel.lastCall,
            title: open.length == 1
                ? 'Last call for ${open.single.title}'
                : 'Last call',
            body: lastCallBody(open.map((g) => g.title).toList()),
            payload: NotificationPayload.goal(open.first.id),
            startAction: open.length == 1,
          ),
        );
      }
    }
  }

  if (milestones) {
    for (final goal in goals) {
      for (final (kind, day, title, body) in _milestones(goal)) {
        final when = at(day, milestoneMinutes);
        if (!when.isAfter(now)) continue;
        plan.add(
          PlannedNotification(
            id: ReminderIds.milestone(goal.id, kind),
            at: when,
            channel: AppChannel.milestones,
            title: title,
            body: body,
            payload: NotificationPayload.goal(goal.id),
          ),
        );
      }
    }
  }

  plan.sort((a, b) => a.at.compareTo(b.at));
  return plan;
}

/// The ids of today's reminders for [goalId] that should disappear from the
/// shade once the day is saved.
List<int> todayIds(int goalId) => [
  ReminderIds.daily(goalId, 0),
  ReminderIds.lastCall(0),
];

List<(int, LocalDate, String, String)> _milestones(Goal goal) {
  final days = goal.totalDays;
  final title = goal.title;
  return [
    if (days >= 14)
      (
        0,
        goal.startDate.addDays(days ~/ 2),
        'Halfway there!',
        "You're halfway through your $title pact. Keep the cups coming.",
      ),
    if (days >= 21)
      (
        1,
        goal.endDate.addDays(-6),
        'Final week',
        '7 days left in your $title pact. Finish strong.',
      ),
    (
      2,
      goal.endDate,
      'Last day',
      'Today is the last day of your $title pact. Make it count.',
    ),
  ];
}

/// Daily reminder lines, varied by day so they don't go stale.
String dailyReminderBody(LocalDate day) {
  const lines = [
    'Your cup is waiting. Even 5 minutes saves the day.',
    'Time to pour. A few minutes keeps the pact alive.',
    "Today's cup is empty. Pour the first drop.",
    'Show up for a few minutes. That is the whole trick.',
  ];
  return lines[(day.year * 400 + day.month * 31 + day.day) % lines.length];
}

/// "Learn Judo needs 5 minutes to save today." or, for several goals,
/// "Learn Judo and Read still need 5 minutes each."
String lastCallBody(List<String> titles) {
  if (titles.length == 1) return '5 minutes saves today. The night is young.';
  final names = titles.length == 2
      ? '${titles[0]} and ${titles[1]}'
      : '${titles.sublist(0, titles.length - 1).join(', ')} '
            'and ${titles.last}';
  return '$names still need 5 minutes each.';
}
