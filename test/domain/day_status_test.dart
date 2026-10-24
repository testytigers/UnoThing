import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/domain/models/day_status.dart';
import 'package:the_one_thing/domain/models/goal.dart';
import 'package:the_one_thing/domain/services/day_status_service.dart';

void main() {
  // Mon 2026-12-07 .. ; weekdays Mon-Fri active, 25 min target.
  final goal = Goal(
    id: 1,
    title: 'Learn Judo',
    horizonMonths: 3,
    dailyTargetSeconds: 25 * 60,
    activeWeekdays: const {1, 2, 3, 4, 5},
    startDate: const LocalDate(2026, 12, 1),
  );
  const today = LocalDate(2026, 12, 9); // Wednesday
  const yesterday = LocalDate(2026, 12, 8); // Tuesday
  const saturday = LocalDate(2026, 12, 5);

  DayStatus status(LocalDate d, int s) => dayStatus(d, s, goal, today);

  group('status table', () {
    test('date after today is FUTURE', () {
      expect(status(today.addDays(1), 0), DayStatus.future);
    });

    test('future wins over any banked time', () {
      expect(status(today.addDays(1), 9999), DayStatus.future);
    });

    test('non-active weekday is REST (D2)', () {
      expect(status(saturday, 0), DayStatus.rest);
    });

    test('rest is never SPILLED, even in the past with 0 seconds', () {
      expect(status(saturday, 0), isNot(DayStatus.spilled));
    });

    test('total >= daily target is TARGET_REACHED', () {
      expect(status(yesterday, 25 * 60), DayStatus.targetReached);
      expect(status(today, 25 * 60 + 1), DayStatus.targetReached);
    });

    test('total >= 300 and below target is SAVED', () {
      expect(status(yesterday, 300), DayStatus.saved);
      expect(status(today, 25 * 60 - 1), DayStatus.saved);
    });

    test('today below 300 is PENDING', () {
      expect(status(today, 0), DayStatus.pending);
      expect(status(today, 299), DayStatus.pending);
    });

    test('past active day below 300 is SPILLED', () {
      expect(status(yesterday, 0), DayStatus.spilled);
    });

    test('past active day with 1..299 seconds is SPILLED (D1)', () {
      expect(status(yesterday, 1), DayStatus.spilled);
      expect(status(yesterday, 299), DayStatus.spilled);
    });

    test('target equal to the safety net reaches target at 300', () {
      final g = Goal(
        id: 1,
        title: 'x',
        horizonMonths: 1,
        dailyTargetSeconds: 300,
        activeWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        startDate: const LocalDate(2026, 12, 1),
      );
      expect(dayStatus(yesterday, 300, g, today), DayStatus.targetReached);
    });
  });

  group('outside the horizon (D7)', () {
    test('before startDate', () {
      expect(
        status(const LocalDate(2026, 11, 30), 0),
        DayStatus.outsideHorizon,
      );
    });

    test('after endDate', () {
      expect(status(goal.endDate.addDays(1), 0), DayStatus.outsideHorizon);
    });

    test('startDate and endDate are inside', () {
      expect(status(goal.startDate, 0), isNot(DayStatus.outsideHorizon));
      expect(status(goal.endDate, 0), DayStatus.future);
    });
  });
}
