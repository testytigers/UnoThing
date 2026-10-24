import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/domain/models/active_session.dart';
import 'package:the_one_thing/domain/models/goal.dart';
import 'package:the_one_thing/features/notifications/app_channels.dart';
import 'package:the_one_thing/features/notifications/reminder_planner.dart';

// Wed 9 Dec 2026, 10:00.
final now = DateTime(2026, 12, 9, 10);
const today = LocalDate(2026, 12, 9);

Goal goal({
  int id = 1,
  String title = 'Learn Judo',
  Set<int> days = const {1, 2, 3, 4, 5},
  int? reminder = 19 * 60,
  LocalDate start = const LocalDate(2026, 12, 1),
  int months = 3,
}) => Goal(
  id: id,
  title: title,
  horizonMonths: months,
  dailyTargetSeconds: 1500,
  activeWeekdays: days,
  startDate: start,
  reminderMinutes: reminder,
);

List<PlannedNotification> plan(
  List<Goal> goals, {
  Map<int, int> todaySeconds = const {},
  ActiveSession? session,
  bool lastCall = true,
  bool milestones = false,
  DateTime? at,
}) => planReminders(
  goals: goals,
  now: at ?? now,
  todaySeconds: todaySeconds,
  session: session,
  lastCall: lastCall,
  milestones: milestones,
);

Iterable<PlannedNotification> of(
  List<PlannedNotification> p,
  AppChannel channel,
) => p.where((n) => n.channel == channel);

