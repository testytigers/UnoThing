import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/duration_format.dart';
import '../../domain/models/goal.dart';
import '../../widgets/reminder_tile.dart';
import '../../widgets/selectable_tile.dart';
import '../notifications/reminders_controller.dart';
import 'frame_03_horizon.dart' show horizonPhrase;
import 'onboarding_controller.dart';
import 'onboarding_guide.dart';
import 'widgets/onboarding_scaffold.dart';

/// "every day", "every weekday", "3 days a week"...
String rhythmPhrase(Set<int> days) {
  if (days.length == 7) return 'every single day';
  if (days.length == 5 && days.containsAll({1, 2, 3, 4, 5})) {
    return 'every weekday';
  }
  if (days.length == 2 && days.containsAll({6, 7})) return 'every weekend';
  if (days.length == 1) return 'one day a week';
  return '${days.length} days a week';
}

/// Frame 6, The Contract: the pact, spelled out.
class ContractScreen extends ConsumerStatefulWidget {
  const ContractScreen({super.key});

  @override
  ConsumerState<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends ConsumerState<ContractScreen> {
  bool _saving = false;

  Future<void> _sign() async {
    setState(() => _saving = true);
    try {
      final remind =
          ref.read(onboardingControllerProvider).reminderMinutes != null;
      await ref.read(onboardingControllerProvider.notifier).submit();
      HapticFeedback.heavyImpact();
      // The reminder needs notifications: ask now, in context.
      if (remind) {
        await ref.read(notificationsEnabledProvider.notifier).ensure();
      }
      // `go` replaces the stack, so onboarding is gone from back navigation.
      if (mounted) context.go(Routes.home);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 5,
      title: 'I commit...',
      guide: contractGuide(committed: draft.committed),
      busy: _saving,
      nextLabel: 'Seal the pact',
      onNext: draft.committed ? _sign : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.titleValid && draft.horizonValid) ...[
            _PactCard(
              draft: draft,
              today: LocalDate.from(ref.watch(clockProvider).now()),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ReminderTile.daily(
            context: context,
            title: 'Remind me',
            minutes: draft.reminderMinutes,
            onChanged: ref
                .read(onboardingControllerProvider.notifier)
                .setReminder,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          SelectableTile(
            label: "I commit that I'll do my best to achieve my Goal!",
            selected: draft.committed,
            indicator: TileIndicator.check,
            leadingIndicator: true,
            onTap: () => ref
                .read(onboardingControllerProvider.notifier)
                .setCommitted(!draft.committed),
          ),
        ],
      ),
    );
  }
}

class _PactCard extends StatelessWidget {
  const _PactCard({required this.draft, required this.today});

  final OnboardingDraft draft;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final months = draft.horizonMonths!;
    final end = horizonEndDate(today, months);
    final body = AppText.headline.copyWith(
      color: t.ink,
      fontSize: 20,
      height: 1.4,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
    final strong = TextStyle(color: t.brandInk, fontWeight: FontWeight.w800);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'THE PACT',
                style: AppText.eyebrow.copyWith(color: t.goldInk),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome, size: 18, color: t.gold),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'For the next ${horizonPhrase(months)}, '
                      "I'll pour ",
                ),
                TextSpan(
                  text: formatSpokenDuration(draft.dailyTargetSeconds),
                  style: strong,
                ),
                const TextSpan(text: ' into '),
                TextSpan(text: draft.title.trim(), style: strong),
                TextSpan(text: ', ${rhythmPhrase(draft.activeWeekdays)}.'),
              ],
            ),
            style: body,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Row(
              children: [
                const _Stamp(label: 'STARTS', value: 'Today'),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, size: 18, color: t.inkFaint),
                const Spacer(),
                _Stamp(
                  label: 'FINISH LINE',
                  value: '${shortDate(end)} ${end.year}',
                  alignEnd: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.eyebrow.copyWith(color: t.inkFaint, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(value, style: AppText.bodyStrong.copyWith(color: t.ink)),
      ],
    );
  }
}
