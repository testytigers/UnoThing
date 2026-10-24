import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../widgets/cup/cup_widget.dart';
import '../../widgets/pressable.dart';
import 'onboarding_controller.dart';
import 'onboarding_guide.dart';
import 'widgets/onboarding_scaffold.dart';

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _everyDay = {1, 2, 3, 4, 5, 6, 7};
const _weekdays = {1, 2, 3, 4, 5};
const _weekends = {6, 7};

/// Frame 5, the Days: your week as seven glasses. Pour days fill up, rest
/// days go dashed, just like the week on the Shelf.
class DaysScreen extends ConsumerStatefulWidget {
  const DaysScreen({super.key});

  @override
  ConsumerState<DaysScreen> createState() => _DaysScreenState();
}

class _DaysScreenState extends ConsumerState<DaysScreen> {
  bool _touched = false;

  void _change(VoidCallback change) {
    change();
    setState(() => _touched = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final draft = ref.watch(onboardingControllerProvider);
    final c = ref.read(onboardingControllerProvider.notifier);
    final today = LocalDate.from(ref.watch(clockProvider).now());
    final days = draft.activeWeekdays;
    bool same(Set<int> preset) =>
        days.length == preset.length && days.containsAll(preset);

    return OnboardingScaffold(
      step: 4,
      title: 'Which days\nwill you pour?',
      guide: daysGuide(draft, today, touched: _touched),
      onNext: draft.daysValid ? () => context.push(Routes.contract) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (label, preset) in [
                ('Every day', _everyDay),
                ('Weekdays', _weekdays),
                ('Weekends', _weekends),
              ]) ...[
                if (preset != _everyDay) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PresetChip(
                    label: label,
                    selected: same(preset),
                    onTap: () => _change(() => c.setWeekdays(preset)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Text('Your week', style: AppText.title.copyWith(color: t.ink)),
                const SizedBox(height: 2),
                Text(
                  'Tap a glass to make it a rest day.',
                  style: AppText.caption.copyWith(color: t.inkMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (var d = 1; d <= 7; d++)
                      Expanded(
                        child: _DayGlass(
                          name: weekdayNames[d - 1],
                          pour: days.contains(d),
                          onTap: () => _change(() => c.toggleWeekday(d)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!draft.daysValid)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Pick at least one day.',
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(color: t.dangerInk),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.brand : t.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: AppText.bodyStrong.copyWith(
              color: selected ? t.onBrand : t.ink,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// One day of the week as a glass: it fills when it becomes a pour day and
/// goes dashed for a rest day.
class _DayGlass extends StatelessWidget {
  const _DayGlass({
    required this.name,
    required this.pour,
    required this.onTap,
  });

  final String name;
  final bool pour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: name,
      checked: pour,
      button: true,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.9,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          children: [
            Text(
              name[0],
              style: AppText.caption.copyWith(
                color: pour ? t.ink : t.inkFaint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            CupWidget(
              // A new key pours the glass again each time it's switched on.
              key: ValueKey(pour),
              size: CupSize.small,
              fill: pour ? 0.6 : 0,
              initialFill: pour ? 0 : null,
              state: pour ? CupState.filled : CupState.rest,
              onCard: true,
            ),
            const SizedBox(height: 6),
            Text(
              pour ? 'Pour' : 'Rest',
              style: AppText.caption.copyWith(
                color: pour ? t.brandInk : t.inkFaint,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
