import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../paint/royal_paint.dart';

enum CupState {
  /// Future day: a faint silhouette.
  ghost,

  /// Today at 0: an empty glass.
  empty,

  /// Royal flake liquid at `fill` (0..1).
  filled,

  /// Missed active day: the glass knocked over, its milk on the ground.
  spilled,

  /// Non-active weekday (D2): a dashed outline.
  rest,
}

/// One-off moments played on a session cup.
enum CupCelebration {
  /// Crossed the safety net: a gold ring pulses out from the surface.
  saved,

  /// Reached the goal: the gold rim draws itself and the flakes flare.
  full,
}

/// Threshold lines drawn on large session cups (Frames 8, 11, 12).
@immutable
class CupThresholds {
  const CupThresholds({
    required this.minFraction,
    required this.targetLabel,
    required this.targetValue,
    required this.minLabel,
    required this.minValue,
    required this.labelStyle,
  });

  /// Height of the min line as a fraction of the fill area (300 / target).
  final double minFraction;
  final String targetLabel;
  final String targetValue;
  final String minLabel;
  final String minValue;
  final TextStyle labelStyle;
}

/// A tumbler seen slightly from above, fitted into a canvas size: the rim
/// and the base are ellipses, joined by straight walls.
class CupGeometry {
  CupGeometry._({
    required this.top,
    required this.bottom,
    required this.topWidth,
    required this.bottomWidth,
    required this.centerX,
    required this.headroom,
  });

  /// Ellipse height over width: how far we look down into the cup.
  static const tilt = 0.17;

  factory CupGeometry.fit(Size size, {required bool withThresholds}) {
    const aspect = 0.98; // wall height / top width
    // Session cups (with thresholds) keep open air above the rim for the
    // falling drop.
    final airAbove = withThresholds ? 0.18 : 0.03;
    final maxTopWidth = size.width * (withThresholds ? 0.6 : 0.9);
    // Rim half-ellipse + walls + base half-ellipse + the shadow below.
    const perWidth = aspect + tilt / 2 + tilt / 2 * 0.64 + 0.04;
    final room = size.height * (0.97 - airAbove);
    final topWidth = math.min(maxTopWidth, room / perWidth);
    final top = size.height * airAbove + topWidth * tilt / 2;
    return CupGeometry._(
      top: top,
      bottom: top + topWidth * aspect,
      topWidth: topWidth,
      bottomWidth: topWidth * 0.64,
      centerX: size.width / 2,
      // The target line needs visible space under the rim; a plain full cup
      // should look full.
      headroom: withThresholds ? 0.12 : 0.06,
    );
  }

  /// Centre of the rim ellipse.
  final double top;

  /// Centre of the base ellipse.
  final double bottom;
  final double topWidth;
  final double bottomWidth;
  final double centerX;

  /// Space between the rim and the 100% fill level, as a fraction of height.
  final double headroom;

  double get height => bottom - top;

  double get fillTop => top + height * headroom;

  /// Y coordinate of a fill fraction (0 = bottom, 1 = target level).
  double levelY(double fraction) =>
      bottom - fraction.clamp(0.0, 1.0) * (bottom - fillTop);

  double get strokeWidth => (topWidth * 0.024).clamp(1.1, 3.6);

  /// Half the cup's width at [y].
  double halfWidthAt(double y) {
    final f = ((y - top) / height).clamp(0.0, 1.0);
    return (topWidth + (bottomWidth - topWidth) * f) / 2;
  }

  /// The ellipse of the cup's cross-section at [y].
  Rect ellipseAt(double y) {
    final half = halfWidthAt(y);
    return Rect.fromCenter(
      center: Offset(centerX, y),
      width: half * 2,
      height: half * 2 * tilt,
    );
  }

  /// The opening.
  Rect get rim => ellipseAt(top);

  Rect get base => ellipseAt(bottom);

  /// The whole glass: the rim's far edge, the walls, the base's near edge.
  Path body() => Path()
    ..moveTo(rim.left, top)
    ..arcTo(rim, math.pi, math.pi, false)
    ..lineTo(base.right, bottom)
    ..arcTo(base, 0, math.pi, false)
    ..close();
}

/// Height of the liquid surface (in wave amplitudes) at spatial angle [k]
/// and wave [phase]. Every phase term uses a whole-number multiple, so the
/// surface at phase 2π matches phase 0 exactly and the loop has no seam.
double surfaceOffset(double k, double phase) =>
    math.sin(k + phase) + 0.35 * math.sin(2.1 * k - 2 * phase);

