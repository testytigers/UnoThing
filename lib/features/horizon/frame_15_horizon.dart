import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/time/local_date.dart';
import '../../core/time/today.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/goal.dart';
import '../../widgets/cup/cup_widget.dart';
import '../../widgets/dock/morphing_dock.dart';
import '../../widgets/mascot/mascot.dart';
import '../session/session_controller.dart';
import '../shelf/shelf_controller.dart';

/// Calendar cells for the horizon: whole weeks, Monday to Sunday. Days before
/// startDate and after endDate are null (blank cells).
List<LocalDate?> horizonCalendarCells(Goal goal) {
  final first = goal.startDate.startOfWeek;
  final last = goal.endDate.startOfWeek.addDays(6);
  return [
    for (var d = first; !d.isAfter(last); d = d.addDays(1))
      goal.contains(d) ? d : null,
  ];
}

const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _gridPadding = EdgeInsets.symmetric(horizontal: 20);
const _columnSpacing = 4.0;

/// Frame 15, The Horizon. Read-only calendar of mini cups, one row per week
/// (Monday first), from the week of startDate to the week of endDate.
class HorizonScreen extends ConsumerWidget {
  const HorizonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final goal = ref.watch(goalProvider).value;
    if (goal == null) return const Scaffold();
    final today = ref.watch(todayProvider);
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

    final cups = [
      for (final date in horizonCalendarCells(goal))
        date == null
            ? null
            : dayCupFor(
                date: date,
                goal: goal,
                today: today,
                logs: logs,
                session: session,
              ),
    ];
    // D4: X = SAVED + TARGET_REACHED days, Y = total horizon days.
    final done = cups.where((c) => c?.status.isSuccess ?? false).length;

    return Scaffold(
      appBar: AppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Mascot(
                  mood: today.isAfter(goal.endDate)
                      ? MascotMood.sparkle
                      : done > 0
                      ? MascotMood.happy
                      : MascotMood.idle,
                  size: 72,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  goal.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppText.eyebrow.copyWith(color: t.brandInk),
                ),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  header: true,
                  child: Text(
                    'Horizon',
                    style: AppText.display.copyWith(color: t.ink, fontSize: 40),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$done/${goal.totalDays} days',
                  style: AppText.bodyStrong.copyWith(
                    color: t.inkMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 200,
                    height: 10,
                    child: ColoredBox(
                      color: t.surface,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: done / goal.totalDays),
                        duration: AppDurations.fill,
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: v,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: t.brand,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          const SliverPersistentHeader(
            pinned: true,
            delegate: _WeekdayHeader(),
          ),
          SliverPadding(
            padding: _gridPadding.copyWith(
              top: AppSpacing.sm,
              // Room for the dock (the live pour shows there).
              bottom: MorphingDock.reserve + AppSpacing.md,
            ),
            sliver: SliverGrid.builder(
              itemCount: cups.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 14,
                crossAxisSpacing: _columnSpacing,
                childAspectRatio:
                    CupSize.mini.dimensions.width /
                    (CupSize.mini.dimensions.height + 8),
              ),
              itemBuilder: (_, i) {
                final cup = cups[i];
                if (cup == null) return const SizedBox.shrink();
                final isToday = cup.date == today;
                return Semantics(
                  container: true,
                  label: cup.semanticLabel,
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Expanded(
                        child: FittedBox(
                          child: CupWidget(
                            size: CupSize.mini,
                            fill: cup.fill,
                            state: cup.state,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isToday ? t.brand : null,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// M T W T F S S, pinned while the calendar scrolls.
class _WeekdayHeader extends SliverPersistentHeaderDelegate {
  const _WeekdayHeader();

  static const _height = 36.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final t = context.tokens;
    // A persistent header must paint its full extent.
    return Container(
      height: _height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.background,
        border: Border(
          bottom: BorderSide(color: overlaps ? t.border : t.background),
        ),
      ),
      child: Padding(
        padding: _gridPadding,
        child: Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: _columnSpacing),
              Expanded(
                child: Semantics(
                  label: _weekdayNames[i],
                  excludeSemantics: true,
                  child: Text(
                    _weekdayInitials[i],
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(
                      color: i >= 5 ? t.inkFaint : t.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_WeekdayHeader oldDelegate) => false;
}
