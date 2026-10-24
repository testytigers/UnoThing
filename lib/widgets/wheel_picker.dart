import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

/// One scroll wheel of integers `0..count-1` with a unit label beside the
/// selected value. Place inside [WheelPickerFrame] for the selection band.
class WheelPicker extends StatefulWidget {
  const WheelPicker({
    super.key,
    required this.count,
    required this.value,
    required this.onChanged,
    required this.unit,
    required this.semanticLabel,
    this.looping = false,
  });

  final int count;
  final int value;
  final ValueChanged<int> onChanged;
  final String unit;

  /// Spoken name of the wheel, e.g. "Hours".
  final String semanticLabel;
  final bool looping;

  static const itemExtent = 52.0;

  @override
  State<WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<WheelPicker> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget item(int i) => Center(
      child: Text(
        '$i',
        style: AppText.wheel.copyWith(color: t.ink),
        textScaler: TextScaler.noScaling,
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      value: '${widget.value} ${widget.unit}',
      increasedValue: '${(widget.value + 1) % widget.count} ${widget.unit}',
      decreasedValue:
          '${(widget.value - 1 + widget.count) % widget.count} ${widget.unit}',
      onIncrease: () => _controller.animateToItem(
        _controller.selectedItem + 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
      ),
      onDecrease: () => _controller.animateToItem(
        _controller.selectedItem - 1,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            child: ExcludeSemantics(
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: WheelPicker.itemExtent,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.3,
                perspective: 0.004,
                overAndUnderCenterOpacity: 0.3,
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  widget.onChanged(i % widget.count);
                },
                childDelegate: widget.looping
                    ? ListWheelChildLoopingListDelegate(
                        children: [
                          for (var i = 0; i < widget.count; i++) item(i),
                        ],
                      )
                    : ListWheelChildBuilderDelegate(
                        childCount: widget.count,
                        builder: (_, i) => item(i),
                      ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: ExcludeSemantics(
              child: Text(
                widget.unit,
                style: AppText.bodyStrong.copyWith(color: t.inkMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card with a highlighted selection band behind side-by-side wheels, and
/// edges that fade out.
class WheelPickerFrame extends StatelessWidget {
  const WheelPickerFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: WheelPicker.itemExtent * 5,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: WheelPicker.itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: t.brandSoft,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                t.ink.withValues(alpha: 0),
                t.ink,
                t.ink,
                t.ink.withValues(alpha: 0),
              ],
              stops: const [0, 0.3, 0.7, 1],
            ).createShader(rect),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
