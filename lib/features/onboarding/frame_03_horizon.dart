import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../core/utils/date_format.dart';
import '../../domain/models/goal.dart' show horizonEndDate;
import '../../widgets/selectable_tile.dart';
import 'onboarding_controller.dart';
import 'onboarding_guide.dart';
import 'widgets/onboarding_scaffold.dart';

String horizonLabel(int months) => switch (months) {
  1 => '1 Month',
  12 => '1 Year',
  _ => '$months Months',
};

/// What each horizon feels like.
String horizonPromise(int months) => switch (months) {
  1 => 'A spark. Prove it to yourself.',
  3 => 'A habit. Long enough to stick.',
  6 => 'A transformation. People will notice.',
  9 => 'A new chapter.',
  _ => 'The year you finally did it.',
};

String horizonPhrase(int months) => switch (months) {
  1 => 'month',
  12 => 'year',
  _ => '$months months',
};

/// Frame 3, the Horizon: how long the pact runs. Each choice shows its
/// finish line; the mascot tells you what it feels like.
class HorizonStepScreen extends ConsumerWidget {
  const HorizonStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider);
    final c = ref.read(onboardingControllerProvider.notifier);
    final today = LocalDate.from(ref.watch(clockProvider).now());
    return OnboardingScaffold(
      step: 2,
      title: 'How long is\nyour pact?',
      guide: horizonGuide(draft),
      onNext: draft.horizonValid ? () => context.push(Routes.targetStep) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final months in horizonMonthOptions) ...[
            SelectableTile(
              label: horizonLabel(months),
              subtitle: () {
                final end = horizonEndDate(today, months);
                return 'Until ${shortDate(end)} ${end.year}';
              }(),
              selected: draft.horizonMonths == months,
              onTap: () => c.setHorizon(months),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
          ],
        ],
      ),
    );
  }
}
