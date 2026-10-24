import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

/// Frame 1, Login. Auth is local-only (open decision D3).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _Action { login, create }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  _Action? _busy;
  String? _error;

  /// A refused login (wrong password, taken email) makes the mascot cross;
  /// a typo only surprises it.
  bool _refused = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const _minPasswordLength = 6;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Repaint the mascot as focus moves between fields.
    _emailFocus.addListener(_refresh);
    _passwordFocus.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  String? _validate(_Action action) {
    if (!_emailPattern.hasMatch(_email.text.trim())) {
      return "That email doesn't look quite right.";
    }
    if (_password.text.isEmpty) return 'Your password, please.';
    if (action == _Action.create &&
        _password.text.length < _minPasswordLength) {
      return 'Make it at least $_minPasswordLength characters. '
          'Your one thing deserves it.';
    }
    return null;
  }

  Future<void> _submit(_Action action) async {
    FocusScope.of(context).unfocus();
    final invalid = _validate(action);
    if (invalid != null) {
      setState(() {
        _error = invalid;
        _refused = false;
      });
      return;
    }
    setState(() {
      _busy = action;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (action == _Action.create) {
        await auth.createAccount(email: _email.text, password: _password.text);
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
      final goals = await ref.read(goalRepositoryProvider).getGoals();
      if (mounted) context.go(goals.isEmpty ? Routes.goal : Routes.home);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _refused = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// The mascot reacts to the form: it watches you type your email, shuts
  /// its eyes for the password, gasps at typos and scowls at a refusal.
  MascotMood get _mood {
    if (_busy != null) return MascotMood.happy;
    if (_error != null) return _refused ? MascotMood.angry : MascotMood.wow;
    if (_passwordFocus.hasFocus && _obscure) return MascotMood.shy;
    return MascotMood.idle;
  }

  Offset get _look {
    if (_emailFocus.hasFocus) {
      // Follow the caret along the field.
      final progress = (_email.text.length / 24).clamp(0.0, 1.0);
      return Offset(-0.8 + 1.6 * progress, 0.9);
    }
    if (_passwordFocus.hasFocus) return const Offset(0, 0.9);
    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final busy = _busy != null;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Column(
              // The headline floats in the middle of the space above the
              // mascot.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox.shrink(),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xl,
                      AppSpacing.gutter,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        FadeSlideIn(
                          child: Semantics(
                            header: true,
                            child: Text(
                              'One thing.\nEvery day.',
                              textAlign: TextAlign.center,
                              style: AppText.hero.copyWith(color: t.ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(
                          delay: AppDurations.stagger,
                          child: Text(
                            'Pour a little time into what matters most, '
                            'and watch your cup fill.',
                            textAlign: TextAlign.center,
                            style: AppText.body.copyWith(color: t.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FadeSlideIn(
                  delay: AppDurations.stagger * 2,
                  offset: 60,
                  child: MascotPeek(
                    mood: _mood,
                    look: _look,
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.maxContentWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.gutter,
                              AppSpacing.md,
                              AppSpacing.gutter,
                              AppSpacing.lg,
                            ),
                            child: _form(t, busy),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AppTokens t, bool busy) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('email'),
            controller: _email,
            focusNode: _emailFocus,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            style: AppText.bodyStrong.copyWith(color: t.ink),
            decoration: _decoration(
              t,
              hint: 'Email',
              icon: Icons.alternate_email_rounded,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          TextField(
            key: const ValueKey('password'),
            controller: _password,
            focusNode: _passwordFocus,
            enabled: !busy,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            style: AppText.bodyStrong.copyWith(color: t.ink),
            decoration:
                _decoration(
                  t,
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: t.inkMuted,
                    ),
                  ),
                ),
            onSubmitted: (_) => _submit(_Action.login),
          ),
          AnimatedSize(
            duration: AppDurations.fast,
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm + 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                      child: Text(
                        _error!,
                        style: AppText.label.copyWith(color: t.dangerInk),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Login',
            busy: _busy == _Action.login,
            onPressed: busy ? null : () => _submit(_Action.login),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          SecondaryButton(
            label: 'Create account',
            onPressed: busy ? null : () => _submit(_Action.create),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Everything stays on this phone. No cloud, no noise.',
            textAlign: TextAlign.center,
            // Full ink: softened, it fell below 4.5:1 on periwinkle.
            style: AppText.caption.copyWith(color: t.onBrand),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(
    AppTokens t, {
    required String hint,
    required IconData icon,
  }) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: t.inkFaint, size: 20),
    // The royal focus ring would vanish on the mascot: use ink instead.
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: t.ink, width: 2),
    ),
  );
}
