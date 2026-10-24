import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'pressable.dart';

/// Full-width white tile button with an optional leading icon.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null;
    final fg = enabled ? t.ink : t.inkFaint;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Pressable(
        onTap: onPressed,
        scale: 0.97,
        child: Container(
          height: AppSizes.buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
    );
  }
}
