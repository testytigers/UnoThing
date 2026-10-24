import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'pressable.dart';

/// Full-width rounded button in soft ink. Flat: no glitter, no gradient.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Shows a spinner and ignores taps.
  final bool busy;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null;
    final fg = enabled ? t.onButton : t.inkFaint;

    final content = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: busy
          ? SizedBox.square(
              key: const ValueKey('busy'),
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: t.onButton,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.button.copyWith(color: fg),
                  ),
                ),
              ],
            ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Pressable(
        onTap: busy ? null : onPressed,
        scale: 0.97,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          height: AppSizes.buttonHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            color: enabled ? t.button : t.backgroundDeep,
          ),
          child: content,
        ),
      ),
    );
  }
}
