import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// One button (or the live timer) in the [MorphingDock].
@immutable
class DockItem {
  /// A round icon button, or with [label] a pill. [filled] paints it
  /// periwinkle: the page's main action.
  const DockItem({
    required this.id,
    required this.semanticLabel,
    this.icon,
    this.playing,
    this.label,
    this.filled = false,
    this.onTap,
  }) : time = null,
       caption = null,
       progress = null;

  /// The live pour: [time], a [caption] under it and a thin line for
  /// today's [progress] toward the goal (0..1).
  const DockItem.timer({
    required this.id,
    required this.semanticLabel,
    required String this.time,
    this.caption,
    this.progress,
    this.onTap,
  }) : icon = null,
       playing = null,
       label = null,
       filled = false;

  /// Keeps the item's slot across changes, so it morphs instead of being
  /// replaced: the same id can go from a "Start pouring" pill to a round
  /// pause button.
  final String id;
  final String semanticLabel;
  final IconData? icon;

  /// A play/pause icon that morphs between the two: true shows pause.
  final bool? playing;
  final String? label;
  final bool filled;
  final String? time;
  final String? caption;
  final double? progress;

  /// Null disables the item.
  final VoidCallback? onTap;

  bool get isTimer => time != null;
}

/// A floating black dock whose buttons change with the page. Between two
/// sets of buttons nothing jumps: buttons that stay slide to their new
/// place and stretch or shrink (a pill can shrink to a circle while its icon
/// morphs from play to pause), new ones grow out of the bar, old ones fold
/// away, and the bar gives a small jelly wobble. Empty, it sinks out of view.
class MorphingDock extends StatefulWidget {
  const MorphingDock({super.key, required this.items});

  final List<DockItem> items;

  /// Height of the bar.
  static const height = _slotHeight + 2 * _pad;

  /// Space a page leaves at its bottom for the dock.
  static const reserve = height + 20;

  @override
  State<MorphingDock> createState() => _MorphingDockState();
}

const _slotHeight = 52.0;
const _pad = 6.0;
const _gap = 4.0;
const _morph = Duration(milliseconds: 460);

class _Slot {
  _Slot(this.item);

  DockItem item;
  bool shown = true;
}

