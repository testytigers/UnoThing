import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/domain/models/goal.dart';

Goal _goal(LocalDate start, int months) => Goal(
  id: 1,
  title: 'x',
  horizonMonths: months,
  dailyTargetSeconds: 1500,
  activeWeekdays: const {1, 2, 3, 4, 5, 6, 7},
  startDate: start,
);

void main() {
  group('horizon length for every option (start 2026-12-06)', () {
    const start = LocalDate(2026, 12, 6);
    final cases = <int, (LocalDate, int)>{
      1: (const LocalDate(2027, 1, 5), 31),
      3: (const LocalDate(2027, 3, 5), 90),
      6: (const LocalDate(2027, 6, 5), 182),
      9: (const LocalDate(2027, 9, 5), 274),
      12: (const LocalDate(2027, 12, 5), 365),
    };
    cases.forEach((months, expected) {
      test('$months months', () {
        final g = _goal(start, months);
        expect(g.endDate, expected.$1);
        expect(g.totalDays, expected.$2);
      });
    });

    test('12 months across a leap year has 366 days', () {
      final g = _goal(const LocalDate(2027, 6, 1), 12);
      expect(g.endDate, const LocalDate(2028, 5, 31));
      expect(g.totalDays, 366);
    });
  });

  group('month-end start dates clamp to the target month', () {
    test('Jan 31 + 1 month = Feb 28, end Feb 27 (non-leap)', () {
      expect(
        const LocalDate(2027, 1, 31).addMonths(1),
        const LocalDate(2027, 2, 28),
      );
      final g = _goal(const LocalDate(2027, 1, 31), 1);
      expect(g.endDate, const LocalDate(2027, 2, 27));
      expect(g.totalDays, 28);
    });

    test('Jan 31 + 1 month = Feb 29 in a leap year, end Feb 28', () {
      final g = _goal(const LocalDate(2028, 1, 31), 1);
      expect(g.endDate, const LocalDate(2028, 2, 28));
      expect(g.totalDays, 29);
    });

    test('Aug 31 + 3 months = Nov 30, end Nov 29', () {
      expect(
        _goal(const LocalDate(2026, 8, 31), 3).endDate,
        const LocalDate(2026, 11, 29),
      );
    });

    test('Mar 31 + 6 months = Sep 30, end Sep 29', () {
      expect(
        _goal(const LocalDate(2027, 3, 31), 6).endDate,
        const LocalDate(2027, 9, 29),
      );
    });

    test('May 31 + 9 months = Feb 29 2028, end Feb 28', () {
      expect(
        _goal(const LocalDate(2027, 5, 31), 9).endDate,
        const LocalDate(2028, 2, 28),
      );
    });

    test('Feb 29 + 12 months = Feb 28, end Feb 27', () {
      expect(
        _goal(const LocalDate(2028, 2, 29), 12).endDate,
        const LocalDate(2029, 2, 27),
      );
    });

    test('Dec 31 + 1 month rolls the year', () {
      expect(
        _goal(const LocalDate(2026, 12, 31), 1).endDate,
        const LocalDate(2027, 1, 30),
      );
    });
  });

  group('LocalDate basics', () {
    test('weekday is Monday = 1', () {
      expect(const LocalDate(2026, 12, 7).weekday, 1);
      expect(const LocalDate(2026, 12, 13).weekday, 7);
    });

    test('startOfWeek is Monday', () {
      expect(
        const LocalDate(2026, 12, 13).startOfWeek,
        const LocalDate(2026, 12, 7),
      );
      expect(
        const LocalDate(2026, 12, 7).startOfWeek,
        const LocalDate(2026, 12, 7),
      );
    });

    test('addDays crosses DST without drifting', () {
      // EU DST ends 2026-10-25, US 2026-11-01.
      expect(
        const LocalDate(2026, 10, 24).addDays(2),
        const LocalDate(2026, 10, 26),
      );
      expect(
        const LocalDate(2026, 10, 31).addDays(2),
        const LocalDate(2026, 11, 2),
      );
    });

    test('ISO round trip and ordering', () {
      const d = LocalDate(2027, 3, 5);
      expect(d.toIso(), '2027-03-05');
      expect(LocalDate.parse('2027-03-05'), d);
      expect(d.isBefore(d.addDays(1)), isTrue);
      expect(d.daysUntil(d.addDays(-3)), -3);
    });
  });
}