void main() {
  group('daily reminder', () {
    test('at its time on each pour day of the next week', () {
      final daily = of(
        plan([goal()], lastCall: false),
        AppChannel.dailyReminders,
      );
      // Wed 9 .. Tue 15 Dec, weekdays only: 9, 10, 11, 14, 15.
      expect(daily.map((n) => n.at), [
        DateTime(2026, 12, 9, 19),
        DateTime(2026, 12, 10, 19),
        DateTime(2026, 12, 11, 19),
        DateTime(2026, 12, 14, 19),
        DateTime(2026, 12, 15, 19),
      ]);
      expect(daily.first.title, 'Learn Judo');
      expect(daily.first.payload, NotificationPayload.goal(1));
      expect(daily.first.startAction, isTrue);
    });

    test('none when switched off', () {
      expect(plan([goal(reminder: null)], lastCall: false), isEmpty);
    });

    test("skips today once today is saved, but not tomorrow", () {
      final daily = of(
        plan([goal()], todaySeconds: {1: 300}, lastCall: false),
        AppChannel.dailyReminders,
      );
      expect(daily.first.at, DateTime(2026, 12, 10, 19));
    });

    test('still comes today with less than the safety net', () {
      final daily = of(
        plan([goal()], todaySeconds: {1: 299}, lastCall: false),
        AppChannel.dailyReminders,
      );
      expect(daily.first.at, DateTime(2026, 12, 9, 19));
    });

    test('skips today while that goal is pouring', () {
      final session = ActiveSession(
        goalId: 1,
        date: today,
        baseSeconds: 0,
        segmentStartedAt: now,
        accumulatedSeconds: 0,
        safetyNetFired: false,
      );
      final daily = of(
        plan([goal()], session: session, lastCall: false),
        AppChannel.dailyReminders,
      );
      expect(daily.first.at, DateTime(2026, 12, 10, 19));
    });

    test('skips a time that has already passed today', () {
      final daily = of(
        plan([goal()], at: DateTime(2026, 12, 9, 19, 1), lastCall: false),
        AppChannel.dailyReminders,
      );
      expect(daily.first.at, DateTime(2026, 12, 10, 19));
    });

    test('never before the start or after the end of the horizon', () {
      final starts = goal(start: const LocalDate(2026, 12, 14));
      expect(
        of(
          plan([starts], lastCall: false),
          AppChannel.dailyReminders,
        ).map((n) => n.at.day),
        [14, 15],
      );
      final ends = goal(start: const LocalDate(2026, 11, 11), months: 1);
      // Ends Thu 10 Dec.
      expect(
        of(
          plan([ends], lastCall: false),
          AppChannel.dailyReminders,
        ).map((n) => n.at.day),
        [9, 10],
      );
    });

    test('ids are stable per goal and day', () {
      final daily = of(
        plan([goal(id: 7)], lastCall: false),
        AppChannel.dailyReminders,
      );
      expect(daily.first.id, ReminderIds.daily(7, 0));
      expect(daily.map((n) => n.id).toSet(), hasLength(daily.length));
    });
  });

  group('last call', () {
    test('at 9 PM on each day a goal still needs saving', () {
      final calls = of(plan([goal(reminder: null)]), AppChannel.lastCall);
      expect(calls.first.at, DateTime(2026, 12, 9, 21));
      expect(calls.first.title, 'Last call for Learn Judo');
      expect(calls.first.startAction, isTrue);
      expect(calls, hasLength(5));
    });

    test('not today once every goal is saved', () {
      final calls = of(
        plan([goal(reminder: null)], todaySeconds: {1: 400}),
        AppChannel.lastCall,
      );
      expect(calls.first.at, DateTime(2026, 12, 10, 21));
    });

    test('names every goal that still needs saving, in one notification', () {
      final calls = of(
        plan(
          [
            goal(reminder: null),
            goal(
              id: 2,
              title: 'Read',
              reminder: null,
              days: {1, 2, 3, 4, 5, 6, 7},
            ),
            goal(id: 3, title: 'Piano', reminder: null),
          ],
          todaySeconds: {3: 600},
        ),
        AppChannel.lastCall,
      );
      final first = calls.first;
      expect(first.title, 'Last call');
      expect(first.body, 'Learn Judo and Read still need 5 minutes each.');
      expect(first.startAction, isFalse);
      // Saturday 12: only Read pours.
      final saturday = calls.firstWhere((n) => n.at.day == 12);
      expect(saturday.title, 'Last call for Read');
    });

    test('none when switched off', () {
      expect(
        of(plan([goal(reminder: null)], lastCall: false), AppChannel.lastCall),
        isEmpty,
      );
    });
  });

  group('milestones', () {
    test('halfway, the final week and the last day, in the morning', () {
      // 1 Dec + 3 months: ends 28 Feb, 90 days.
      final m = of(
        plan([goal(reminder: null)], lastCall: false, milestones: true),
        AppChannel.milestones,
      ).toList();
      expect(m.map((n) => n.at), [
        DateTime(2027, 1, 15, 9),
        DateTime(2027, 2, 22, 9),
        DateTime(2027, 2, 28, 9),
      ]);
      expect(m.map((n) => n.title), [
        'Halfway there!',
        'Final week',
        'Last day',
      ]);
    });

    test('only those still ahead', () {
      final late = goal(
        reminder: null,
        start: const LocalDate(2026, 10, 1),
      ); // ends 31 Dec; halfway 15 Nov has passed
      final m = of(
        plan([late], lastCall: false, milestones: true),
        AppChannel.milestones,
      );
      expect(m.map((n) => n.title), ['Final week', 'Last day']);
    });

    test('a one-month pact gets all three', () {
      final short = goal(
        reminder: null,
        start: const LocalDate(2026, 12, 9),
        months: 1,
      );
      final m = of(
        plan([short], lastCall: false, milestones: true),
        AppChannel.milestones,
      );
      expect(m.map((n) => n.title), [
        'Halfway there!',
        'Final week',
        'Last day',
      ]);
    });

    test('none when switched off', () {
      expect(plan([goal(reminder: null)], lastCall: false), isEmpty);
    });
  });

  test('the plan is in time order', () {
    final p = plan([goal()], milestones: true);
    final times = p.map((n) => n.at).toList();
    expect(times, [...times]..sort());
  });

  test('last call lists three goals with commas', () {
    expect(
      lastCallBody(['A', 'B', 'C']),
      'A, B and C still need 5 minutes each.',
    );
  });
}
