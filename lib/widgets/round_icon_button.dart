import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'pressable.dart';

enum RoundIconButtonStyle {
  /// White on the canvas.
  plain,

  /// Canvas-colored, for use inside white cards.
  soft,

  /// Soft ink, white icon: the main action.
  filled,
}

/// Circular icon button with a press-scale. Null [onPressed] disables it.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.iconSize,
    this.style = RoundIconButtonStyle.plain,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double? iconSize;
  final RoundIconButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null;
    final filled = style == RoundIconButtonStyle.filled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: enabled ? 1 : 0.3,
          child: Pressable(
            onTap: onPressed,
            scale: 0.9,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (style) {
                  RoundIconButtonStyle.plain => t.surface,
                  RoundIconButtonStyle.soft => t.background,
                  RoundIconButtonStyle.filled => t.button,
                },
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: filled ? t.onButton : t.ink,
                  size: iconSize ?? size * 0.46,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