class CupPainter extends CustomPainter {
  CupPainter({
    required this.fill,
    required this.state,
    required this.tokens,
    required this.wavePhase,
    required this.waveStrength,
    this.shader,
    this.motion,
    this.thresholds,
    this.detailed = true,
    this.pouring = false,
    this.landing,
    this.celebration,
    this.celebrationT,
    this.onCard = false,
  }) : super(
         repaint: Listenable.merge([
           wavePhase,
           ?motion,
           ?celebrationT,
           ?landing,
         ]),
       );

  /// Fraction of a drop's cycle spent falling; it splashes after this.
  static const dropFallEnd = 0.55;

  /// Liquid level 0..1 (values above 1 are capped visually).
  final double fill;
  final CupState state;
  final AppTokens tokens;

  /// Wave phase in radians, animated while a session runs.
  final Animation<double> wavePhase;

  /// 0 = flat surface, 1 = full wave.
  final double waveStrength;

  /// Royal paint for the liquid; null draws the static gradient.
  final ui.FragmentShader? shader;

  /// Drives the flakes' glint. Null keeps the paint still.
  final PaintMotion? motion;

  final CupThresholds? thresholds;

  /// Shadow, highlights and puddle. Off for mini cups.
  final bool detailed;

  /// Drops fall from above the rim into the liquid (a running session).
  final bool pouring;

  /// One drop falling in and splashing, 0..1 (the Shelf's rise after a
  /// save). Nothing is drawn at 0 or 1.
  final Animation<double>? landing;

  /// The moment being played, and its progress 0..1.
  final CupCelebration? celebration;
  final Animation<double>? celebrationT;

  /// Drawn on a white card (the week strip): a cooler glass and a cream
  /// puddle, so both still stand out.
  final bool onCard;

  double get _celebrationP => celebrationT?.value ?? 1;

  bool _playing(CupCelebration c) => celebration == c && _celebrationP < 1;

  AppTokens get t => tokens;

  Color get _glass => onCard ? t.cupInner : t.cupGlass;

  /// Spilled milk: lighter than what it lies on.
  Color get _milk => onCard ? t.background : t.milk;

  double _line(CupGeometry g, [double scale = 1]) =>
      math.max(1.0, g.topWidth * 0.018 * scale);

  @override
  void paint(Canvas canvas, Size size) {
    final g = CupGeometry.fit(size, withThresholds: thresholds != null);

    switch (state) {
      case CupState.rest:
        _paintRest(canvas, g);
      case CupState.ghost:
        _paintGhost(canvas, g);
      case CupState.spilled:
        _paintSpilled(canvas, g);
      case CupState.empty:
      case CupState.filled:
        _paintGround(canvas, g);
        final level = state == CupState.filled ? fill.clamp(0.0, 1.0) : 0.0;
        final reached = state == CupState.filled && fill >= 1.0;
        _paintGlass(canvas, g, level: level, rim: reached ? t.gold : null);
    }

    final th = thresholds;
    if (th != null) _paintThresholds(canvas, g, th);

    final level = fill.clamp(0.0, 1.0);
    final holdsLiquid = state == CupState.filled || state == CupState.empty;
    final landed = landing?.value ?? 0;
    if (pouring && holdsLiquid) {
      _paintDrop(canvas, g, level, (wavePhase.value / (2 * math.pi) * 2) % 1.0);
    } else if (landed > 0 && landed < 1 && holdsLiquid) {
      _paintDrop(canvas, g, level, landed);
    }
    if (_playing(CupCelebration.saved)) _paintSavedPulse(canvas, g, level);
  }

  /// A flat shadow on the ground, like the mascot's.
  void _paintGround(Canvas canvas, CupGeometry g) {
    if (!detailed) return;
    final base = g.base;
    canvas.drawOval(
      Rect.fromCenter(
        center: base.center.translate(g.topWidth * 0.04, base.height * 0.35),
        width: base.width * 1.45,
        height: base.height * 1.7,
      ),
      Paint()..color = t.shadow.withValues(alpha: 0.06),
    );
  }

  /// The glass, built up like a vector illustration: body, the inside of
  /// the far wall, the liquid, a shade band, highlights, then the edges.
  /// [rim] recolors the rim (gold when full, coral when spilled).
  void _paintGlass(
    Canvas canvas,
    CupGeometry g, {
    double level = 0,
    Color? rim,
  }) {
    final body = g.body();
    final opening = g.rim;

    canvas.drawPath(body, Paint()..color = _glass);
    canvas.drawOval(opening, Paint()..color = t.cupInner);

    if (level > 0.001) {
      canvas.save();
      canvas.clipPath(
        Path.combine(PathOperation.union, body, Path()..addOval(opening)),
      );
      _paintLiquid(canvas, g, level);
      canvas.restore();
    }

    if (detailed) _paintShading(canvas, g, body);

    // Edges: the outline and the rim.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _line(g, 0.7)
      ..strokeJoin = StrokeJoin.round
      ..color = t.cupEdge;
    canvas.drawPath(body, edge);
    _paintRim(canvas, g, rim);
  }

