import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import 'pressable.dart';

enum TileIndicator {
  /// Single choice.
  radio,

  /// Multiple choice or a single checkbox (the contract).
  check,
}

/// Full-width white tile. Selected tiles turn solid royal.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.indicator = TileIndicator.radio,
    this.leadingIndicator = false,
    this.fillWhenSelected = true,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final TileIndicator indicator;

  /// Put the indicator before the label (checkbox style) instead of after.
  final bool leadingIndicator;

  /// False keeps the tile white and fills only the indicator, for tiles that
  /// sit on royal (the mascot).
  final bool fillWhenSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final filled = selected && fillWhenSelected;
    final fg = filled ? t.onBrand : t.ink;
    final mark = _Indicator(
      selected: selected,
      kind: indicator,
      onBrand: fillWhenSelected,
    );
    final text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.bodyStrong.copyWith(color: fg)),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppText.label.copyWith(
                color: filled ? t.onBrand.withValues(alpha: 0.8) : t.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: leadingIndicator
            ? [mark, const SizedBox(width: 14), text]
            : [text, const SizedBox(width: 14), mark],
      ),
    );

    return Semantics(
      selected: selected,
      checked: indicator == TileIndicator.check ? selected : null,
      inMutuallyExclusiveGroup: indicator == TileIndicator.radio,
      button: true,
      child: Pressable(
        scale: 0.98,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: AppSizes.tileHeight),
          decoration: BoxDecoration(
            color: filled ? t.brand : t.surface,
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.selected,
    required this.kind,
    required this.onBrand,
  });

  final bool selected;
  final TileIndicator kind;

  /// Drawn on a royal tile: white box, royal check. Otherwise the reverse.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final round = kind == TileIndicator.radio;
    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? (onBrand ? t.onBrand : t.brand) : t.background,
        borderRadius: BorderRadius.circular(round ? 13 : 8),
        border: selected ? null : Border.all(color: t.borderStrong, width: 1.6),
      ),
      child: AnimatedScale(
        duration: AppDurations.medium,
        curve: Curves.easeOutBack,
        scale: selected ? 1 : 0,
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: onBrand ? t.brand : t.onBrand,
        ),
      ),
    );
  }
}
