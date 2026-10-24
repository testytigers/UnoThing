import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/mascot/mascot_guide.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/round_icon_button.dart';
import '../onboarding_guide.dart';

/// Shared layout for the onboarding steps: back, the mascot guiding the step
/// (with the progress pie) pinned on top, the step's title and content, and
/// the primary button pinned at the bottom (it rides above the keyboard).
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.guide,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Next',
    this.busy = false,
  });

  /// 1-based position among [totalSteps].
  final int step;
  static const totalSteps = 5;

  final String title;

  /// What the mascot says right now.
  final Guide guide;
  final Widget child;

  /// Null disables the button.
  final VoidCallback? onNext;
  final String nextLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (context.canPop()) ...[
                        RoundIconButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Back',
                          iconSize: 26,
                          onPressed: context.pop,
                        ),
                        const SizedBox(height: AppSpacing.sm + 4),
                      ] else
                        const SizedBox(height: AppSpacing.sm),
                      FadeSlideIn(
                        child: MascotGuide(
                          message: guide.message,
                          mood: guide.mood,
                          step: step,
                          steps: totalSteps,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          delay: AppDurations.stagger,
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: AppText.display.copyWith(color: t.ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          delay: AppDurations.stagger * 2,
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: PrimaryButton(
                    label: nextLabel,
                    onPressed: onNext,
                    busy: busy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
