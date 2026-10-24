import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/primary_button.dart';

/// What Pro adds, with the test unlock until billing ships. True once
/// unlocked.
Future<bool> showProSheet(BuildContext context) async {
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ProSheet(),
  );
  return unlocked ?? false;
}

class _ProSheet extends ConsumerWidget {
  const _ProSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    Widget perk(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: t.brandInk),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: AppText.body.copyWith(color: t.ink)),
          ),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Mascot(mood: MascotMood.cool, size: 96)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The One Thing Pro',
              textAlign: TextAlign.center,
              style: AppText.display.copyWith(color: t.ink, fontSize: 28),
            ),
            const SizedBox(height: AppSpacing.lg),
            perk(
              Icons.local_drink_rounded,
              'Pour into up to $maxProGoals things at once.',
            ),
            perk(
              Icons.calendar_month_rounded,
              'Each with its own cup, week and Horizon.',
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Try Pro (test build)',
              icon: Icons.auto_awesome,
              onPressed: () async {
                await ref
                    .read(preferencesRepositoryProvider)
                    .setBool(Pref.proPreview, true);
                HapticFeedback.mediumImpact();
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Testing only: no payment is taken. Turn it off in Settings.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: t.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