  void _paintRim(Canvas canvas, CupGeometry g, Color? color) {
    final opening = g.rim;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _line(g, 1.1)
      ..color = t.cupEdge;
    canvas.drawOval(opening, ring);
    if (color == null) {
      // A white catch-light along the near lip.
      if (detailed) {
        canvas.drawArc(
          opening.deflate(_line(g) * 0.9),
          math.pi * 0.2,
          math.pi * 0.45,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = _line(g, 0.8)
            ..color = t.cupGlass,
        );
      }
      return;
    }
    // A colored rim. While the "full" moment plays, the gold draws itself
    // round the rim.
    final reach = color == t.gold && _playing(CupCelebration.full)
        ? Curves.easeInOutCubic.transform((_celebrationP * 1.4).clamp(0.0, 1.0))
        : 1.0;
    canvas.drawArc(
      opening,
      math.pi,
      2 * math.pi * reach,
      false,
      ring
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = _line(g, 1.4),
    );
  }

  /// Points around the liquid surface at [y], rippled by the wave.
  List<Offset> _surface(
    CupGeometry g,
    double y,
    double amp, {
    bool front = false,
  }) {
    final e = g.ellipseAt(y);
    final width = e.width;
    final phase = wavePhase.value;
    final n = front ? 24 : 48;
    return [
      for (var i = 0; i <= n; i++)
        () {
          // front: from the left (π) round the near side (π/2) to the right.
          final a = front ? math.pi - math.pi * i / n : 2 * math.pi * i / n;
          final x = e.center.dx + e.width / 2 * math.cos(a);
          final k = 2 * math.pi * (x - e.left) / (width / 1.35);
          return Offset(
            x,
            y + e.height / 2 * math.sin(a) + amp * surfaceOffset(k, phase),
          );
        }(),
    ];
  }

  void _paintLiquid(Canvas canvas, CupGeometry g, double level) {
    final y = g.levelY(level);
    // Calm the wave near empty so a thin layer doesn't slosh out of shape.
    final calm = (level * 6).clamp(0.0, 1.0);
    final amp = g.height * 0.018 * waveStrength * calm;

    final bounds = Rect.fromLTRB(
      g.centerX - g.topWidth / 2,
      g.top,
      g.centerX + g.topWidth / 2,
      g.bottom + g.base.height,
    );
    void paint(Path path, {double sparkle = 1}) => RoyalPaint.fill(
      canvas,
      path,
      bounds: bounds,
      tokens: t,
      shader: detailed ? shader : null,
      time: motion?.time ?? 0,
      light: motion?.light ?? Offset.zero,
      flakeScale: (g.topWidth / 34).clamp(1.6, 3.4),
      sparkle: sparkle,
    );
    // The flakes flare while the cup fills to the brim.
    final sparkle = _playing(CupCelebration.full)
        ? 1 + 2.5 * (1 - _celebrationP)
        : 1.0;

    // The body of liquid: the near edge of the surface, down the walls,
    // round the base.
    final front = _surface(g, y, amp, front: true);
    final volume = Path()..addPolygon(front, false);
    final base = g.base;
    volume
      ..lineTo(base.right, g.bottom)
      ..arcTo(base, 0, math.pi, false)
      ..close();
    paint(volume, sparkle: sparkle);

    // The top of the liquid: a lit ellipse.
    final top = Path()..addPolygon(_surface(g, y, amp), true);
    paint(top, sparkle: sparkle);
    canvas.drawPath(top, Paint()..color = t.paintGlow.withValues(alpha: 0.5));
    canvas.drawPath(
      Path()..addPolygon(front, false),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _line(g, 0.6)
        ..color = t.paintGlow,
    );
  }

