import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../../core/time/local_date.dart';
import '../../core/time/today.dart';
import '../../core/utils/duration_format.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/goal.dart';
import '../../widgets/dock/morphing_dock.dart';
import '../session/session_controller.dart';
import '../shelf/shelf_controller.dart';
import 'dock_actions.dart';

/// Space a page leaves at its bottom for the dock.
const dockReserve = MorphingDock.reserve;

/// The pages the dock knows, read from the path.
enum DockPage {
  none,
  home,
  settings,
  shelf,
  horizon,
  session,
  stop,
  today,
  day,
}

DockPage dockPageFor(String path) {
  if (path == Routes.home) return DockPage.home;
  if (path == Routes.settings) return DockPage.settings;
  if (path == Routes.shelf) return DockPage.shelf;
  if (path == Routes.horizon) return DockPage.horizon;
  if (path == Routes.session) return DockPage.session;
  if (path == Routes.sessionStop) return DockPage.stop;
  if (path == Routes.today) return DockPage.today;
  if (path.startsWith(Routes.day(''))) return DockPage.day;
  return DockPage.none;
}

/// The floating black dock: the buttons that matter on each page, morphing
/// from one page's set to the next. Above every page, outside the routes, so
/// it can morph across navigation; it steps aside for dialogs, sheets and
/// the keyboard.
class ActionDock extends ConsumerWidget {
  const ActionDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popups = ref.watch(popupRouteObserverProvider).open;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final items = keyboard ? const <DockItem>[] : dockItems(ref);
    final bottom = math.max(MediaQuery.viewPaddingOf(context).bottom, 12.0);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 8),
        child: ValueListenableBuilder<int>(
          valueListenable: popups,
          builder: (_, open, _) =>
              MorphingDock(items: open > 0 ? const [] : items),
        ),
      ),
    );
  }
}

/// The dock's buttons for the current page and session.
List<DockItem> dockItems(WidgetRef ref) {
  final page = dockPageFor(ref.watch(locationProvider));
  if (page == DockPage.none) return const [];
  final state = ref.watch(sessionControllerProvider);
  final pouring = ref.watch(sessionGoalProvider);
  final goal = ref.watch(goalProvider).value;
  final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
  final today = ref.watch(todayProvider);

  // The live pour, wherever it's shown: pause, the timer, finish.
  List<DockItem> player(Goal goal) {
    final value = state.value ?? 0;
    final time = formatTimer(value);
    return [
      DockItem(
        id: 'toggle',
        playing: state.isRunning,
        filled: true,
        semanticLabel: state.isRunning ? 'Pause' : 'Resume',
        onTap: () => togglePause(ref),
      ),
      DockItem.timer(
        id: 'timer',
        time: time,
        caption: state.isRunning ? goal.title : 'Paused',
        progress: value / goal.dailyTargetSeconds,
        semanticLabel: '${goal.title}, $time. Open the session',
        onTap: () => openSession(ref),
      ),
      DockItem(
        id: 'finish',
        icon: Icons.stop_rounded,
        semanticLabel: 'Finish',
        onTap: () => finishSession(ref),
      ),
    ];
  }

  switch (page) {
    case DockPage.none:
      return const [];
    case DockPage.home:
      if (pouring != null) return player(pouring);
      if (!FeatureFlags.multiHabit || goals.length >= maxProGoals) {
        return const [];
      }
      return [
        DockItem(
          id: 'toggle',
          icon: Icons.add_rounded,
          label: 'New habit',
          filled: true,
          semanticLabel: 'New habit',
          onTap: () => addHabit(ref),
        ),
      ];
    case DockPage.settings:
    case DockPage.horizon:
      return pouring == null ? const [] : player(pouring);
    case DockPage.shelf:
      if (pouring != null) return player(pouring);
      if (goal == null) return const [];
      return _shelf(ref, goal, today);
    case DockPage.session:
      if (pouring == null) return const [];
      return [
        DockItem(
          id: 'toggle',
          playing: state.isRunning,
          label: state.isRunning ? 'Pause' : 'Resume',
          filled: true,
          semanticLabel: state.isRunning ? 'Pause' : 'Resume',
          onTap: () => togglePause(ref),
        ),
        DockItem(
          id: 'finish',
          icon: Icons.stop_rounded,
          semanticLabel: 'Finish',
          onTap: () => finishSession(ref),
        ),
      ];
    case DockPage.stop:
      if (pouring == null) return const [];
      return [
        DockItem(
          id: 'toggle',
          playing: false,
          semanticLabel: 'Continue',
          onTap: () => continueSession(ref),
        ),
        DockItem(
          id: 'save',
          icon: Icons.check_rounded,
          label: 'Save session',
          filled: true,
          semanticLabel: 'Save session',
          onTap: () => saveSession(ref),
        ),
        DockItem(
          id: 'discard',
          icon: Icons.delete_outline_rounded,
          semanticLabel: 'Discard',
          onTap: () => discardSession(ref),
        ),
      ];
    case DockPage.today:
      if (goal == null) return const [];
      if (pouring != null) {
        return [
          DockItem(
            id: 'toggle',
            icon: Icons.water_drop_rounded,
            label: 'Back to your pour',
            filled: true,
            semanticLabel: 'Back to your pour',
            onTap: () => openSession(ref),
          ),
        ];
      }
      return [
        DockItem(
          id: 'toggle',
          playing: false,
          label: 'Keep pouring',
          filled: true,
          semanticLabel: 'Keep pouring',
          onTap: () => startAndOpen(ref, goal),
        ),
        DockItem(
          id: 'adjust',
          icon: Icons.edit_outlined,
          semanticLabel: 'Adjust time',
          onTap: () => adjustTime(ref, goal, today),
        ),
      ];
    case DockPage.day:
      if (goal == null) return const [];
      final iso = ref.watch(locationProvider).substring(Routes.day('').length);
      final date = LocalDate.parse(iso);
      if (date.isAfter(today) || !goal.contains(date)) return const [];
      return [
        DockItem(
          id: 'adjust',
          icon: Icons.edit_outlined,
          label: 'Adjust time',
          filled: true,
          semanticLabel: 'Adjust time',
          onTap: () => adjustTime(ref, goal, date),
        ),
      ];
  }
}

/// One goal's Shelf, nothing pouring: its Horizon, the pour, its reminder.
List<DockItem> _shelf(WidgetRef ref, Goal goal, LocalDate today) {
  final logs = ref
      .watch(logsInRangeProvider((goalId: goal.id, from: today, to: today)))
      .value;
  final seconds = logs?[today]?.totalSeconds ?? 0;
  final open = logs != null && canPourToday(goal, today, seconds);
  final label = open
      ? (seconds == 0 ? 'Start pouring' : 'Keep pouring')
      : today.isAfter(goal.endDate)
      ? 'Horizon complete'
      : today.isBefore(goal.startDate)
      ? 'Starts soon'
      : 'Rest day';
  return [
    DockItem(
      id: 'horizon',
      icon: Icons.calendar_month_rounded,
      semanticLabel: 'Horizon',
      onTap: () => ref.read(routerProvider).go(Routes.horizon),
    ),
    DockItem(
      id: 'toggle',
      playing: false,
      label: label,
      filled: true,
      semanticLabel: label,
      onTap: open ? () => startPouring(ref, goal) : null,
    ),
    DockItem(
      id: 'reminder',
      icon: goal.reminderMinutes == null
          ? Icons.notifications_none_rounded
          : Icons.notifications_active_rounded,
      semanticLabel: 'Reminder',
      onTap: () => editReminder(ref, goal),
    ),
  ];
}
