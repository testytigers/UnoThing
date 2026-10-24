import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../core/utils/duration_format.dart';
import '../../widgets/pressable.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/wheel_picker.dart';
import 'onboarding_controller.dart';
import 'onboarding_guide.dart';
import 'widgets/onboarding_scaffold.dart';

/// Most people pick a round number; Custom covers the rest.
const targetPresetsMinutes = [10, 15, 25, 45, 60];

/// Frame 4, the Daily Target: big friendly amounts, and the mascot tells
/// you what they add up to by the finish line.
class DailyTargetScreen extends ConsumerStatefulWidget {
  const DailyTargetScreen({super.key});

  @override
  ConsumerState<DailyTargetScreen> createState() => _DailyTargetScreenState();
}

class _DailyTargetScreenState extends ConsumerState<DailyTargetScreen> {
  bool _touched = false;

  void _pick(int seconds) {
    ref.read(onboardingControllerProvider.notifier).setTargetSeconds(seconds);
    setState(() => _touched = true);
  }

  Future<void> _custom() async {
    setState(() => _touched = true);
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _CustomTargetSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    final today = LocalDate.from(ref.watch(clockProvider).now());
    final target = draft.dailyTargetSeconds;
    final isPreset =
        target % 60 == 0 && targetPresetsMinutes.contains(target ~/ 60);

    final tiles = <Widget>[
      for (final m in targetPresetsMinutes)
        _AmountTile(
          big: '$m',
          small: 'min a day',
          semanticLabel: '$m minutes a day',
          selected: target == m * 60,
          onTap: () => _pick(m * 60),
        ),
      _AmountTile(
        big: isPreset ? '+' : formatShortDuration(target),
        small: isPreset ? 'Your own' : 'a day',
        semanticLabel: 'Custom amount',
        selected: !isPreset,
        onTap: _custom,
      ),
    ];

    return OnboardingScaffold(
      step: 3,
      title: 'How much\neach day?',
      guide: targetGuide(draft, today, touched: _touched),
      onNext: draft.targetValid ? () => context.push(Routes.daysStep) : null,
      child: Column(
        children: [
          for (var row = 0; row < tiles.length; row += 2) ...[
            if (row > 0) const SizedBox(height: AppSpacing.sm + 4),
            Row(
              children: [
                Expanded(child: tiles[row]),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(child: tiles[row + 1]),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A big number and a small line under it.
class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.big,
    required this.small,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String big;
  final String small;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          // Grows with large text instead of clipping it.
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? t.brand : t.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  big,
                  style: AppText.display.copyWith(
                    color: selected ? t.onBrand : t.ink,
                    fontSize: 34,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                small,
                style: AppText.label.copyWith(
                  color: selected ? t.onBrand : t.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hours and minutes wheels for a custom daily amount (5 min to 12 hrs).
class _CustomTargetSheet extends ConsumerWidget {
  const _CustomTargetSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final draft = ref.watch(onboardingControllerProvider);
    final c = ref.read(onboardingControllerProvider.notifier);
    final message = switch (draft.targetError) {
      TargetError.belowSafetyNet => 'At least 5 min a day.',
      TargetError.aboveMaximum => '12 hrs is the most a cup can hold.',
      null => null,
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your own amount',
              style: AppText.headline.copyWith(color: t.ink),
            ),
            const SizedBox(height: AppSpacing.lg),
            WheelPickerFrame(
              children: [
                WheelPicker(
                  key: const ValueKey('hours'),
                  count: 13,
                  value: draft.targetHours,
                  unit: 'hrs',
                  semanticLabel: 'Hours',
                  onChanged: c.setTargetHours,
                ),
                const SizedBox(width: AppSpacing.md),
                WheelPicker(
                  key: const ValueKey('minutes'),
                  count: 60,
                  value: draft.targetMinutes,
                  unit: 'min',
                  semanticLabel: 'Minutes',
                  looping: true,
                  onChanged: c.setTargetMinutes,
                ),
              ],
            ),
            SizedBox(
              height: 36,
              child: Center(
                child: message == null
                    ? null
                    : Text(
                        message,
                        style: AppText.label.copyWith(color: t.dangerInk),
                      ),
              ),
            ),
            PrimaryButton(
              label: 'Done',
              onPressed: draft.targetValid
                  ? () => Navigator.pop(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
