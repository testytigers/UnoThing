import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/core/utils/duration_format.dart';
import 'package:the_one_thing/domain/models/day_status.dart';
import 'package:the_one_thing/features/onboarding/frame_06_contract.dart';
import 'package:the_one_thing/features/session/session_copy.dart';
import 'package:the_one_thing/widgets/mascot/mascot.dart';

void main() {
  group('live session line', () {
    String line(int s, {bool running = true}) =>
        liveSessionLine(seconds: s, targetSeconds: 1500, running: running);

    test('counts down to the safety net', () {
      expect(line(0), 'Every pour starts with one drop.');
      expect(line(48), '4:12 to save the day.');
    });

    test('celebrates the save, then counts down to a full cup', () {
      expect(line(300), 'Day saved. Everything now is a bonus.');
      expect(line(600), '15:00 to a full cup.');
      expect(line(1400), 'Almost full. Stay with it.');
      expect(line(1500), 'Cup full. Keep going if you like.');
    });

    test('paused wins over everything', () {
      expect(line(700, running: false), 'Paused. Your cup is waiting.');
    });

    test('hours show as h:mm:ss', () {
      expect(
        liveSessionLine(seconds: 400, targetSeconds: 7600, running: true),
        '2:00:00 to a full cup.',
      );
    });
  });

  test('banked today line follows the cup', () {
    expect(
      bankedTodayLine(seconds: 0, targetSeconds: 1200),
      "Today's cup is empty. Pour the first drop.",
    );
    expect(
      bankedTodayLine(seconds: 133, targetSeconds: 1200),
      '2:47 more saves the day.',
    );
    expect(
      bankedTodayLine(seconds: 306, targetSeconds: 1200),
      'Day saved. 14:54 more fills the cup.',
    );
    expect(
      bankedTodayLine(seconds: 1200, targetSeconds: 1200),
      'Full cup today. Anything more is a bonus.',
    );
  });

  test('shelf line speaks to today', () {
    String line(
      DayStatus? s, {
      int seconds = 0,
      bool active = false,
      bool over = false,
    }) => shelfLine(
      todayStatus: s,
      todaySeconds: seconds,
      sessionActive: active,
      horizonOver: over,
    );
    expect(line(DayStatus.pending), "Today's cup is empty.");
    expect(
      line(DayStatus.pending, seconds: 30),
      'A few more minutes and today is safe.',
    );
    expect(line(DayStatus.saved), 'Day saved. Top it up to your goal?');
    expect(line(DayStatus.targetReached), 'Cup full today. Well done.');
    expect(line(DayStatus.rest), 'Rest day. See you tomorrow.');
    expect(line(DayStatus.pending, active: true), "You're pouring right now.");
    expect(line(null, over: true), 'Horizon complete. Look how far you came.');
  });

  test('banked toast', () {
    expect(bankedToast(306), '+5:06 saved to today.');
    expect(bankedToast(0), 'Saved to today.');
  });

  test('pact rhythm phrase', () {
    expect(rhythmPhrase({1, 2, 3, 4, 5, 6, 7}), 'every single day');
    expect(rhythmPhrase({1, 2, 3, 4, 5}), 'every weekday');
    expect(rhythmPhrase({6, 7}), 'every weekend');
    expect(rhythmPhrase({3}), 'one day a week');
    expect(rhythmPhrase({1, 3, 5}), '3 days a week');
  });

  test('timer: mm:ss under an hour, h:mm:ss after', () {
    expect(formatTimer(0), '00:00');
    expect(formatTimer(306), '05:06');
    expect(formatTimer(3599), '59:59');
    expect(formatTimer(3600), '1:00:00');
    expect(formatTimer(45296), '12:34:56');
  });

  test('spoken durations', () {
    expect(formatSpokenDuration(25 * 60), '25 minutes');
    expect(formatSpokenDuration(60), '1 minute');
    expect(formatSpokenDuration(3600), '1 hour');
    expect(formatSpokenDuration(5400), '1 hour 30 minutes');
    expect(formatSpokenDuration(7200 + 60), '2 hours 1 minute');
  });

  group('mascot moods', () {
    MascotMood live(int s, {bool running = true}) =>
        liveSessionMood(seconds: s, targetSeconds: 1500, running: running);

    test('watches the drops, cheers the save, shades on at a full cup', () {
      expect(live(0), MascotMood.focus);
      expect(live(299), MascotMood.focus);
      expect(live(300), MascotMood.happy);
      expect(live(1499), MascotMood.happy);
      expect(live(1500), MascotMood.cool);
      expect(live(900, running: false), MascotMood.idle);
    });

    test('banked today follows the cup', () {
      MascotMood banked(int s) =>
          bankedTodayMood(seconds: s, targetSeconds: 1500);
      expect(banked(0), MascotMood.idle);
      expect(banked(120), MascotMood.idle);
      expect(banked(306), MascotMood.happy);
      expect(banked(1600), MascotMood.cool);
    });

    test('shelf: asleep on rest days, sparkling at the end', () {
      MascotMood shelf(
        DayStatus? s, {
        bool active = false,
        bool over = false,
      }) => shelfMood(todayStatus: s, sessionActive: active, horizonOver: over);
      expect(shelf(DayStatus.pending), MascotMood.idle);
      expect(shelf(DayStatus.saved), MascotMood.happy);
      expect(shelf(DayStatus.targetReached), MascotMood.cool);
      expect(shelf(DayStatus.rest), MascotMood.sleepy);
      expect(shelf(DayStatus.pending, active: true), MascotMood.focus);
      expect(shelf(DayStatus.rest, over: true), MascotMood.sparkle);
    });
  });
}
