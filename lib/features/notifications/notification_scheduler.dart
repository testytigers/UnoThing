import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import 'app_channels.dart';
import 'reminder_planner.dart';

/// A tap on a notification or one of its buttons.
@immutable
class NotificationTap {
  const NotificationTap({this.payload, this.actionId});

  final String? payload;

  /// The button pressed, or null for the notification itself.
  final String? actionId;
}

/// Schedules the app's reminders with the system. Faked in tests.
abstract interface class NotificationScheduler {
  /// Sets up channels and reports taps while the app runs.
  Future<void> init({required void Function(NotificationTap tap) onTap});

  /// The tap that launched the app, if any.
  Future<NotificationTap?> launchTap();

  /// Replaces every scheduled reminder with [plan].
  Future<void> replace(List<PlannedNotification> plan);

  /// Removes these notifications, shown or scheduled.
  Future<void> withdraw(List<int> ids);

  /// Whether the app may post notifications.
  Future<bool> enabled();

  /// Asks for the notification permission (Android 13+). True if granted.
  Future<bool> requestPermission();

  /// Opens the system's notification settings for the app.
  Future<void> openSettings();

  /// Whether reminders may fire on the minute ("Alarms & reminders",
  /// asked for on Android 14+). Without it they still come, up to about an
  /// hour late.
  Future<bool> exactAllowed();

  /// Opens the system's "Alarms & reminders" page for the app.
  Future<void> requestExact();
}

class LocalNotificationScheduler implements NotificationScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({required void Function(NotificationTap tap) onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_pour'),
      ),
      onDidReceiveNotificationResponse: (r) =>
          onTap(NotificationTap(payload: r.payload, actionId: r.actionId)),
    );
    final android = _android;
    if (android == null) return;
    for (final channel in AppChannel.values) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          channel.title,
          description: channel.description,
          importance: channel.importance,
        ),
      );
    }
    for (final id in AppChannel.retired) {
      await android.deleteNotificationChannel(channelId: id);
    }
  }

  @override
  Future<NotificationTap?> launchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final r = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || r == null) return null;
    return NotificationTap(payload: r.payload, actionId: r.actionId);
  }

  @override
  Future<void> replace(List<PlannedNotification> plan) async {
    // On the minute when allowed; otherwise inexact (no special permission,
    // kinder to the battery, but Android may hold it back up to an hour).
    final mode = await exactAllowed()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.cancelAllPendingNotifications();
    for (final n in plan) {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        // An absolute instant: the plan is rebuilt whenever the app opens,
        // so a change of time zone is picked up then.
        scheduledDate: tz.TZDateTime.from(n.at.toUtc(), tz.UTC),
        notificationDetails: NotificationDetails(
          android: n.channel.details(
            actions: n.startAction
                ? const [
                    AndroidNotificationAction(
                      NotificationPayload.startAction,
                      'Start pouring',
                      showsUserInterface: true,
                    ),
                  ]
                : null,
          ),
        ),
        androidScheduleMode: mode,
        payload: n.payload,
      );
    }
  }

  @override
  Future<void> withdraw(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  @override
  Future<bool> enabled() async =>
      await _android?.areNotificationsEnabled() ?? true;

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  @override
  Future<void> openSettings() async {
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<bool> exactAllowed() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  @override
  Future<void> requestExact() async {
    await _android?.requestExactAlarmsPermission();
  }
}

/// No system notifications: tests, and anywhere they're unavailable.
class NoopNotificationScheduler implements NotificationScheduler {
  /// The last plan handed over, for tests.
  List<PlannedNotification> plan = const [];

  /// Ids withdrawn so far, for tests.
  final withdrawn = <int>[];

  bool granted = true;

  /// Times the permission was asked for, for tests.
  int permissionRequests = 0;

  @override
  Future<void> init({
    required void Function(NotificationTap tap) onTap,
  }) async {}

  @override
  Future<NotificationTap?> launchTap() async => null;

  @override
  Future<void> replace(List<PlannedNotification> plan) async =>
      this.plan = plan;

  @override
  Future<void> withdraw(List<int> ids) async => withdrawn.addAll(ids);

  @override
  Future<bool> enabled() async => granted;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<void> openSettings() async {}

  bool exact = false;

  /// Times the exact-alarm page was opened, for tests.
  int exactRequests = 0;

  @override
  Future<bool> exactAllowed() async => exact;

  @override
  Future<void> requestExact() async => exactRequests++;
}

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => LocalNotificationScheduler(),
);
