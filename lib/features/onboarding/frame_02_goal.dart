import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import 'onboarding_controller.dart';
import 'onboarding_guide.dart';
import 'widgets/onboarding_scaffold.dart';

/// Frame 2, The Goal.
class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  late final TextEditingController _text = TextEditingController(
    text: ref.read(onboardingControllerProvider).title,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _next() => context.push(Routes.horizonStep);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final draft = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 1,
      title: draft.adding
          ? "What's your\nnext thing?"
          : "What's your\none thing?",
      guide: goalGuide(draft.title, adding: draft.adding),
      onNext: draft.titleValid ? _next : null,
      child: TextField(
        controller: _text,
        autofocus: true,
        maxLength: maxGoalTitleLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        style: AppText.headline.copyWith(color: t.ink, fontSize: 24),
        decoration: InputDecoration(
          hintText: 'e.g. Learn Judo',
          hintStyle: AppText.headline.copyWith(
            color: t.inkFaint.withValues(alpha: 0.7),
            fontSize: 24,
          ),
          counterStyle: AppText.caption.copyWith(color: t.inkFaint),
        ),
        onChanged: ref.read(onboardingControllerProvider.notifier).setTitle,
        onSubmitted: (_) {
          if (ref.read(onboardingControllerProvider).titleValid) _next();
        },
      ),
    );
  }
}
