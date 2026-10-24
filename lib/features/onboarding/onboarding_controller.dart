import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/goal.dart';
import '../pro/pro.dart';

enum TargetError { belowSafetyNet, aboveMaximum }

/// Answers collected across the onboarding steps. Nothing is written to the
/// database until [OnboardingController.submit].
@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.title = '',
    this.horizonMonths,
    this.targetHours = 0,
    this.targetMinutes = 25,
    this.activeWeekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.committed = false,
    this.reminderMinutes = defaultReminderMinutes,
    this.adding = false,
  });

  final String title;
  final int? horizonMonths;
  final int targetHours;
  final int targetMinutes;
  final Set<int> activeWeekdays;
  final bool committed;

  /// Daily reminder, minutes after local midnight; null for none.
  final int? reminderMinutes;

  /// Adding another goal next to existing ones (Pro), not the first.
  final bool adding;

  int get dailyTargetSeconds => targetHours * 3600 + targetMinutes * 60;

  bool get titleValid {
    final trimmed = title.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxGoalTitleLength;
  }

  bool get horizonValid => horizonMonths != null;

  TargetError? get targetError {
    if (dailyTargetSeconds < minDailyTargetSeconds) {
      return TargetError.belowSafetyNet;
    }
    if (dailyTargetSeconds > maxDailyTargetSeconds) {
      return TargetError.aboveMaximum;
    }
    return null;
  }

  bool get targetValid => targetError == null;

  bool get daysValid => activeWeekdays.isNotEmpty;

  bool get complete =>
      titleValid && horizonValid && targetValid && daysValid && committed;

  OnboardingDraft copyWith({
    String? title,
    int? horizonMonths,
    int? targetHours,
    int? targetMinutes,
    Set<int>? activeWeekdays,
    bool? committed,
    int? Function()? reminderMinutes,
  }) {
    return OnboardingDraft(
      title: title ?? this.title,
      horizonMonths: horizonMonths ?? this.horizonMonths,
      targetHours: targetHours ?? this.targetHours,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      committed: committed ?? this.committed,
      reminderMinutes: reminderMinutes != null
          ? reminderMinutes()
          : this.reminderMinutes,
      adding: adding,
    );
  }
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void setTitle(String value) => state = state.copyWith(title: value);

  void setHorizon(int months) {
    assert(horizonMonthOptions.contains(months));
    state = state.copyWith(horizonMonths: months);
  }

  void setTargetHours(int hours) => state = state.copyWith(targetHours: hours);

  void setTargetMinutes(int minutes) =>
      state = state.copyWith(targetMinutes: minutes);

  void setTargetSeconds(int seconds) => state = state.copyWith(
    targetHours: seconds ~/ 3600,
    targetMinutes: seconds % 3600 ~/ 60,
  );

  void setWeekdays(Set<int> weekdays) =>
      state = state.copyWith(activeWeekdays: {...weekdays});

  void toggleWeekday(int weekday) {
    final days = {...state.activeWeekdays};
    if (!days.remove(weekday)) days.add(weekday);
    state = state.copyWith(activeWeekdays: days);
  }

  void setCommitted(bool value) => state = state.copyWith(committed: value);

  void setReminder(int? minutes) =>
      state = state.copyWith(reminderMinutes: () => minutes);

  /// A fresh draft for another goal next to the existing ones.
  void startNew() => state = const OnboardingDraft(adding: true);

  /// Signs the contract: saves the goal with startDate = today, shows it on
  /// the Shelf, then clears the draft. Refused past the goal limit (one, or
  /// three with Pro).
  Future<Goal> submit() async {
    final draft = state;
    if (!draft.complete) {
      throw StateError('Onboarding is incomplete');
    }
    final goals = ref.read(goalRepositoryProvider);
    final existing = await goals.getGoals();
    if (existing.length >= goalLimit(pro: ref.read(proProvider))) {
      throw StateError('Goal limit reached');
    }
    final goal = await goals.createGoal(
      title: draft.title.trim(),
      horizonMonths: draft.horizonMonths!,
      dailyTargetSeconds: draft.dailyTargetSeconds,
      activeWeekdays: draft.activeWeekdays,
      startDate: LocalDate.from(ref.read(clockProvider).now()),
      reminderMinutes: draft.reminderMinutes,
    );
    ref.read(selectedGoalIdProvider.notifier).select(goal.id);
    state = const OnboardingDraft();
    return goal;
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );
