import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../app/theme.dart';
import 'mascot_painter.dart';

export 'mascot_painter.dart' show MascotMood;

/// The mascot, alive: it breathes, blinks, sways its tuft, and bounces when
/// its mood changes. Decorative, so hidden from screen readers.
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    required this.mood,
    this.size = 64,
    this.look = Offset.zero,
    this.facing = 0,
    this.talkKey,
  });

  final MascotMood mood;
  final double size;

  /// Whenever this changes (say, the message beside it), the mascot talks
  /// for a moment: its mouth opens and closes like speaking.
  final Object? talkKey;

  /// Where the eyes look, -1..1 per axis.
  final Offset look;

  /// Radians the drop rests turned by: positive faces right, toward a
  /// speech bubble, in a three-quarter view.
  final double facing;

  /// False in tests: a still pose, so pumpAndSettle settles.
  static bool ambient = true;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: _LiveMascot(
      mood: mood,
      frame: MascotFrame.figure,
      look: look,
      facing: facing,
      talkKey: talkKey,
    ),
  );
}

/// The mascot's huge body rising from the bottom, wider than the screen,
/// with [child] laid on its belly below the face.
class MascotPeek extends StatelessWidget {
  const MascotPeek({
    super.key,
    required this.mood,
    required this.child,
    this.look = Offset.zero,
  });

  final MascotMood mood;
  final Offset look;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Positioned.fill(
            child: _LiveMascot(mood: mood, frame: MascotFrame.peek, look: look),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: c.maxWidth * MascotPainter.peekFaceDepth,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LiveMascot extends StatefulWidget {
  const _LiveMascot({
    required this.mood,
    required this.frame,
    required this.look,
    this.facing = 0,
    this.talkKey,
  });

  final MascotMood mood;
  final MascotFrame frame;
  final Offset look;
  final double facing;
  final Object? talkKey;

  @override
  State<_LiveMascot> createState() => _LiveMascotState();
}

class _LiveMascotState extends State<_LiveMascot>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final _pose = ValueNotifier(
    MascotPose(look: widget.look, turn: widget.facing, mood: widget.mood),
  );
  final _random = math.Random();

  /// A full turn on every mood change, like the inspiration GIF: the face
  /// slides round the back and comes back with the new expression.
  static const _spinLength = 0.75;
  static const _blinkLength = 0.18;
  static const _talkLength = 1.2;

  double _time = 0;
  double _nextBlink = 1.6;
  double _spinAt = -10;
  double _landAt = -10;
  double _nextGlance = 4;
  double _glance = 0;
  double _glanceTarget = 0;
  late MascotMood _shown = widget.mood;
  Offset _look = Offset.zero;
  double _previous = 0;
  late double _mouthTurn = widget.facing;
  Offset _dart = Offset.zero;
  Offset _dartTarget = Offset.zero;
  double _nextDart = 1.8;

  /// Say hello on arrival when there's something to say.
  late double _talkAt = widget.talkKey == null ? -10 : 0.25;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alive = Mascot.ambient && !MediaQuery.disableAnimationsOf(context);
    if (alive && !_ticker.isActive) {
      _ticker.start();
    } else if (!alive && _ticker.isActive) {
      _ticker.stop();
      _still();
    }
  }

  @override
  void didUpdateWidget(_LiveMascot old) {
    super.didUpdateWidget(old);
    if (!_ticker.isActive) {
      _still();
      return;
    }
    // Start a new spin unless one is still on its way to facing away (it
    // will pick up the latest mood when it gets there).
    if (old.mood != widget.mood && _time - _spinAt >= _spinLength / 2) {
      _spinAt = _time;
    }
    if (widget.talkKey != null && old.talkKey != widget.talkKey) {
      _talkAt = _time;
    }
  }

  void _still() {
    _shown = widget.mood;
    _pose.value = MascotPose(
      look: widget.look,
      turn: widget.facing,
      mood: widget.mood,
    );
  }

  void _tick(Duration elapsed) {
    _time = elapsed.inMicroseconds / 1e6;
    final dt = (_time - _previous).clamp(0.0, 0.1);
    _previous = _time;

    if (_time > _nextBlink + _blinkLength) {
      // Mostly single blinks, now and then a quick double.
      _nextBlink = _random.nextDouble() < 0.2
          ? _time + 0.12
          : _time + 2.2 + _random.nextDouble() * 3.4;
    }
    final b = _time - _nextBlink;
    final blink = b < 0 || b > _blinkLength
        ? 0.0
        : math.sin(b / _blinkLength * math.pi);

    // The spin: ease all the way round, swapping the face at the back, with
    // a little hop; a squash when it lands.
    final spin = (_time - _spinAt) / _spinLength;
    var turn = 0.0;
    var hop = 0.0;
    if (spin >= 0 && spin < 1) {
      turn = 2 * math.pi * Curves.easeInOutCubic.transform(spin);
      hop = math.sin(spin * math.pi);
      if (spin >= 0.5) _shown = widget.mood;
      _landAt = _spinAt + _spinLength;
    } else {
      _shown = widget.mood;
      // Now and then, glance to one side and back.
      if (_time > _nextGlance) {
        _glanceTarget = _glanceTarget == 0
            ? (_random.nextBool() ? 0.45 : -0.45)
            : 0;
        _nextGlance =
            _time + (_glanceTarget == 0 ? 3.5 + _random.nextDouble() * 4 : 1.2);
      }
    }
    _glance += (_glanceTarget - _glance) * 0.08;
    final since = _time - _landAt;
    final squash = since >= 0 && since < 1
        ? math.sin(since * 14) * math.exp(-since * 5) * 0.9
        : 0.0;
    _look = Offset.lerp(_look, widget.look, 0.1)!;
    final turnNow = widget.facing + turn + _glance;

    // The mouth follows the eyes a beat later (never more than 0.3 rad
    // behind), measured the short way round so a finished spin doesn't
    // unwind it.
    var lag = _mouthTurn - turnNow;
    lag = (lag + math.pi) % (2 * math.pi) - math.pi;
    lag *= math.exp(-dt / 0.07);
    _mouthTurn = turnNow + lag.clamp(-0.3, 0.3);

    // Now and then the eyes dart a little, then often settle back.
    if (_time > _nextDart) {
      _dartTarget = _random.nextDouble() < 0.4
          ? Offset.zero
          : Offset(
              (_random.nextDouble() - 0.5) * 0.5,
              (_random.nextDouble() - 0.5) * 0.25,
            );
      _nextDart = _time + 1.2 + _random.nextDouble() * 2.2;
    }
    _dart = Offset.lerp(_dart, _dartTarget, 1 - math.exp(-dt / 0.035))!;

    // Talking: about four syllables a second, easing in and out.
    final talking = _time - _talkAt;
    final talk = talking >= 0 && talking < _talkLength
        ? (0.5 - 0.5 * math.cos(2 * math.pi * 4.2 * talking)) *
              math.sin(math.pi * talking / _talkLength)
        : null;

    _pose.value = MascotPose(
      blink: blink,
      breathe: math.sin(_time * 2 * math.pi / 3.6),
      squash: squash,
      look: _look,
      turn: turnNow,
      hop: hop,
      time: _time,
      // The outline redraws itself eight times a second, like a hand-drawn
      // animation.
      boil: (_time * 8).floor(),
      mood: _shown,
      mouthTurn: _mouthTurn,
      dart: _dart,
      talk: talk,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: MascotPainter(
            mood: widget.mood,
            tokens: context.tokens,
            frame: widget.frame,
            pose: () => _pose.value,
            repaint: _pose,
          ),
        ),
      ),
    );
  }
}
