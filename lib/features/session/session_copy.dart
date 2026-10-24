import '../../core/constants.dart';
import '../../domain/models/day_status.dart';
import '../../widgets/mascot/mascot.dart';

/// `4:12` or `1:04:12`: compact countdowns inside sentences.
String _clock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = s % 3600 ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
}

/// The coach line under the live timer (Frame 8).
String liveSessionLine({
  required int seconds,
  required int targetSeconds,
  required bool running,
}) {
  if (!running) return 'Paused. Your cup is waiting.';
  if (seconds == 0) return 'Every pour starts with one drop.';
  if (seconds < safetyNetSeconds) {
    return '${_clock(safetyNetSeconds - seconds)} to save the day.';
  }
  if (seconds >= targetSeconds) return 'Cup full. Keep going if you like.';
  if (seconds < safetyNetSeconds + 60) {
    return 'Day saved. Everything now is a bonus.';
  }
  final left = targetSeconds - seconds;
  if (left <= 120) return 'Almost full. Stay with it.';
  return '${_clock(left)} to a full cup.';
}

/// The mascot beside [liveSessionLine]: watching the drops, then happy once
/// the day is saved, shades on at a full cup.
MascotMood liveSessionMood({
  required int seconds,
  required int targetSeconds,
  required bool running,
}) {
  if (!running) return MascotMood.idle;
  if (seconds >= targetSeconds) return MascotMood.cool;
  if (seconds >= safetyNetSeconds) return MascotMood.happy;
  return MascotMood.focus;
}

/// Frame 11: the timer is paused, three choices.
const stopSessionLine = 'Nice pour. Save it to today?';

/// Frame 12: today's cup after banking.
String bankedTodayLine({required int seconds, required int targetSeconds}) {
  if (seconds >= targetSeconds) {
    return 'Full cup today. Anything more is a bonus.';
  }
  if (seconds >= safetyNetSeconds) {
    return 'Day saved. ${_clock(targetSeconds - seconds)} more fills the cup.';
  }
  if (seconds == 0) return "Today's cup is empty. Pour the first drop.";
  return '${_clock(safetyNetSeconds - seconds)} more saves the day.';
}

/// The mascot beside [bankedTodayLine].
MascotMood bankedTodayMood({required int seconds, required int targetSeconds}) {
  if (seconds >= targetSeconds) return MascotMood.cool;
  if (seconds >= safetyNetSeconds) return MascotMood.happy;
  return MascotMood.idle;
}

/// The line under today's cup on the Shelf.
String shelfLine({
  required DayStatus? todayStatus,
  required int todaySeconds,
  required bool sessionActive,
  required bool horizonOver,
}) {
  if (horizonOver) return 'Horizon complete. Look how far you came.';
  if (sessionActive) return "You're pouring right now.";
  return switch (todayStatus) {
    DayStatus.targetReached => 'Cup full today. Well done.',
    DayStatus.saved => 'Day saved. Top it up to your goal?',
    DayStatus.pending when todaySeconds > 0 =>
      'A few more minutes and today is safe.',
    DayStatus.pending => "Today's cup is empty.",
    DayStatus.rest => 'Rest day. See you tomorrow.',
    _ => 'One thing. Every day.',
  };
}

/// The line on another goal's page while one goal pours.
String pouringElsewhereLine(String goalTitle) =>
    "You're pouring into $goalTitle right now.";

/// The mascot beside [shelfLine].
MascotMood shelfMood({
  required DayStatus? todayStatus,
  required bool sessionActive,
  required bool horizonOver,
}) {
  if (horizonOver) return MascotMood.sparkle;
  if (sessionActive) return MascotMood.focus;
  return switch (todayStatus) {
    DayStatus.targetReached => MascotMood.cool,
    DayStatus.saved => MascotMood.happy,
    DayStatus.rest => MascotMood.sleepy,
    _ => MascotMood.idle,
  };
}

/// Toast after saving a session (Frame 10).
String bankedToast(int addedSeconds) {
  if (addedSeconds <= 0) return 'Saved to today.';
  return '+${_clock(addedSeconds)} saved to today.';
}

/// Toast when a save completes a week of pour days.
const weekCompleteToast = 'A full week saved! Keep it rolling.';

/// Banner when the safety net is crossed during a session.
const safetyNetBanner = 'Day saved. Nothing can spill it now.';
