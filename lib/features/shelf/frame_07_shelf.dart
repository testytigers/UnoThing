import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/time/local_date.dart';
import '../../core/time/today.dart';
import '../../core/utils/date_format.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/goal.dart';
import '../../widgets/cup/cup_widget.dart';
import '../../widgets/cup/day_cup.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/mascot/coach_bubble.dart';
import '../../widgets/pressable.dart';
import '../../widgets/round_icon_button.dart';
import '../session/session_controller.dart';
import '../session/session_copy.dart';
import '../dock/action_dock.dart';
import '../dock/dock_actions.dart';
import 'shelf_controller.dart';

const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Frame 7, The Shelf: one goal. Its week on top, today's cup as the hero;
/// the dock below pours. Also Frame 10: right after a save, today's cup
/// rises once. Back returns to Home.
class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider).value;
    return Scaffold(
      body: SafeArea(
        child: goal == null ? const SizedBox.shrink() : _ShelfBody(goal: goal),
      ),
    );
  }
}

class _ShelfBody extends ConsumerWidget {
  const _ShelfBody({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final today = ref.watch(todayProvider);
    final session = ref.watch(sessionControllerProvider);
    final rise = ref.watch(fillAnimationProvider);
    final allLogs =
        ref
            .watch(
              logsInRangeProvider((
                goalId: goal.id,
                from: goal.startDate,
                to: goal.endDate,
              )),
            )
            .value ??
        const {};

    final todayCup = dayCupFor(
      date: today,
      goal: goal,
      today: today,
      logs: allLogs,
      session: session,
    );
    final horizonOver = today.isAfter(goal.endDate);
    final dayNumber = goal.startDate.daysUntil(today) + 1;
    final saved = allLogs.entries
        .where((e) => !e.key.isAfter(today) && e.value.status.isSuccess)
        .length;

    final pouring = session.session;
    final active = pouring?.goalId == goal.id && pouring?.date == today;
    // One goal pours at a time: another goal's session comes first.
    final elsewhere = pouring != null && !active
        ? ref.watch(sessionGoalProvider)
        : null;
    final todayStatus = goal.contains(today) ? todayCup.status : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                0,
              ),
              child: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Home',
                          iconSize: 26,
                          onPressed: () => context.go(Routes.home),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _StatsPill(
                              day: horizonOver
                                  ? 'Horizon complete'
                                  : 'Day $dayNumber of ${goal.totalDays}',
                              saved: '$saved saved',
                              onTap: () => context.go(Routes.horizon),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display.copyWith(color: t.ink),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // The mascot on top, like on Home.
                    CoachBubble(
                      text: elsewhere != null
                          ? pouringElsewhereLine(elsewhere.title)
                          : shelfLine(
                              todayStatus: todayStatus,
                              todaySeconds: todayCup.totalSeconds,
                              sessionActive: active,
                              horizonOver: horizonOver,
                            ),
                      mood: shelfMood(
                        todayStatus: todayStatus,
                        sessionActive: pouring != null,
                        horizonOver: horizonOver,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // The week first, like a calendar header: where you stand.
            FadeSlideIn(
              delay: AppDurations.stagger,
              child: _WeekStrip(goal: goal, today: today),
            ),
            // Today, zoomed in; the dock below holds its action.
            Expanded(
              child: FadeSlideIn(
                delay: AppDurations.stagger * 2,
                child: _TodayHero(
                  goal: goal,
                  cup: todayCup,
                  today: today,
                  session: session,
                  rise: rise?.goalId == goal.id && rise?.date == today
                      ? rise
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Day 1 of 92 · 0 saved", a visible door to the Horizon.
class _StatsPill extends StatelessWidget {
  const _StatsPill({
    required this.day,
    required this.saved,
    required this.onTap,
  });

  final String day;
  final String saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = AppText.label.copyWith(color: t.ink, fontSize: 14);
    return Semantics(
      button: true,
      label: '$day · $saved. Open the Horizon',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: t.brand),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  day,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: t.border,
              ),
              Icon(Icons.water_drop_rounded, size: 18, color: t.brand),
              const SizedBox(width: 4),
              Text(saved, maxLines: 1, style: style),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 20, color: t.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's cup, centred above the dock.
class _TodayHero extends ConsumerWidget {
  const _TodayHero({
    required this.goal,
    required this.cup,
    required this.today,
    required this.session,
    required this.rise,
  });

  final Goal goal;
  final DayCup cup;
  final LocalDate today;
  final SessionState session;
  final FillAnimation? rise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rise = this.rise;

    // Tapping the cup follows the Shelf rules (Frame 12 when banked); it
    // opens the full session, where the dock only starts in place.
    final tap = switch (shelfTapFor(cup, today, session, goalId: goal.id)) {
      ShelfTap.startSession => () => startAndOpen(ref, goal),
      ShelfTap.openSession => () => openSession(ref),
      ShelfTap.bankedToday => () => context.go(Routes.today),
      _ => null,
    };

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      container: true,
                      button: tap != null,
                      label: cup.semanticLabel,
                      excludeSemantics: true,
                      child: Pressable(
                        onTap: tap,
                        scale: 0.97,
                        child: Hero(
                          tag: cupHeroTag(goal.id, today),
                          child: CupWidget(
                            // A new key replays the rise for each save
                            // (Frame 10).
                            key: ValueKey('today-${rise?.id ?? 0}'),
                            size: CupSize.large,
                            showThresholds: true,
                            dailyTargetSeconds: goal.dailyTargetSeconds,
                            fill: cup.fill,
                            state: cup.state == CupState.ghost
                                ? CupState.empty
                                : cup.state,
                            running: cup.running,
                            initialFill: rise == null
                                ? null
                                : rise.fromSeconds / goal.dailyTargetSeconds,
                            fillDelay: rise == null
                                ? Duration.zero
                                : AppDurations.fill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: dockReserve),
      ],
    );
  }
}

/// The week as a compact row of seven small cups, with week navigation.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.goal, required this.today});

  final Goal goal;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final (first, last) = weekBounds(goal);
    final week =
        ref.watch(shelfWeekProvider(goal.id)) ?? defaultWeek(goal, today);
    void show(LocalDate monday) {
      HapticFeedback.selectionClick();
      ref.read(shelfWeekProvider(goal.id).notifier).show(monday);
    }

    final prev = week.isAfter(first) ? () => show(week.addDays(-7)) : null;
    final next = week.isBefore(last) ? () => show(week.addDays(7)) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Row(
            children: [
              RoundIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous week',
                size: 36,
                style: RoundIconButtonStyle.soft,
                onPressed: prev,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Text(
                    weekRange(week),
                    key: ValueKey(week),
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(color: t.ink),
                  ),
                ),
              ),
              RoundIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next week',
                size: 36,
                style: RoundIconButtonStyle.soft,
                onPressed: next,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Swiping here would fight the habit pages: weeks change with the
          // arrows.
          AnimatedSwitcher(
            duration: AppDurations.medium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _WeekRow(
              key: ValueKey(week),
              goal: goal,
              monday: week,
              today: today,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends ConsumerWidget {
  const _WeekRow({
    super.key,
    required this.goal,
    required this.monday,
    required this.today,
  });

  final Goal goal;
  final LocalDate monday;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final logs =
        ref
            .watch(
              logsInRangeProvider((
                goalId: goal.id,
                from: monday,
                to: monday.addDays(6),
              )),
            )
            .value ??
        const {};
    final session = ref.watch(sessionControllerProvider);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final date = monday.addDays(i);
                final cup = dayCupFor(
                  date: date,
                  goal: goal,
                  today: today,
                  logs: logs,
                  session: session,
                );
                final isToday = date == today;
                final tap = _onTap(context, ref, cup, session);
                return Semantics(
                  container: true,
                  button: tap != null,
                  label: cup.semanticLabel,
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: tap,
                    scale: 0.9,
                    child: Column(
                      children: [
                        Text(
                          _weekdayInitials[i],
                          style: AppText.caption.copyWith(
                            color: isToday ? t.brandInk : t.inkFaint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupWidget(
                          size: CupSize.small,
                          fill: cup.fill,
                          state: cup.state,
                          onCard: true,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 26,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday ? t.brand : null,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '${date.day}',
                            style: AppText.caption.copyWith(
                              color: isToday ? t.onBrand : t.inkMuted,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  VoidCallback? _onTap(
    BuildContext context,
    WidgetRef ref,
    DayCup cup,
    SessionState session,
  ) {
    switch (shelfTapFor(cup, today, session, goalId: goal.id)) {
      case ShelfTap.none:
        return null;
      case ShelfTap.pastDay:
        return () {
          ref.read(selectedGoalIdProvider.notifier).select(goal.id);
          context.go(Routes.day(cup.date.toIso()));
        };
      case ShelfTap.bankedToday:
        return () => context.go(Routes.today);
      case ShelfTap.openSession:
        return () => openSession(ref);
      case ShelfTap.startSession:
        return () => startAndOpen(ref, goal);
    }
  }
}
