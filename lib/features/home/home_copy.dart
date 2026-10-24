import '../../widgets/mascot/mascot.dart';

/// What the mascot says over the habits on Home, and how it feels.
({String text, MascotMood mood}) homeLine({
  required int pourToday,
  required int savedToday,
  required String? pouringInto,
  required bool allOver,
  bool paused = false,
}) {
  if (pouringInto != null && paused) {
    return (
      text: '$pouringInto is paused. Ready when you are.',
      mood: MascotMood.idle,
    );
  }
  if (pouringInto != null) {
    return (
      text: 'Pouring into $pouringInto. Stay with it.',
      mood: MascotMood.focus,
    );
  }
  if (allOver) {
    return (
      text: 'Horizon complete. Look how far you came.',
      mood: MascotMood.sparkle,
    );
  }
  if (pourToday == 0) {
    return (text: 'Rest day. See you tomorrow.', mood: MascotMood.sleepy);
  }
  if (savedToday >= pourToday) {
    return (
      text: pourToday == 1
          ? 'Today is saved. Well done.'
          : 'Every cup saved today. Legend.',
      mood: MascotMood.cool,
    );
  }
  if (savedToday > 0) {
    return (
      text: '$savedToday of $pourToday saved today. Keep going!',
      mood: MascotMood.happy,
    );
  }
  return (
    text: pourToday == 1
        ? "Today's cup is waiting."
        : "Today's $pourToday cups are waiting.",
    mood: MascotMood.idle,
  );
}
