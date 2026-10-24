import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// What the mascot feels. Each mood is a pair of eyes, a mouth, and maybe an
/// extra (a tear, a sweat drop, an anger mark, sunglasses).
enum MascotMood {
  /// Dash eyes and an open smile. Blinks and glances around.
  idle,

  /// Squinting ^ ^ with a big open smile.
  happy,

  /// Star eyes and a big open smile: wow moments.
  sparkle,

  /// Closed, content eyes and a floating "z": rest days.
  sleepy,

  /// Eyes squeezed shut > < and blushing: typing a password.
  shy,

  /// Tall eyes and a round "O": surprised.
  wow,

  /// Worried brows, a frown and a tear.
  sad,

  /// Looking up, "ooh": watching the drops fall while pouring.
  focus,

  /// Black sunglasses and a smirk: a full cup.
  cool,

  /// Slanted brows, a tight mouth and an anger mark.
  angry,

  /// Flat eyes, flat mouth, a sweat drop: "-_-".
  disappointed,
}

/// One frame of the mascot's motion. All values are small and centred on 0.
@immutable
class MascotPose {
  const MascotPose({
    this.blink = 0,
    this.breathe = 0,
    this.squash = 0,
    this.look = Offset.zero,
    this.turn = 0,
    this.hop = 0,
    this.time = 0,
    this.boil,
    this.mood,
    this.mouthTurn,
    this.dart = Offset.zero,
    this.talk,
  });

  /// 0 open .. 1 shut.
  final double blink;

  /// -1..1, the slow rise and fall of the body.
  final double breathe;

  /// Positive squashes (wider, shorter), negative stretches.
  final double squash;

  /// Where the eyes look, -1..1 per axis.
  final Offset look;

  /// Radians the body has turned about its vertical axis: the face slides
  /// around the drop and disappears behind it past a quarter turn.
  final double turn;

  /// 0..1, how far the body has hopped off the ground.
  final double hop;

  /// Seconds, for the floating "z".
  final double time;

  /// The hand-drawn "boil": a new wobble of the outline each frame number,
  /// like a hand-animated drawing. Null keeps the line still.
  final int? boil;

  /// The mood on screen right now, when it differs from the target (it
  /// swaps while the mascot faces away during a spin).
  final MascotMood? mood;

  /// The mouth's own turn: it follows [turn] a beat later, so the face
  /// isn't one rigid stamp. Null moves it with the eyes.
  final double? mouthTurn;

  /// A quick dart of the eyes within the face, in face units.
  final Offset dart;

  /// 0..1 while talking (how open the mouth is right now), else null.
  final double? talk;

  static const rest = MascotPose();
}

/// How the mascot is framed.
enum MascotFrame {
  /// The whole drop in its box, standing on its shadow (avatars, toasts).
  figure,

  /// A huge drop rising from the bottom of the box, wider than it, like a
  /// friend peeking up from below the screen.
  peek,
}

