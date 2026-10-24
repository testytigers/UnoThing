import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../../../app/routes.dart';
import '../../notifications/app_channels.dart';
import '../../../core/constants.dart';
import '../../../core/time/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../../domain/models/active_session.dart';
import '../../../domain/services/timer_engine.dart';
import '../session_copy.dart';
import 'pour_notification.dart';

/// Entry point of the foreground service isolate.
@pragma('vm:entry-point')
void pourServiceCallback() {
  FlutterForegroundTask.setTaskHandler(PourTaskHandler());
}

/// Runs in the foreground service, once a second. The database is the
/// source of truth: the handler reads the session, applies midnight
/// rollover, fires the safety net once, and keeps the notification current,
/// even when the app's UI is gone.
class PourTaskHandler extends TaskHandler {
  static const _safetyNetNotificationId = 41;
  static const _cupFullNotificationId = 42;

  AppDatabase? _db;
  TimerEngine? _engine;
  final _notifications = FlutterLocalNotificationsPlugin();
  bool _busy = false;
  bool? _lastRunning;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _db = AppDatabase();
    _engine = TimerEngine(db: _db!, clock: const SystemClock());
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_pour'),
      ),
    );
    await _tick();
  }

  @override
  void onRepeatEvent(DateTime timestamp) => unawaited(_tick());

  Future<void> _tick() async {
    final db = _db;
    final engine = _engine;
    if (_busy || db == null || engine == null) return;
    _busy = true;
    try {
      var session = await engine.reconcile();
      final goal = session == null
          ? null
          : await GoalRepository(db).getGoal(session.goalId);
      if (goal == null || session == null) {
        await FlutterForegroundTask.stopService();
        return;
      }
      final now = engine.clock.now();
      final value = session.valueAt(now);
      if (session.isRunning &&
          !session.safetyNetFired &&
          value >= safetyNetSeconds) {
        session = await engine.markSafetyNetFired(session);
        await _alert(
          id: _safetyNetNotificationId,
          title: safetyNetNotificationTitle,
          body: safetyNetBanner,
        );
        FlutterForegroundTask.sendDataToMain(PourMessage.changed);
      }
      if (session.isRunning &&
          !session.targetFired &&
          value >= goal.dailyTargetSeconds) {
        session = await engine.markTargetFired(session);
        await _alert(
          id: _cupFullNotificationId,
          title: cupFullNotificationTitle,
          body: cupFullNotificationBody(goal.title),
        );
        FlutterForegroundTask.sendDataToMain(PourMessage.changed);
      }
      await _render(goal.title, goal.dailyTargetSeconds, session, now);
    } on Object catch (e) {
      debugPrint('Pour service tick failed: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _render(
    String goalTitle,
    int target,
    ActiveSession session,
    DateTime now,
  ) async {
    final content = pourNotificationContent(
      goalTitle: goalTitle,
      seconds: session.valueAt(now),
      targetSeconds: target,
      running: session.isRunning,
    );
    final buttonsChanged = _lastRunning != session.isRunning;
    _lastRunning = session.isRunning;
    await FlutterForegroundTask.updateService(
      notificationTitle: content.title,
      notificationText: content.text,
      notificationButtons: buttonsChanged
          ? pourButtons(running: session.isRunning)
          : null,
    );
  }

  /// A session moment (safety net, cup full): a buzz, and outside the app a
  /// notification. In the app the screen celebrates it instead.
  Future<void> _alert({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(pattern: [0, 140, 90, 260]);
      }
    } on Object catch (e) {
      debugPrint('Vibration unavailable: $e');
    }
    if (await FlutterForegroundTask.isAppOnForeground) return;
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AppChannel.sessionMoments.details(),
      ),
      payload: NotificationPayload.open,
    );
  }

  @override
  Future<void> onNotificationButtonPressed(String id) async {
    final engine = _engine;
    final session = await engine?.current();
    if (engine == null || session == null) return;
    switch (id) {
      case PourAction.pause:
        await engine.pause(session);
      case PourAction.resume:
        await engine.resume(session);
      case PourAction.stop:
        await engine.pause(session);
        FlutterForegroundTask.sendDataToMain(PourMessage.stop);
        FlutterForegroundTask.launchApp(Routes.sessionStop);
    }
    FlutterForegroundTask.sendDataToMain(PourMessage.changed);
    await _tick();
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _db?.close();
    _db = null;
    _engine = null;
  }
}

/// Pause/Resume and Finish.
List<NotificationButton> pourButtons({required bool running}) => [
  running
      ? const NotificationButton(id: PourAction.pause, text: 'Pause')
      : const NotificationButton(id: PourAction.resume, text: 'Resume'),
  const NotificationButton(id: PourAction.stop, text: 'Finish'),
];
