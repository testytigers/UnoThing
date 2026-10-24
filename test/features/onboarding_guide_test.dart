import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/core/time/local_date.dart';
import 'package:the_one_thing/features/onboarding/onboarding_controller.dart';
import 'package:the_one_thing/features/onboarding/onboarding_guide.dart';
import 'package:the_one_thing/widgets/mascot/mascot.dart';

const today = LocalDate(2026, 12, 6); // a Sunday

OnboardingDraft draft({
  int? months = 3,
  int targetMinutes = 25,
  Set<int> days = const {1, 2, 3, 4, 5, 6, 7},
  String title = 'Learn Judo',
}) => OnboardingDraft(
  title: title,
  horizonMonths: months,
  targetHours: targetMinutes ~/ 60,
  targetMinutes: targetMinutes % 60,
  activeWeekdays: days,
);

void main() {
  test('step 1 says hello, then cheers the goal', () {
    expect(goalGuide('  ').mood, MascotMood.idle);
    expect(goalGuide('Learn Judo').message, '"Learn Judo". Love it!');
    expect(goalGuide('Learn Judo').mood, MascotMood.happy);
    expect(goalGuide('x' * 40).message, '"${'x' * 25}…". Love it!');
  });

  test('step 2: each horizon has its promise, bolder for longer', () {
    expect(horizonGuide(draft(months: null)).message, contains('How long'));
    expect(horizonGuide(draft()).message, 'A habit. Long enough to stick.');
    expect(horizonGuide(draft(months: 6)).mood, MascotMood.sparkle);
    expect(horizonGuide(draft(months: 12)).mood, MascotMood.cool);
  });

  group('the fun fact', () {
    test('counts only the pour days up to the finish line', () {
      // 6 Dec 2026 .. 5 Mar 2027 = 90 days: 12 weeks + Sun..Fri, so 65
      // weekdays.
      expect(pourDays(today, 3, {1, 2, 3, 4, 5, 6, 7}), 90);
      expect(pourDays(today, 3, {1, 2, 3, 4, 5}), 65);
    });

    test('in hours, or minutes when small', () {
      expect(totalPhrase(90 * 25 * 60), '38 hours');
      expect(totalPhrase(5 * 10 * 60), '50 minutes');
    });

    test('names the goal when it is short', () {
      expect(
        pactTotal(draft(), today),
        'about 38 hours of Learn Judo by 5 Mar',
      );
      expect(
        pactTotal(draft(title: 'Write the novel I keep talking about'), today),
        'about 38 hours by 5 Mar',
      );
      expect(pactTotal(draft(months: null), today), isNull);
    });
  });

  test('step 3: the amount, and what it adds up to', () {
    Guide g(int m) =>
        targetGuide(draft(targetMinutes: m), today, touched: true);
    expect(
      targetGuide(draft(), today, touched: false).message,
      'How much will you pour each day? Even 10 minutes adds up.',
    );
    expect(
      g(10).message,
      "Small and steady! That's about 15 hours of Learn "
      'Judo by 5 Mar.',
    );
    expect(g(45).mood, MascotMood.sparkle);
    expect(g(90).mood, MascotMood.wow);
    expect(g(4).message, "Hmm, that won't fit in a cup.");
  });

  test('step 4: the days, and no days at all wins over everything', () {
    Guide g(Set<int> d) => daysGuide(draft(days: d), today, touched: true);
    expect(g({1, 2, 3, 4, 5, 6, 7}).mood, MascotMood.cool);
    expect(
      g({1, 2, 3, 4, 5}).message,
      "Weekdays on, weekends off. Smart. That's about 27 hours of Learn Judo "
      'by 5 Mar.',
    );
    expect(g({6, 7}).message, startsWith('Weekends it is.'));
    expect(g({1, 3, 5}).message, startsWith('3 days a week. Nice rhythm.'));
    expect(
      daysGuide(draft(days: {}), today, touched: false).mood,
      MascotMood.sad,
    );
  });

  test('step 5: shades on once committed', () {
    expect(contractGuide(committed: false).mood, MascotMood.idle);
    expect(contractGuide(committed: true).mood, MascotMood.cool);
  });
}