/// Paints the mascot: a plump water drop, flat periwinkle, with a compact
/// face of thick black strokes, like a hand-drawn cartoon.
class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.mood,
    required this.tokens,
    required this.pose,
    this.frame = MascotFrame.figure,
    this.monochrome,
    super.repaint,
  });

  final MascotMood mood;
  final AppTokens tokens;

  /// Read on every paint, so the widget can animate without rebuilding.
  final MascotPose Function() pose;
  final MascotFrame frame;

  /// Draws the body in this color and cuts the face out (themed icons).
  final Color? monochrome;

  /// Height of the peek drop above the face's bottom, as a fraction of
  /// width: lay content out below this.
  static const peekFaceDepth = 0.46;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose();
    switch (frame) {
      case MascotFrame.figure:
        _paintFigure(canvas, size, p);
      case MascotFrame.peek:
        _paintPeek(canvas, size, p);
    }
  }

  /// How far the tip leans: right when facing us, swinging left as the drop
  /// turns away.
  static double _lean(MascotPose p) => math.cos(p.turn);

  // The figure lives in a 100-unit box: tip at y 3, round belly down to 95,
  // shadow at 96.5.
  void _paintFigure(Canvas canvas, Size size, MascotPose p) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    // The shadow stays on the ground and shrinks as the body hops.
    if (monochrome == null) {
      final shrink = 1 - 0.35 * p.hop;
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(50, 96.5),
          width: 54 * shrink * (1 + 0.1 * p.squash),
          height: 5.5 * shrink,
        ),
        Paint()..color = tokens.shadow.withValues(alpha: 0.14 * shrink),
      );
    }

    // Hop, then breathe and squash about the feet.
    canvas.translate(0, -12 * p.hop);
    final sx = 1 - 0.012 * p.breathe + 0.1 * p.squash;
    final sy = 1 + 0.02 * p.breathe - 0.1 * p.squash;
    canvas.translate(50, 95);
    canvas.scale(sx, sy);
    canvas.translate(-50, -95);

    final tx = 50 + 5 * _lean(p);
    final drop = Path()
      ..moveTo(tx, 4)
      ..cubicTo(tx + 7, 16, 85, 34, 85, 62)
      ..cubicTo(85, 82, 69, 95, 50, 95)
      ..cubicTo(31, 95, 15, 82, 15, 62)
      ..cubicTo(15, 34, tx - 7, 16, tx, 4)
      ..close();
    const face = Offset(50, 62);
    const u = 6.2;
    _paintCreature(
      canvas,
      body: _boiled(drop, p, 0.7),
      face: face,
      u: u,
      radius: _turnRadius(drop, face, u),
      p: p,
      zAt: const Offset(68, 8),
      zSize: 12,
    );
    canvas.restore();
  }

  void _paintPeek(Canvas canvas, Size size, MascotPose p) {
    final w = size.width;
    final lift = w * (0.006 * p.breathe - 0.03 * p.squash + 0.04 * p.hop);
    final apex = w * 0.02 - lift;
    final mid = w / 2;
    final tx = mid + w * 0.035 * _lean(p);
    final side = w * 0.6;
    final shoulder = apex + w * 0.8;
    final drop = Path()
      ..moveTo(tx, apex)
      ..cubicTo(
        tx + w * 0.08,
        apex + w * 0.14,
        mid + side,
        apex + w * 0.36,
        mid + side,
        shoulder,
      )
      ..lineTo(mid + side, size.height + 10)
      ..lineTo(mid - side, size.height + 10)
      ..lineTo(mid - side, shoulder)
      ..cubicTo(
        mid - side,
        apex + w * 0.36,
        tx - w * 0.08,
        apex + w * 0.14,
        tx,
        apex,
      )
      ..close();
    final face = Offset(mid, apex + w * 0.3);
    final u = w * 0.048;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintCreature(
      canvas,
      body: _boiled(drop, p, w * 0.004),
      face: face,
      u: u,
      radius: _turnRadius(drop, face, u),
      p: p,
      zAt: Offset(mid + w * 0.18, apex + w * 0.04),
      zSize: w * 0.07,
    );
    canvas.restore();
  }

  /// The radius of the turn the face slides round: the drop's half-width
  /// at the top of the eyes, a little inside the edge, so a glance or a
  /// spin squeezes the face against the side instead of sliding it off.
  static double _turnRadius(Path drop, Offset face, double u) {
    final y = face.dy - 1.4 * u;
    final bounds = drop.getBounds();
    var inside = face.dx;
    var outside = bounds.right + 1;
    for (var i = 0; i < 14; i++) {
      final x = (inside + outside) / 2;
      if (drop.contains(Offset(x, y))) {
        inside = x;
      } else {
        outside = x;
      }
    }
    return (inside - face.dx) * 0.9;
  }

  /// [clean], redrawn as if by hand: resampled into a smooth closed curve
  /// and, while boiling, nudged in and out along its length by a soft wave
  /// that changes every frame.
  static Path _boiled(Path clean, MascotPose p, double amplitude) {
    final metric = clean.computeMetrics().first;
    const n = 72;
    final frame = p.boil;
    final random = math.Random((frame ?? 0) * 7919 + 13);
    final phases = [for (var i = 0; i < 3; i++) random.nextDouble() * 6.283];
    final amp = frame == null ? 0.0 : amplitude;
    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final tangent = metric.getTangentForOffset(metric.length * i / n)!;
      final th = 2 * math.pi * i / n;
      final wobble =
          amp *
          (0.6 * math.sin(2 * th + phases[0]) +
              0.3 * math.sin(3 * th + phases[1]) +
              0.2 * math.sin(5 * th + phases[2]));
      final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
      points.add(tangent.position + normal * wobble);
    }
    Offset half(Offset a, Offset b) => (a + b) / 2;
    final start = half(points.last, points.first);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final to = half(points[i], points[(i + 1) % n]);
      path.quadraticBezierTo(points[i].dx, points[i].dy, to.dx, to.dy);
    }
    return path..close();
  }

  void _paintCreature(
    Canvas canvas, {
    required Path body,
    required Offset face,
    required double u,
    required double radius,
    required MascotPose p,
    required Offset zAt,
    required double zSize,
  }) {
    // The face jitters a hair with the boil, like the outline.
    final jitter = p.boil == null
        ? Offset.zero
        : Offset(
            math.sin(p.boil! * 2.1) * u * 0.05,
            math.cos(p.boil! * 1.7) * u * 0.05,
          );
    final mono = monochrome;
    if (mono != null) {
      canvas.saveLayer(body.getBounds().inflate(4), Paint());
      canvas.drawPath(body, Paint()..color = mono);
      _Face(this, canvas, face + jitter, u, radius, p, cut: true).paint(body);
      canvas.restore();
      return;
    }
    canvas.drawPath(body, Paint()..color = tokens.mascot);
    _Face(this, canvas, face + jitter, u, radius, p).paint(body);
    if ((p.mood ?? mood) == MascotMood.sleepy) _paintZ(canvas, zAt, zSize, p);
  }

  /// Two floating z's that drift up and fade.
  void _paintZ(Canvas canvas, Offset at, double size, MascotPose p) {
    for (var i = 0; i < 2; i++) {
      final phase = (p.time / 2.4 + i * 0.5) % 1;
      final style = TextStyle(
        fontFamily: 'Rubik',
        fontWeight: FontWeight.w800,
        fontSize: size * (0.75 + 0.35 * i),
        color: tokens.mascotInk.withValues(
          alpha: 0.85 * math.sin(phase * math.pi).clamp(0.0, 1.0),
        ),
        height: 1,
      );
      final tp = TextPainter(
        text: TextSpan(text: 'z', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        at + Offset(i * size * 0.7 + phase * size * 0.3, -phase * size),
      );
    }
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.mood != mood ||
      old.tokens != tokens ||
      old.frame != frame ||
      old.monochrome != monochrome ||
      old.pose != pose;
}

/// Draws one compact face in units of [u] (half an eye's height) around
/// [center], mapped onto the drop's round belly of [radius] so it can turn.
class _Face {
  _Face(
    this.painter,
    this.canvas,
    this.center,
    this.u,
    this.radius,
    this.pose, {
    this.cut = false,
  });

  final MascotPainter painter;
  final Canvas canvas;
  final Offset center;
  final double u;
  final double radius;
  final MascotPose pose;

  /// Clear the face out of the body instead of inking it (monochrome).
  final bool cut;

  AppTokens get t => painter.tokens;
  MascotMood get mood => pose.mood ?? painter.mood;

  BlendMode get _blend => cut ? BlendMode.clear : BlendMode.srcOver;

  Paint _strokeOf(double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * u
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = t.mascotInk
    ..blendMode = _blend;

  late final Paint _stroke = _strokeOf(0.6);

  late final Paint _fill = Paint()
    ..color = t.mascotInk
    ..blendMode = _blend;

  Paint _light([double alpha = 1]) => Paint()
    ..color = t.highlight.withValues(alpha: alpha)
    ..blendMode = _blend;

  /// Draws [draw] at face-local ([fx], [fy]) units, slid round the belly by
  /// the turn and squeezed as it nears the edge. Hidden round the back.
  ///
  /// The eyes and the [mouth] layer move separately: the mouth lags the
  /// turn, sits deeper (it shifts less when looking around), and on a
  /// landing squash the eyes drop while the mouth bunches up.
  void at(double fx, double fy, void Function() draw, {bool mouth = false}) {
    final look = pose.look;
    final turn = mouth ? (pose.mouthTurn ?? pose.turn) : pose.turn;
    final phi = math.asin((fx * u / radius).clamp(-1.0, 1.0));
    final a = phi + turn + look.dx * (mouth ? 0.06 : 0.12);
    final squeeze = math.cos(a);
    if (squeeze < 0.06) return;
    final dy = mouth
        ? look.dy * 0.25 - pose.squash * 0.35
        : look.dy * 0.45 + pose.squash * 0.2;
    canvas.save();
    canvas.translate(
      center.dx + radius * math.sin(a),
      center.dy + (fy + dy) * u,
    );
    // Eyes stretch on the way up and flatten on landing.
    final stretch = mouth
        ? 1.0
        : (1 + 0.22 * pose.hop - 0.3 * pose.squash).clamp(0.6, 1.4);
    canvas.scale(squeeze, stretch);
    draw();
    canvas.restore();
  }

  void line(double x0, double y0, double x1, double y1) =>
      canvas.drawLine(Offset(x0 * u, y0 * u), Offset(x1 * u, y1 * u), _stroke);

  void curve(
    double x0,
    double y0,
    double cx,
    double cy,
    double x1,
    double y1,
  ) => canvas.drawPath(
    Path()
      ..moveTo(x0 * u, y0 * u)
      ..quadraticBezierTo(cx * u, cy * u, x1 * u, y1 * u),
    _stroke,
  );

  void paint(Path body) {
    canvas.save();
    canvas.clipPath(body);
    const eyeX = 1.65;
    const eyeY = -0.55;
    const mouthY = 1.15;

    if (!cut && mood == MascotMood.shy) {
      final blush = Paint()..color = t.blush;
      for (final side in const [-1.0, 1.0]) {
        at(side * 3.0, 0.9, mouth: true, () {
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 1.8 * u, height: u),
            blush,
          );
        });
      }
    }

    if (mood == MascotMood.cool) {
      _sunglasses(eyeX, eyeY);
    } else {
      for (final side in const [-1.0, 1.0]) {
        at(side * eyeX, eyeY, () {
          canvas.translate(pose.dart.dx * u, pose.dart.dy * u);
          _eye(side);
        });
      }
    }
    // Grumpy mouths sit a little off-centre.
    final skew = mood == MascotMood.angry || mood == MascotMood.disappointed;
    at(skew ? 0.35 : 0, mouthY, _mouth, mouth: true);

    switch (mood) {
      case MascotMood.sad:
        at(-eyeX + 0.25, 1.05, () => _drop(0.42, _light(0.95)));
      case MascotMood.disappointed:
        at(3.3, -1.5, () => _drop(0.5, _light(0.95)));
      case MascotMood.angry:
        at(3.1, -2.5, _angerMark);
      default:
        break;
    }
    canvas.restore();
  }

  /// A black "0" eye with a small white catch-light, [open] 0..1 (blinks
  /// squeeze it to a line).
  void _ovalEye(double rx, double ry, {double open = 1, bool star = false}) {
    if (open < 0.3) {
      line(-rx * 0.85, 0, rx * 0.85, 0);
      return;
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 2 * rx * u,
        height: 2 * ry * open * u,
      ),
      _fill,
    );
    if (cut || open < 0.6) return;
    if (star) {
      _star(
        rx * 0.62,
        center: Offset(0.05 * u, -0.12 * ry * u),
        paint: _light(),
      );
      canvas.drawCircle(
        Offset(-0.32 * rx * u, 0.5 * ry * u),
        0.12 * u,
        _light(),
      );
    } else {
      canvas.drawCircle(
        Offset(0.3 * rx * u, -0.38 * ry * u),
        0.36 * rx * u,
        _light(),
      );
    }
  }

  /// A short brow above an eye: [inner] > 0 raises its inner end (worried),
  /// < 0 lowers it (cross).
  void _brow(double side, double inner, double y) {
    line(-0.6, y + side * inner, 0.6, y - side * inner);
  }

  void _eye(double side) {
    final open = 1 - pose.blink;
    switch (mood) {
      case MascotMood.idle:
        _ovalEye(0.7, 1.0, open: open);
      case MascotMood.focus:
        // Looking up, at the drops falling into the cup.
        canvas.translate(0, -0.35 * u);
        _ovalEye(0.7, 1.0, open: open);
      case MascotMood.wow:
        _ovalEye(0.78, 1.15, open: open);
      case MascotMood.sparkle:
        _ovalEye(0.82, 1.15, star: true);
      case MascotMood.happy:
        curve(-0.7, 0.3, 0, -0.75, 0.7, 0.3);
      case MascotMood.sleepy:
        curve(-0.7, -0.15, 0, 0.65, 0.7, -0.15);
      case MascotMood.shy:
        // Squeezed shut, pointing inward: > <
        line(side * 0.5, -0.6, -side * 0.45, 0);
        line(-side * 0.45, 0, side * 0.5, 0.6);
      case MascotMood.sad:
        _ovalEye(0.66, 0.9, open: open);
        _brow(side, -0.16, -1.4);
      case MascotMood.angry:
        _ovalEye(0.66, 0.85, open: open);
        _brow(side, 0.22, -1.2);
      case MascotMood.disappointed:
        // Heavy lids: only the lower half of each eye, under a flat lid.
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(-u, -0.05 * u, u, u));
        _ovalEye(0.68, 0.92);
        canvas.restore();
        line(-0.62, -0.05, 0.62, -0.05);
      case MascotMood.cool:
        break;
    }
  }

  /// The GIF's open smile: a "D" on its back, white inside, inked round.
  void _openMouth(double halfWidth, double depth) {
    final w = halfWidth * u;
    final path = Path()
      ..moveTo(-w, 0)
      ..lineTo(w, 0)
      ..cubicTo(w, depth * 1.33 * u, -w, depth * 1.33 * u, -w, 0)
      ..close();
    if (!cut) canvas.drawPath(path, _light());
    canvas.drawPath(path, cut ? _fill : _strokeOf(0.45));
  }

  /// A talking "o", white inside: for moods that aren't smiling.
  void _talkingO(double open) {
    final o = Rect.fromCenter(
      center: Offset(0, 0.4 * u),
      width: 0.95 * u,
      height: (0.3 + 0.8 * open) * u,
    );
    if (!cut) canvas.drawOval(o, _light());
    canvas.drawOval(o, cut ? _fill : _strokeOf(0.45));
  }

  void _mouth() {
    final talk = pose.talk;
    if (talk != null) {
      switch (mood) {
        case MascotMood.idle ||
            MascotMood.happy ||
            MascotMood.sparkle ||
            MascotMood.focus ||
            MascotMood.wow:
          _openMouth(0.85, 0.25 + 0.85 * talk);
          return;
        case MascotMood.sad || MascotMood.angry || MascotMood.disappointed:
          _talkingO(talk);
          return;
        case MascotMood.cool || MascotMood.sleepy || MascotMood.shy:
          break;
      }
    }
    // Smiles breathe a little with the body.
    final breath = 1 + 0.08 * pose.breathe;
    switch (mood) {
      case MascotMood.idle:
        _openMouth(0.95, 0.85 * breath);
      case MascotMood.happy || MascotMood.sparkle:
        _openMouth(1.1, 1.05 * breath);
      case MascotMood.sleepy:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, 0.25 * u),
            width: 0.5 * u,
            height: 0.6 * u,
          ),
          _fill,
        );
      case MascotMood.focus:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, 0.3 * u),
            width: 0.6 * u,
            height: 0.75 * u,
          ),
          _fill,
        );
      case MascotMood.wow:
        final o = Rect.fromCenter(
          center: Offset(0, 0.45 * u),
          width: 1.0 * u,
          height: 1.2 * u,
        );
        if (!cut) canvas.drawOval(o, _light());
        canvas.drawOval(o, cut ? _fill : _strokeOf(0.45));
      case MascotMood.shy:
        canvas.drawPath(
          Path()
            ..moveTo(-0.6 * u, 0.2 * u)
            ..quadraticBezierTo(-0.3 * u, -0.2 * u, 0, 0.2 * u)
            ..quadraticBezierTo(0.3 * u, 0.6 * u, 0.6 * u, 0.2 * u),
          _stroke,
        );
      case MascotMood.sad:
        curve(-0.55, 0.5, 0, -0.2, 0.55, 0.5);
      case MascotMood.cool:
        curve(-0.6, 0.15, 0.15, 0.6, 0.75, -0.2);
      case MascotMood.angry:
        line(-0.45, 0.15, 0.45, 0.0);
      case MascotMood.disappointed:
        line(-0.5, 0.2, 0.5, 0.2);
    }
  }

  /// Black shades: two wide lenses under one thick frame, each with a glare.
  void _sunglasses(double eyeX, double eyeY) {
    for (final side in const [-1.0, 1.0]) {
      at(side * eyeX * 1.05, eyeY, () {
        final lens = Path()
          ..moveTo(-1.25 * u, -0.75 * u)
          ..lineTo(1.25 * u, -0.75 * u)
          ..cubicTo(1.3 * u, 0.6 * u, 0.75 * u, 1.1 * u, 0, 1.1 * u)
          ..cubicTo(-0.75 * u, 1.1 * u, -1.3 * u, 0.6 * u, -1.25 * u, -0.75 * u)
          ..close();
        canvas.drawPath(lens, _fill);
        if (!cut) {
          canvas.drawLine(
            Offset(-0.75 * u, -0.25 * u),
            Offset(-0.2 * u, -0.25 * u),
            _light(0.65)
              ..strokeWidth = 0.28 * u
              ..strokeCap = StrokeCap.round,
          );
        }
      });
    }
    // The bridge.
    at(0, eyeY - 0.6, () => line(-0.5, 0, 0.5, 0));
  }

  void _star(double r, {Offset center = Offset.zero, Paint? paint}) {
    final inner = r * 0.3;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final rr = (i.isEven ? r : inner) * u;
      final pt = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path..close(), paint ?? _fill);
  }

  /// A small drop, point up (a tear or a sweat drop).
  void _drop(double r, Paint paint) {
    final rr = r * u;
    canvas.drawPath(
      Path()
        ..moveTo(0, -rr * 1.6)
        ..cubicTo(rr * 0.4, -rr * 0.7, rr, -rr * 0.4, rr, rr * 0.2)
        ..arcToPoint(Offset(-rr, rr * 0.2), radius: Radius.circular(rr))
        ..cubicTo(-rr, -rr * 0.4, -rr * 0.4, -rr * 0.7, 0, -rr * 1.6)
        ..close(),
      paint,
    );
  }

  /// The comic anger mark: four little curved corners around a centre.
  void _angerMark() {
    final paint = _strokeOf(0.32);
    for (final qx in const [-1.0, 1.0]) {
      for (final qy in const [-1.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(qx * 0.25 * u, qy * 0.85 * u)
            ..quadraticBezierTo(
              qx * 0.25 * u,
              qy * 0.25 * u,
              qx * 0.85 * u,
              qy * 0.25 * u,
            ),
          paint,
        );
      }
    }
  }
}
