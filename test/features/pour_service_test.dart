import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/clock.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/features/session/background/pour_notification.dart';
import 'package:the_one_thing/features/session/background/pour_service.dart';
import 'package:the_one_thing/features/session/session_controller.dart';

import '../helpers/app_harness.dart';

/// Records calls; can pretend to be running so the app defers to it.
class FakePourService implements PourService {
  final calls = <String>[];
  void Function(String)? _onMessage;
  bool active = false;

  @override
  bool get isActive => active;

  @override
  Future<void> ensurePermission() async => calls.add('permission');

  @override
  Future<void> start({required String goalTitle, required int seconds}) async {
    calls.add('start:$goalTitle:$seconds');
    active = true;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    active = false;
  }

  @override
  void listen(void Function(String message) onMessage) =>
      _onMessage = onMessage;

  void send(String message) => _onMessage?.call(message);
}

Future<void> seed(AppDatabase db) => GoalRepository(db).createGoal(
  title: 'Learn Judo',
  horizonMonths: 3,
  dailyTargetSeconds: 1500,
  activeWeekdays: {1, 2, 3, 4, 5},
  startDate: const LocalDate(2026, 12, 1),
);

void main() {
  group('notification content', () {
    test('running shows goal, time and the coach line', () {
      final c = pourNotificationContent(
        goalTitle: 'Learn Judo',
        seconds: 743,
        targetSeconds: 1500,
        running: true,
      );
      expect(c.title, 'Learn Judo · 12:23');
      expect(c.text, '12:37 to a full cup.');
    });

    test('below the safety net counts down to it', () {
      final c = pourNotificationContent(
        goalTitle: 'Learn Judo',
        seconds: 135,
        targetSeconds: 1500,
        running: true,
      );
      expect(c.text, '2:45 to save the day.');
    });

    test('paused', () {
      final c = pourNotificationContent(
        goalTitle: 'Learn Judo',
        seconds: 306,
        targetSeconds: 1500,
        running: false,
      );
      expect(c.title, 'Paused · 05:06');
      expect(c.text, 'Paused. Your cup is waiting.');
    });
  });

  testWidgets(
    'starting asks permission and starts the service; banking stops it',
    (tester) async {
      final pour = FakePourService();
      final clock = FakeClock(DateTime(2026, 12, 9, 10));
      var alerts = 0;
      await pumpApp(
        tester,
        start: Routes.shelf,
        clock: clock,
        seed: seed,
        pour: pour,
        overrides: [
          safetyNetAlertProvider.overrideWithValue(() async => alerts++),
        ],
      );
      await settleAsync(tester);

      await tester.tap(
        find.bySemanticsLabel('9 December, 0 minutes, today').first,
      );
      await settleAsync(tester, settle: false);
      expect(pour.calls, ['permission', 'start:Learn Judo:0']);

      // With the service running, the app leaves the safety net to it.
      clock.advance(const Duration(seconds: 310));
      await tester.pump(const Duration(seconds: 1));
      await settleAsync(tester, settle: false);
      expect(alerts, 0);

      await tester.tap(find.bySemanticsLabel('Finish'));
      await settleAsync(tester);
      await tester.tap(find.text('Save session'));
      await settleAsync(tester);
      expect(pour.calls.last, 'stop');
      await unmountApp(tester);
    },
  );

  testWidgets('Stop on the notification opens Frame 11', (tester) async {
    final pour = FakePourService();
    await pumpApp(
      tester,
      start: Routes.shelf,
      clock: FakeClock(DateTime(2026, 12, 9, 10)),
      seed: seed,
      pour: pour,
    );
    await settleAsync(tester);
    await tester.tap(
      find.bySemanticsLabel('9 December, 0 minutes, today').first,
    );
    await settleAsync(tester, settle: false);
    expect(location(tester), Routes.session);

    pour.send(PourMessage.stop);
    await settleAsync(tester, settle: false);
    await tester.pump(const Duration(seconds: 1));
    expect(location(tester), Routes.sessionStop);
    await unmountApp(tester);
  });
}