class _MorphingDockState extends State<MorphingDock>
    with SingleTickerProviderStateMixin {
  late final List<_Slot> _slots = [for (final i in widget.items) _Slot(i)];
  late final AnimationController _jelly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    value: 1,
  );
  Timer? _prune;

  @override
  void didUpdateWidget(MorphingDock old) {
    super.didUpdateWidget(old);
    final next = widget.items;
    final ids = {for (final i in next) i.id};
    final before = {
      for (final s in _slots)
        if (s.shown) s.item.id,
    };

    for (final s in _slots) {
      if (!ids.contains(s.item.id)) s.shown = false;
    }
    // Place each item after the slot of the item before it in the new list,
    // so leaving buttons fold away where they stood.
    for (var i = 0; i < next.length; i++) {
      final item = next[i];
      final existing = _slots.where((s) => s.item.id == item.id).firstOrNull;
      if (existing != null) {
        existing
          ..item = item
          ..shown = true;
        continue;
      }
      final prev = i == 0 ? null : next[i - 1].id;
      final at = prev == null
          ? 0
          : _slots.indexWhere((s) => s.item.id == prev) + 1;
      // Arrives folded, then opens next frame, so it grows out of the bar
      // (an implicit animation starts at its target on the first build).
      final slot = _Slot(item)..shown = false;
      _slots.insert(at, slot);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ids.contains(slot.item.id) && _slots.contains(slot)) {
          setState(() => slot.shown = true);
        }
      });
    }

    if (!_sameIds(before, ids)) {
      if (!MediaQuery.disableAnimationsOf(context)) _jelly.forward(from: 0);
      // Once folded away, leaving buttons drop out of the bar.
      _prune?.cancel();
      _prune = Timer(_morph, () {
        if (mounted) setState(() => _slots.removeWhere((s) => !s.shown));
      });
    }
  }

  static bool _sameIds(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  void dispose() {
    _prune?.cancel();
    _jelly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : _morph;
    final visible = widget.items.isNotEmpty;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.6),
      duration: duration,
      curve: Curves.easeInOutCubicEmphasized,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedBuilder(
            animation: _jelly,
            builder: (context, child) {
              // A damped wobble: wider and flatter, then back.
              final p = _jelly.value;
              final s = math.sin(p * math.pi * 3) * (1 - p) * 0.045;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(1 + s * 0.7, 1 - s, 1),
                child: child,
              );
            },
            child: Container(
              height: MorphingDock.height,
              padding: const EdgeInsets.all(_pad),
              decoration: BoxDecoration(
                color: t.ink,
                borderRadius: BorderRadius.circular(MorphingDock.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: t.ink.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              // Mid-morph, leaving and arriving buttons can briefly need
              // more room than the screen has: clip, don't overflow.
              child: UnconstrainedBox(
                clipBehavior: Clip.hardEdge,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in _slots)
                      _DockSlot(
                        key: ValueKey(s.item.id),
                        item: s.item,
                        shown: s.shown,
                        duration: duration,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One item's place in the bar: its width animates, and its content is
/// clipped to it, so a pill folding into a circle crops its label away.
class _DockSlot extends StatefulWidget {
  const _DockSlot({
    super.key,
    required this.item,
    required this.shown,
    required this.duration,
  });

  final DockItem item;
  final bool shown;
  final Duration duration;

  @override
  State<_DockSlot> createState() => _DockSlotState();
}

class _DockSlotState extends State<_DockSlot> {
  /// The label of a pill that is folding into a circle, kept while it fades.
  String? _lastLabel;

  DockItem get item => widget.item;
  bool get shown => widget.shown;
  Duration get duration => widget.duration;

  @override
  void didUpdateWidget(_DockSlot old) {
    super.didUpdateWidget(old);
    _lastLabel = item.label ?? old.item.label ?? _lastLabel;
  }

  double _width(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    double measure(String text, TextStyle style) {
      final p = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scale,
        maxLines: 1,
      )..layout();
      return p.width;
    }

    if (item.isTimer) {
      final w = math.max(
        measure(item.time!, _timeStyle),
        item.caption == null ? 0.0 : measure(item.caption!, _captionStyle),
      );
      return math.min(160, math.max(96, w + 32));
    }
    final label = item.label;
    if (label == null) return _slotHeight;
    return math.min(220, measure(label, AppText.button) + 22 + 8 + 44);
  }

  static final _timeStyle = AppText.bodyStrong.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );
  static final _captionStyle = AppText.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = item.onTap != null;
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOutCubicEmphasized,
      width: shown ? _width(context) : 0,
      height: _slotHeight,
      margin: EdgeInsets.symmetric(horizontal: shown ? _gap / 2 : 0),
      // Narrower than a button while it folds or grows: lay the content
      // out at button size and crop it.
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, c) => OverflowBox(
            minWidth: math.max(c.maxWidth, _slotHeight),
            maxWidth: math.max(c.maxWidth, _slotHeight),
            child: AnimatedOpacity(
              duration: duration,
              opacity: shown ? (enabled ? 1 : 0.4) : 0,
              child: AnimatedScale(
                duration: duration,
                curve: Curves.easeOutBack,
                scale: shown ? 1 : 0.6,
                // A folded-away button is no longer there for screen readers.
                child: ExcludeSemantics(
                  excluding: !shown,
                  child: Semantics(
                    button: true,
                    enabled: enabled,
                    label: item.semanticLabel,
                    excludeSemantics: true,
                    child: Material(
                      type: MaterialType.transparency,
                      child: AnimatedContainer(
                        duration: duration,
                        decoration: BoxDecoration(
                          color: item.filled ? t.brand : Colors.transparent,
                          borderRadius: BorderRadius.circular(_slotHeight / 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: item.onTap == null
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  item.onTap!();
                                },
                          splashColor: (item.filled ? t.onBrand : t.onButton)
                              .withValues(alpha: 0.12),
                          highlightColor: Colors.transparent,
                          child: item.isTimer
                              ? _TimerContent(
                                  item: item,
                                  timeStyle: _timeStyle,
                                  captionStyle: _captionStyle,
                                )
                              : _ButtonContent(
                                  item: item,
                                  label: item.label ?? _lastLabel,
                                  duration: duration,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.item,
    required this.label,
    required this.duration,
  });

  final DockItem item;

  /// The label shown, or fading out after the item lost it.
  final String? label;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = item.filled ? t.onBrand : t.onButton;
    final playing = item.playing;
    final icon = playing != null
        ? TweenAnimationBuilder<double>(
            tween: Tween(end: playing ? 1 : 0),
            duration: duration,
            curve: Curves.easeInOutCubic,
            builder: (_, v, _) => AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: AlwaysStoppedAnimation(v),
              color: color,
              size: 26,
            ),
          )
        : Icon(item.icon, color: color, size: 24);
    final hasLabel = item.label != null;
    // Icon, gap and label always laid out: as the slot narrows the label is
    // squeezed to nothing and the gap closes, so the icon ends up centred
    // without a jump.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        AnimatedContainer(duration: duration, width: hasLabel ? 8 : 0),
        Flexible(
          child: AnimatedOpacity(
            duration: duration,
            opacity: hasLabel ? 1 : 0,
            child: Text(
              label ?? '',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: AppText.button.copyWith(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimerContent extends StatelessWidget {
  const _TimerContent({
    required this.item,
    required this.timeStyle,
    required this.captionStyle,
  });

  final DockItem item;
  final TextStyle timeStyle;
  final TextStyle captionStyle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = item.progress;
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.time!,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: timeStyle.copyWith(color: t.onButton),
                ),
                if (item.caption != null)
                  Text(
                    item.caption!,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: captionStyle.copyWith(
                      color: t.onButton.withValues(alpha: 0.72),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (progress != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    ColoredBox(
                      color: t.onButton.withValues(alpha: 0.14),
                      child: const SizedBox.expand(),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: ColoredBox(
                        color: progress >= 1 ? t.gold : t.brand,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