  /// A darker band down the right wall and two white highlights on the left:
  /// the glass reads as round and shiny over both glass and liquid.
  void _paintShading(Canvas canvas, CupGeometry g, Path body) {
    final rim = g.rim;
    final base = g.base;
    canvas.save();
    canvas.clipPath(body);

    final bandTop = g.topWidth * 0.16;
    final bandBottom = g.bottomWidth * 0.16;
    final band = Path()
      ..moveTo(rim.right, g.top)
      ..lineTo(base.right, g.bottom)
      ..lineTo(base.right, g.bottom + base.height)
      ..lineTo(base.right - bandBottom, g.bottom + base.height)
      ..lineTo(rim.right - bandTop, g.top + rim.height * 0.5)
      ..close();
    canvas.drawPath(
      Path.combine(PathOperation.difference, band, Path()..addOval(rim)),
      Paint()..color = t.shadow.withValues(alpha: 0.07),
    );

    // Highlights, parallel to the left wall.
    Offset wall(double f, double inset) {
      final y = g.top + g.height * f;
      return Offset(g.centerX - g.halfWidthAt(y) + g.topWidth * inset, y);
    }

    final shine = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, g.topWidth * 0.05)
      ..color = t.cupGlass.withValues(alpha: 0.8);
    canvas.drawLine(wall(0.2, 0.14), wall(0.62, 0.12), shine);
    canvas.drawLine(wall(0.72, 0.12), wall(0.78, 0.115), shine);
    canvas.restore();
  }

  void _paintGhost(Canvas canvas, CupGeometry g) {
    // Whisper-light: future days should not compete with earned ones.
    canvas.drawPath(
      g.body(),
      Paint()
        ..color = (onCard ? t.background : t.backgroundDeep).withValues(
          alpha: 0.8,
        ),
    );
  }

  void _paintRest(Canvas canvas, CupGeometry g) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, g.topWidth * 0.028)
      ..strokeCap = StrokeCap.round
      ..color = t.borderStrong;
    final dash = math.max(2.0, g.topWidth * 0.07);
    final gap = dash * 0.9;
    for (final metric in g.body().computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  /// Knocked over: the glass lies on its side, its opening to the left with
  /// a coral rim, and its milk spread on the ground.
  void _paintSpilled(Canvas canvas, CupGeometry g) {
    final w = g.centerX * 2;
    final wall = math.atan2((g.topWidth - g.bottomWidth) / 2, g.height);
    final center = Offset(g.centerX, (g.top + g.bottom) / 2);
    // Rotate so one wall lies flat; the lying glass takes the right part of
    // the canvas.
    final scale = w * (detailed ? 0.56 : 0.66) / (g.height + g.rim.height);
    final m = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(-(math.pi / 2 - wall))
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    final bounds = g.body().transform(m.storage).getBounds();
    final ground = g.bottom + g.base.height / 2;
    final shift = Offset(w * 0.96 - bounds.right, ground - bounds.bottom);
    final mouthX = bounds.left + shift.dx;

    // The milk that got away, pooling out of the opening.
    final puddleH = math.max(3.0, g.height * 0.09);
    final puddle = Path()
      ..addRRect(
        RRect.fromLTRBR(
          w * 0.08,
          ground - puddleH * 0.55,
          mouthX + w * 0.16,
          ground + puddleH * 0.45,
          Radius.circular(puddleH / 2),
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(w * 0.03, ground + puddleH * 0.1),
          width: puddleH * 0.8,
          height: puddleH * 0.55,
        ),
      );
    if (detailed) {
      canvas.drawPath(
        puddle.shift(Offset(0, puddleH * 0.2)),
        Paint()..color = t.shadow.withValues(alpha: 0.07),
      );
    }
    canvas.drawPath(puddle, Paint()..color = _milk);
    canvas.drawPath(
      puddle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _line(g, 0.5)
        ..color = t.cupEdge,
    );

    canvas.save();
    canvas.translate(shift.dx, shift.dy);
    canvas.transform(m.storage);
    _paintGlass(canvas, g, rim: t.danger);
    canvas.restore();
  }

  void _paintThresholds(Canvas canvas, CupGeometry g, CupThresholds th) {
    void line(
      double y,
      Color color,
      Color textColor,
      String left,
      String right,
    ) {
      final e = g.ellipseAt(y);
      // Dashed round the near side of the glass, at that height.
      final arc = Path()..addArc(e, 0, math.pi);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final dash = g.topWidth * 0.05;
      final gap = dash * 0.75;
      for (final metric in arc.computeMetrics()) {
        for (var d = gap; d < metric.length - gap; d += dash + gap) {
          canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length - gap)),
            paint,
          );
        }
      }
      // The labels hug the walls.
      final style = th.labelStyle.copyWith(color: textColor);
      final lp = TextPainter(
        text: TextSpan(text: left, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final rp = TextPainter(
        text: TextSpan(text: right, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      const space = 10.0;
      lp.paint(canvas, Offset(e.left - space - lp.width, y - lp.height / 2));
      rp.paint(canvas, Offset(e.right + space, y - rp.height / 2));
    }

    // Gold text would wash out on cream: labels use the darker gold ink.
    line(g.levelY(1), t.targetLine, t.goldInk, th.targetLabel, th.targetValue);
    // Coral text uses the darker coral ink, like gold: readable on cream.
    line(
      g.levelY(th.minFraction),
      t.minLine,
      t.dangerInk,
      th.minLabel,
      th.minValue,
    );
  }

  void _paintSavedPulse(Canvas canvas, CupGeometry g, double level) {
    final p = _celebrationP;
    final fade = 1 - p;
    final y = g.levelY(level);
    final w = g.topWidth * (0.6 + 1.1 * Curves.easeOutCubic.transform(p));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(g.centerX, y),
        width: w,
        height: w * CupGeometry.tilt,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 + 2.6 * fade
        ..color = t.gold.withValues(alpha: fade),
    );
    canvas.drawOval(
      g.rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _line(g, 1.9)
        ..color = t.gold.withValues(alpha: fade),
    );
  }

  /// One drop at [u] (0..1) of its cycle: falls with gravity from the top
  /// of the canvas, then splashes into the surface with ripples and two tiny
  /// droplets. While pouring, one cycle runs every 1.3 s.
  void _paintDrop(Canvas canvas, CupGeometry g, double level, double u) {
    const fallEnd = dropFallEnd;
    final cx = g.centerX;
    final r = g.topWidth * 0.042;
    final surfaceY = level > 0.001 ? g.levelY(level) : g.bottom;

    if (u < fallEnd) {
      final f = u / fallEnd;
      final cy = ui.lerpDouble(r, surfaceY - r * 0.7, f * f)!;
      final tipY = cy - r * (1.9 + 1.2 * f); // stretches as it speeds up
      final mid = tipY + (cy - tipY) * 0.45;
      final drop = Path()
        ..moveTo(cx, tipY)
        ..cubicTo(cx + r * 0.2, mid, cx + r, cy - r * 0.7, cx + r, cy)
        ..arcToPoint(Offset(cx - r, cy), radius: Radius.circular(r))
        ..cubicTo(cx - r, cy - r * 0.7, cx - r * 0.2, mid, cx, tipY)
        ..close();
      final fadeIn = (f * 6).clamp(0.0, 1.0);
      canvas.saveLayer(
        drop.getBounds().inflate(2),
        Paint()..color = t.cupGlass.withValues(alpha: fadeIn),
      );
      RoyalPaint.fill(
        canvas,
        drop,
        bounds: drop.getBounds(),
        tokens: t,
        shader: shader,
        time: motion?.time ?? 0,
        light: motion?.light ?? Offset.zero,
        flakeScale: 1.6,
      );
      canvas.drawCircle(
        Offset(cx - r * 0.35, cy - r * 0.15),
        r * 0.22,
        Paint()..color = t.cupGlass.withValues(alpha: 0.75),
      );
      canvas.restore();
      return;
    }

    final p = (u - fallEnd) / (1 - fallEnd);
    final ease = Curves.easeOutCubic.transform(p);
    canvas.save();
    canvas.clipPath(Path()..addOval(g.ellipseAt(surfaceY)));
    for (final (delay, strength) in [(0.0, 1.0), (0.22, 0.6)]) {
      final q = ((p - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (q <= 0) continue;
      final w = r * 2 + g.topWidth * 0.5 * Curves.easeOutCubic.transform(q);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, surfaceY),
          width: w,
          height: w * CupGeometry.tilt,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = t.cupGlass.withValues(alpha: (1 - q) * 0.9 * strength),
      );
    }
    canvas.restore();

    // Two droplets thrown up and out, then back down.
    if (p < 0.8) {
      final hop = math.sin(math.min(p / 0.8, 1) * math.pi);
      for (final side in [-1.0, 1.0]) {
        canvas.drawCircle(
          Offset(
            cx + side * (r * 0.6 + r * 2.6 * ease),
            surfaceY - hop * r * 2.4,
          ),
          r * 0.32 * (1 - p * 0.5),
          Paint()..color = t.paintBright.withValues(alpha: 1 - p / 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(CupPainter old) =>
      old.fill != fill ||
      old.state != state ||
      old.tokens != tokens ||
      old.waveStrength != waveStrength ||
      old.thresholds != thresholds ||
      old.detailed != detailed ||
      old.shader != shader ||
      old.motion != motion ||
      old.pouring != pouring ||
      old.landing != landing ||
      old.celebration != celebration ||
      old.celebrationT != celebrationT ||
      old.onCard != onCard ||
      old.wavePhase != wavePhase;
}
