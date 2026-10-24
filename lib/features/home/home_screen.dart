import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/time/local_date.dart';
import '../../core/time/today.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/duration_format.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/day_status.dart';
import '../../domain/models/goal.dart';
import '../../widgets/cup/cup_widget.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/mascot/coach_bubble.dart';
import '../../widgets/pressable.dart';
import '../../widgets/round_icon_button.dart';
import '../dock/action_dock.dart';
import '../dock/dock_actions.dart';
import '../notifications/reminders_controller.dart';
import '../session/session_controller.dart';
import '../shelf/shelf_controller.dart';
import 'home_copy.dart';

/// Home: every goal as a card with today's cup and the pact so far. A card
/// opens that goal's Shelf; the dock below adds a habit or runs the pour.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final today = ref.watch(todayProvider);
    final totals = ref.watch(dayTotalsProvider(today)).value ?? const {};
    final pouring = ref.watch(sessionGoalProvider);

    final pourToday = goals
        .where((g) => canPourToday(g, today, totals[g.id] ?? 0))
        .toList();
    final line = homeLine(
      pourToday: pourToday.length,
      savedToday: pourToday
          .where((g) => (totals[g.id] ?? 0) >= safetyNetSeconds)
          .length,
      pouringInto: pouring?.title,
      paused: !ref.watch(sessionControllerProvider.select((s) => s.isRunning)),
      allOver: goals.isNotEmpty && goals.every((g) => today.isAfter(g.endDate)),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                dockReserve,
              ),
              children: [
                FadeSlideIn(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          weekdayDate(today).toUpperCase(),
                          style: AppText.eyebrow.copyWith(color: t.inkMuted),
                        ),
                      ),
                      RoundIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Settings',
                        onPressed: () => context.go(Routes.settings),
                      ),
                    ],
                  ),
                ),
                FadeSlideIn(
                  delay: AppDurations.stagger,
                  child: Semantics(
                    header: true,
                    child: Text(
                      goals.length == 1 ? 'Your one thing' : 'Your habits',
                      style: AppText.display.copyWith(color: t.ink),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  delay: AppDurations.stagger * 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CoachBubble(text: line.text, mood: line.mood),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < goals.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm + 4),
                  FadeSlideIn(
                    delay: AppDurations.stagger * (3 + i),
                    child: _HabitCard(goal: goals[i], today: today),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One goal: today's cup, today's minutes, and a bar for the whole pact
/// (days saved over days gone). Opens the goal's Shelf.
class _HabitCard extends ConsumerWidget {
  const _HabitCard({required this.goal, required this.today});

  final Goal goal;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final session = ref.watch(sessionControllerProvider);
    final logs =
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
    final cup = dayCupFor(
      date: today,
      goal: goal,
      today: today,
      logs: logs,
      session: session,
    );
    final saved = logs.entries
        .where((e) => !e.key.isAfter(today) && e.value.status.isSuccess)
        .length;
    final total = goal.totalDays;
    final day = (goal.startDate.daysUntil(today) + 1).clamp(0, total);
    final target = goal.dailyTargetSeconds;

    final String status;
    var statusColor = t.inkMuted;
    if (cup.running) {
      status = 'Pouring · ${formatTimer(cup.totalSeconds)}';
      statusColor = t.brandInk;
    } else if (today.isAfter(goal.endDate)) {
      status = 'Horizon complete';
    } else if (today.isBefore(goal.startDate)) {
      status = 'Starts ${shortDate(goal.startDate)}';
    } else if (cup.status == DayStatus.rest) {
      status = 'Rest day';
    } else {
      final verdict = switch (cup.status) {
        DayStatus.targetReached => ' · Full cup',
        DayStatus.saved => ' · Saved',
        _ => '',
      };
      status =
          '${cup.totalSeconds ~/ 60} / ${formatShortDuration(target)} today'
          '$verdict';
      if (cup.status.isSuccess) statusColor = t.brandInk;
    }
    final dayText = today.isAfter(goal.endDate)
        ? '$total of $total days'
        : 'Day $day of $total';

    return Semantics(
      button: true,
      label: '${goal.title}. $status. $dayText, $saved saved. Open',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.98,
        onTap: () {
          ref.read(selectedGoalIdProvider.notifier).select(goal.id);
          context.go(Routes.shelf);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 18, 16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.background,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: CupWidget(
                  size: CupSize.small,
                  fill: cup.fill,
                  state: cup.state,
                  running: cup.running,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(color: t.ink),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: t.inkFaint,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(
                        color: statusColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    _PactBar(
                      gone: total == 0 ? 0 : day / total,
                      saved: total == 0 ? 0 : saved / total,
                    ),
                    const SizedBox(height: 6),
                    // Side by side, or stacked with very large text. Full
                    // width, so the saved count sits at the right end.
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 2,
                        children: [
                          Text(
                            dayText,
                            style: AppText.caption.copyWith(color: t.inkMuted),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop_rounded,
                                size: 13,
                                color: t.brand,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$saved saved',
                                style: AppText.caption.copyWith(
                                  color: t.inkMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pact as a bar: the share of days gone (soft), and of days saved
/// (brand) on top.
class _PactBar extends StatelessWidget {
  const _PactBar({required this.gone, required this.saved});

  final double gone;
  final double saved;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget fill(double widthFactor, Color color) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor.clamp(0.0, 1.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox.expand(),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.fill,
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Stack(
            children: [
              ColoredBox(color: t.background, child: const SizedBox.expand()),
              fill(gone * v, t.brandSoft),
              fill(saved * v, t.brand),
            ],
          ),
        ),
      ),
    );
  }
}
