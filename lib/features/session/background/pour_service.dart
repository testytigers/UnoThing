import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/duration_format.dart';
import 'pour_notification.dart';
import 'pour_task_handler.dart';

/// Keeps a session alive and visible outside the app: a foreground service
/// with an ongoing notification. Faked in tests.
abstract interface class PourService {
  /// Whether the service is running (so it owns the safety-net alert).
  bool get isActive;

  /// Asks for the notification permission once (first session start).
  Future<void> ensurePermission();

  /// Starts the service for a session, if it is not running yet.
  Future<void> start({required String goalTitle, required int seconds});

  Future<void> stop();

  /// Messages from the service isolate ([PourMessage]).
  void listen(void Function(String message) onMessage);
}

class ForegroundPourService implements PourService {
  ForegroundPourService() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'pouring',
        channelName: 'Pouring',
        channelDescription: 'Shows your running session and its time.',
        onlyAlertOnce: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        allowWakeLock: true,
        // Keep pouring when the app is swiped away; the UI restores on open.
        stopWithTask: false,
      ),
    );
  }

  static const _serviceId = 1771;
  bool _active = false;
  bool _asked = false;

  @override
  bool get isActive => _active;

  @override
  Future<void> ensurePermission() async {
    if (_asked) return;
    _asked = true;
    try {
      final status = await FlutterForegroundTask.checkNotificationPermission();
      if (status != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } on Object catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  @override
  Future<void> start({required String goalTitle, required int seconds}) async {
    if (await FlutterForegroundTask.isRunningService) {
      _active = true;
      return;
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.specialUse],
      notificationTitle: '$goalTitle · ${formatTimer(seconds)}',
      notificationText: 'Pouring…',
      notificationIcon: NotificationIcon(
        metaDataName: 'io.passionatetalents.the_one_thing.POUR_ICON',
        backgroundColor: AppTokens.light.brand,
      ),
      notificationButtons: pourButtons(running: true),
      callback: pourServiceCallback,
    );
    _active = result is ServiceRequestSuccess;
    if (!_active) debugPrint('Pour service did not start: $result');
  }

  @override
  Future<void> stop() async {
    _active = false;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  void listen(void Function(String message) onMessage) {
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is String) onMessage(data);
    });
  }
}

/// No service: used in tests and wherever background work is unavailable.
class NoopPourService implements PourService {
  @override
  bool get isActive => false;

  @override
  Future<void> ensurePermission() async {}

  @override
  Future<void> start({required String goalTitle, required int seconds}) async {}

  @override
  Future<void> stop() async {}

  @override
  void listen(void Function(String message) onMessage) {}
}

final pourServiceProvider = Provider<PourService>(
  (ref) => ForegroundPourService(),
);
