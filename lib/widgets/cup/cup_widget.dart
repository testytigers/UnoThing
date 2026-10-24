import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/utils/duration_format.dart';
import '../paint/royal_paint.dart';
import 'cup_painter.dart';

export 'cup_painter.dart' show CupCelebration, CupState;

enum CupSize {
  /// Session screens, with room for threshold labels.
  large(Size(320, 330)),

  /// Shelf grid.
  medium(Size(84, 88)),

  /// Shelf week row.
  small(Size(40, 44)),

  /// Horizon grid: no wave, no labels, no shadow.
  mini(Size(30, 32));

  const CupSize(this.dimensions);

  final Size dimensions;
}

/// One reusable cup. Liquid level animates smoothly when [fill] changes and
/// the surface waves while [running].
class CupWidget extends StatefulWidget {
  const CupWidget({
    super.key,
    required this.fill,
    required this.state,
    this.size = CupSize.medium,
    this.showThresholds = false,
    this.dailyTargetSeconds,
    this.running = false,
    this.initialFill,
    this.fillDelay = Duration.zero,
    this.semanticLabel,
    this.onCard = false,
  }) : assert(
         !showThresholds || dailyTargetSeconds != null,
         'Thresholds need the daily target',
       );

  /// 0..1, capped at 1 visually.
  final double fill;
  final CupState state;
  final CupSize size;

  /// Target and min lines (Frames 8, 11, 12 only).
  final bool showThresholds;
  final int? dailyTargetSeconds;

  /// Animates the liquid surface. Ignored for [CupSize.mini].
  final bool running;

  /// If set, the liquid rises from this level to [fill] on first build
  /// (the Frame 10 "saved" animation).
  final double? initialFill;

  /// Wait before the first rise from [initialFill], e.g. until a route
  /// transition has finished.
  final Duration fillDelay;

  final String? semanticLabel;

  /// Sits on a white card: draws the cup in cream so it stands out.
  final bool onCard;

  @override
  State<CupWidget> createState() => _CupWidgetState();
}

class _CupWidgetState extends State<CupWidget> with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final Animation<double> _phase = Tween<double>(
    begin: 0,
    end: 2 * math.pi,
  ).animate(_wave);

  /// One drop falls in and splashes before the first rise from
  /// [CupWidget.initialFill]; the liquid starts rising as it lands.
  late final AnimationController _land = AnimationController(
    vsync: this,
    duration: _landLength,
  );
  static const _landLength = Duration(milliseconds: 800);
  Timer? _landTimer;

  late final AnimationController _celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
    value: 1,
  );
  CupCelebration? _celebration;

  /// The first rise from [CupWidget.initialFill] has finished. After it, no
  /// drop and no start delay: later changes (a live session) just flow.
  bool _riseDone = false;

  /// Whether this cup opens with a rise from [CupWidget.initialFill].
  bool get _rises {
    final from = widget.initialFill;
    return from != null &&
        widget.size != CupSize.mini &&
        widget.fill.clamp(0.0, 1.0) > from + 0.001;
  }

  /// Wait before the level moves: the route's [CupWidget.fillDelay], then
  /// the drop's fall.
  Duration get _riseLead =>
      widget.fillDelay +
      (_rises ? _landLength * CupPainter.dropFallEnd : Duration.zero);

  bool get _waving => widget.running && widget.size != CupSize.mini;

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (widget.size != CupSize.mini) _shader = RoyalPaint.newShader();
    if (_waving) _wave.repeat();
    if (_rises) {
      _landTimer = Timer(widget.fillDelay, () {
        if (mounted && !MediaQuery.disableAnimationsOf(context)) {
          _land.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(CupWidget old) {
    super.didUpdateWidget(old);
    _maybeCelebrate(old);
    if (_waving && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!_waving && _wave.isAnimating) {
      // Let the surface settle via waveStrength, then stop ticking.
      Future<void>.delayed(AppDurations.fill, () {
        if (mounted && !_waving) _wave.stop();
      });
    }
  }

  /// Plays a moment when a running session crosses the safety net or the
  /// goal.
  void _maybeCelebrate(CupWidget old) {
    final target = widget.dailyTargetSeconds;
    if (!widget.running || target == null || widget.size == CupSize.mini) {
      return;
    }
    final saved = safetyNetSeconds / target;
    CupCelebration? moment;
    if (old.fill < 1 && widget.fill >= 1) {
      moment = CupCelebration.full;
    } else if (old.fill < saved && widget.fill >= saved) {
      moment = CupCelebration.saved;
    }
    if (moment == null || MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _celebration = moment);
    _celebrate.forward(from: 0);
  }

  @override
  void dispose() {
    _landTimer?.cancel();
    _land.dispose();
    _celebrate.dispose();
    _wave.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final target = widget.dailyTargetSeconds;
    final thresholds = widget.showThresholds && target != null
        ? CupThresholds(
            minFraction: (safetyNetSeconds / target).clamp(0.0, 1.0),
            targetLabel: 'Goal',
            targetValue: formatShortDuration(target),
            minLabel: 'Saved',
            minValue: formatShortDuration(safetyNetSeconds),
            labelStyle: AppText.label.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        : null;
    final mini = widget.size == CupSize.mini;
    final fill = widget.fill.clamp(0.0, 1.0).toDouble();
    // Flakes glint only where there is liquid to see.
    final motion =
        !mini && widget.state == CupState.filled && paintShouldAnimate(context)
        ? PaintMotion.instance
        : null;

    Widget paint(double level, double waveStrength) => CustomPaint(
      size: widget.size.dimensions,
      painter: CupPainter(
        landing: mini ? null : _land,
        celebration: _celebration,
        celebrationT: _celebrate,
        fill: level,
        state: widget.state,
        tokens: tokens,
        wavePhase: _phase,
        waveStrength: waveStrength,
        shader: _shader,
        motion: motion,
        thresholds: thresholds,
        detailed: !mini,
        pouring: _waving && widget.size == CupSize.large,
        onCard: widget.onCard,
      ),
    );

    final Widget cup = mini
        ? paint(fill, 0)
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.initialFill ?? fill, end: fill),
            // While pouring, the value ticks once a second: glide linearly
            // for exactly that second so the rise is one continuous motion,
            // not a surge-and-stop per tick.
            duration: widget.running
                ? const Duration(seconds: 1)
                : _riseDone
                ? AppDurations.fill
                : AppDurations.fill + _riseLead,
            curve: widget.running
                ? Curves.linear
                : _riseDone
                ? Curves.easeOutCubic
                : Interval(
                    _riseLead.inMicroseconds /
                        (AppDurations.fill + _riseLead).inMicroseconds,
                    1,
                    curve: Curves.easeOutCubic,
                  ),
            onEnd: () {
              if (!_riseDone && mounted) setState(() => _riseDone = true);
            },
            builder: (_, level, _) => TweenAnimationBuilder<double>(
              tween: Tween(end: _waving ? 1 : 0),
              duration: AppDurations.fill,
              curve: Curves.easeInOut,
              builder: (_, strength, _) => paint(level, strength),
            ),
          );

    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      excludeSemantics: true,
      child: RepaintBoundary(child: cup),
    );
  }
}
