import '../../core/time/local_date.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/goal.dart' show horizonEndDate;
import '../../widgets/mascot/mascot.dart';
import 'frame_03_horizon.dart' show horizonPromise;
import 'frame_06_contract.dart' show rhythmPhrase;
import 'onboarding_controller.dart';

/// What the mascot says, and how it feels saying it.
typedef Guide = ({String message, MascotMood mood});

/// Days from [today] to the end of a [months] horizon that fall on
/// [weekdays] (Mon=1).
int pourDays(LocalDate today, int months, Set<int> weekdays) {
  final end = horizonEndDate(today, months);
  var count = 0;
  for (var d = today; !d.isAfter(end); d = d.addDays(1)) {
    if (weekdays.contains(d.weekday)) count++;
  }
  return count;
}

/// "45 minutes" under two hours, else "38 hours".
String totalPhrase(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes < 120) return '$minutes minutes';
  return '${(minutes / 60).round()} hours';
}

/// The whole pact as time: "about 38 hours of Learn Judo by 20 Jan", or
/// null until the pact is complete enough to count.
String? pactTotal(OnboardingDraft draft, LocalDate today) {
  if (!draft.horizonValid || !draft.targetValid || !draft.daysValid) {
    return null;
  }
  final months = draft.horizonMonths!;
  final seconds =
      pourDays(today, months, draft.activeWeekdays) * draft.dailyTargetSeconds;
  final goal = draft.title.trim();
  final of = goal.isNotEmpty && goal.length <= 22 ? ' of $goal' : '';
  return 'about ${totalPhrase(seconds)}$of by '
      '${shortDate(horizonEndDate(today, months))}';
}

/// Step 1: hello (or, for another goal, a nod to the ambition), then a
/// cheer for the goal being typed.
Guide goalGuide(String title, {bool adding = false}) {
  final goal = title.trim();
  if (goal.isEmpty && adding) {
    return (
      message: 'Another thing? I like the ambition. What is it?',
      mood: MascotMood.sparkle,
    );
  }
  if (goal.isEmpty) {
    return (
      message:
          "Hi! I'll be with you every day. Let's start with your one "
          'thing.',
      mood: MascotMood.idle,
    );
  }
  final short = goal.length > 26 ? '${goal.substring(0, 25)}…' : goal;
  return (message: '"$short". Love it!', mood: MascotMood.happy);
}

/// Step 2: how long. Each horizon has its promise.
Guide horizonGuide(OnboardingDraft draft) {
  final months = draft.horizonMonths;
  if (months == null) {
    return (
      message:
          'How long is our pact? Long enough to change you, short enough '
          'to see the finish line.',
      mood: MascotMood.idle,
    );
  }
  return (
    message: horizonPromise(months),
    mood: months >= 12
        ? MascotMood.cool
        : months >= 6
        ? MascotMood.sparkle
        : MascotMood.happy,
  );
}

/// Step 3: how much each day, and what it adds up to.
Guide targetGuide(
  OnboardingDraft draft,
  LocalDate today, {
  required bool touched,
}) {
  if (!touched) {
    return (
      message: 'How much will you pour each day? Even 10 minutes adds up.',
      mood: MascotMood.idle,
    );
  }
  if (!draft.targetValid) {
    return (message: "Hmm, that won't fit in a cup.", mood: MascotMood.wow);
  }
  final minutes = draft.dailyTargetSeconds ~/ 60;
  final (lead, mood) = minutes <= 10
      ? ('Small and steady!', MascotMood.happy)
      : minutes <= 25
      ? ('A sweet spot!', MascotMood.happy)
      : minutes <= 60
      ? ('Solid!', MascotMood.sparkle)
      : ('Whoa, ambitious!', MascotMood.wow);
  final total = pactTotal(draft, today);
  return (message: total == null ? lead : "$lead That's $total.", mood: mood);
}

/// Step 4: which days, and what they add up to.
Guide daysGuide(
  OnboardingDraft draft,
  LocalDate today, {
  required bool touched,
}) {
  if (!draft.daysValid) {
    return (
      message: 'I need at least one day to pour into!',
      mood: MascotMood.sad,
    );
  }
  if (!touched) {
    return (
      message:
          'Which days will you pour? Rest days never spill, so pick '
          'what you can keep.',
      mood: MascotMood.idle,
    );
  }
  final days = draft.activeWeekdays;
  final String lead;
  var mood = MascotMood.happy;
  if (days.length == 7) {
    lead = 'Every single day? Respect.';
    mood = MascotMood.cool;
  } else if (days.length == 5 && days.containsAll({1, 2, 3, 4, 5})) {
    lead = 'Weekdays on, weekends off. Smart.';
  } else if (days.length == 2 && days.containsAll({6, 7})) {
    lead = 'Weekends it is.';
  } else {
    final rhythm = rhythmPhrase(days);
    lead = '${rhythm[0].toUpperCase()}${rhythm.substring(1)}. Nice rhythm.';
  }
  final total = pactTotal(draft, today);
  return (message: total == null ? lead : "$lead That's $total.", mood: mood);
}

/// Step 5: calm while reading, shades on once committed.
Guide contractGuide({required bool committed}) => committed
    ? (message: "That's the spirit. Let's do this!", mood: MascotMood.cool)
    : (message: 'Read it once. Mean it. Then seal it.', mood: MascotMood.idle);
