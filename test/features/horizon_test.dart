import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/routes.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/data/db/app_database.dart';
import 'package:the_one_thing/data/repositories/goal_repository.dart';
import 'package:the_one_thing/domain/models/goal.dart';
import 'package:the_one_thing/features/horizon/frame_15_horizon.dart';

import '../helpers/app_harness.dart';

Goal _goal(LocalDate start, int months) => Goal(
  id: 1,
  title: 'x',
  horizonMonths: months,
  dailyTargetSeconds: 1500,
  activeWeekdays: const {1, 2, 3, 4, 5},
  startDate: start,
);

void main() {
  group('calendar cells', () {
    test('rows start on Monday; days before the start are blank', () {
      // Wed 2026-10-21 + 3 months -> ends Wed 2027-01-20.
      final cells = horizonCalendarCells(
        _goal(const LocalDate(2026, 10, 21), 3),
      );
      expect(cells.length % 7, 0);
      expect(cells.take(2), [null, null]); // Mon 19, Tue 20
      expect(cells[2], const LocalDate(2026, 10, 21));
      expect(cells[2]!.weekday, 3);
    });

    test('days after the end are blank to finish the last week', () {
      final cells = horizonCalendarCells(
        _goal(const LocalDate(2026, 10, 21), 3),
      );
      final last = cells.lastIndexWhere((c) => c != null);
      expect(cells[last], const LocalDate(2027, 1, 20));
      expect(cells.skip(last + 1), [null, null, null, null]); // Thu-Sun
    });

    test('every horizon day appears exactly once, in order', () {
      final goal = _goal(const LocalDate(2027, 1, 31), 12);
      final days = horizonCalendarCells(goal).whereType<LocalDate>().toList();
      expect(days.length, goal.totalDays);
      expect(days.first, goal.startDate);
      expect(days.last, goal.endDate);
      for (var i = 1; i < days.length; i++) {
        expect(days[i - 1].daysUntil(days[i]), 1);
      }
    });

    test('a horizon starting on Monday has no leading blanks', () {
      final cells = horizonCalendarCells(
        _goal(const LocalDate(2026, 12, 7), 1),
      );
      expect(cells.first, const LocalDate(2026, 12, 7));
    });
  });

  testWidgets('shows a pinned weekday header and Monday-aligned cups', (
    tester,
  ) async {
    await pumpApp(
      tester,
      start: Routes.horizon,
      now: DateTime(2026, 10, 21, 9),
      seed: (AppDatabase db) => GoalRepository(db).createGoal(
        title: 'Learn Judo',
        horizonMonths: 3,
        dailyTargetSeconds: 1200,
        activeWeekdays: {1, 2, 3, 4, 5},
        startDate: const LocalDate(2026, 10, 21),
      ),
    );
    await settleAsync(tester);

    expect(find.text('0/92 days'), findsOneWidget);
    for (final day in ['Monday', 'Wednesday', 'Sunday']) {
      expect(find.bySemanticsLabel(day), findsOneWidget);
    }
    final wednesday = tester.getCenter(find.bySemanticsLabel('Wednesday'));
    final firstCup = tester.getCenter(
      find.bySemanticsLabel('21 October, 0 minutes, today').first,
    );
    expect(firstCup.dx, closeTo(wednesday.dx, 1));
    await unmountApp(tester);
  });
}
