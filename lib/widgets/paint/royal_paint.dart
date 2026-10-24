import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme.dart';

/// The royal metallic-flake paint (shaders/royal_paint.frag).
abstract final class RoyalPaint {
  static ui.FragmentProgram? _program;

  /// False in tests: surfaces use the static gradient fallback and nothing
  /// animates, so goldens are deterministic and pumpAndSettle settles.
  static bool enabled = true;

  static bool get isLoaded => _program != null;

  /// Compiles the shader once at startup. Failure falls back to gradients.
  static Future<void> load() async {
    if (!enabled || _program != null) return;
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/royal_paint.frag');
    } on Object catch (e) {
      debugPrint('Royal paint shader unavailable, using gradient: $e');
    }
  }

  static ui.FragmentShader? newShader() =>
      enabled ? _program?.fragmentShader() : null;

  /// Fills [path] with royal paint laid out over [bounds].
  static void fill(
    Canvas canvas,
    Path path, {
    required Rect bounds,
    required AppTokens tokens,
    ui.FragmentShader? shader,
    double time = 0,
    Offset light = Offset.zero,
    double flakeScale = 2.4,
    double sparkle = 1,
    double opacity = 1,
  }) {
    final paint = Paint();
    if (shader != null) {
      var i = 0;
      void f(double v) => shader.setFloat(i++, v);
      void c(Color color) {
        f(color.r);
        f(color.g);
        f(color.b);
        f(color.a);
      }

      f(bounds.width);
      f(bounds.height);
      f(bounds.left);
      f(bounds.top);
      f(time);
      f(light.dx);
      f(light.dy);
      c(tokens.paintDeep);
      c(tokens.paint);
      c(tokens.paintBright);
      c(tokens.flakeA);
      c(tokens.flakeB);
      f(flakeScale);
      f(sparkle);
      f(opacity);
      paint.shader = shader;
    } else {
      paint.shader = gradient(bounds, tokens, opacity: opacity);
    }
    canvas.drawPath(path, paint);
  }

  /// Static stand-in for the shader: a lit diagonal body.
  static Shader gradient(Rect bounds, AppTokens t, {double opacity = 1}) {
    Color o(Color c) => c.withValues(alpha: c.a * opacity);
    return ui.Gradient.linear(
      bounds.topLeft,
      bounds.bottomRight,
      [o(t.paintBright), o(t.paint), o(t.paintDeep)],
      const [0, 0.45, 1],
    );
  }
}

/// Animation source for the glittering liquid: time plus smoothed device
/// tilt. Runs only while something is listening.
class PaintMotion extends ChangeNotifier {
  PaintMotion._();

  static final instance = PaintMotion._();

  Ticker? _ticker;
  StreamSubscription<AccelerometerEvent>? _tilt;
  int _listeners = 0;

  double _time = 0;
  Offset _light = Offset.zero;
  Offset _target = Offset.zero;
  Offset? _baseline;

  double get time => _time;
  Offset get light => _light;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (++_listeners == 1) _start();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (--_listeners == 0) _stop();
  }

  void _start() {
    if (!RoyalPaint.enabled) return;
    _ticker = Ticker(_onTick)..start();
    try {
      _tilt =
          accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
              .listen(
                _onTilt,
                onError: (Object _) => _tilt = null,
                cancelOnError: true,
              );
    } on Object catch (_) {
      _tilt = null;
    }
  }

  void _stop() {
    _ticker?.dispose();
    _ticker = null;
    _tilt?.cancel();
    _tilt = null;
  }

  void _onTilt(AccelerometerEvent e) {
    final raw = Offset(e.x, e.y);
    // Re-centre slowly on how the phone is held, so the light reacts to
    // movement rather than to a fixed posture.
    final base = _baseline == null ? raw : Offset.lerp(_baseline, raw, 0.02)!;
    _baseline = base;
    final delta = raw - base;
    _target = Offset(
      (-delta.dx / 3.5).clamp(-1.0, 1.0),
      (delta.dy / 3.5).clamp(-1.0, 1.0),
    );
  }

  void _onTick(Duration elapsed) {
    _time = elapsed.inMicroseconds / 1e6;
    _light = Offset.lerp(_light, _target, 0.08)!;
    notifyListeners();
  }
}

/// Whether painted surfaces should animate here.
bool paintShouldAnimate(BuildContext context) =>
    RoyalPaint.enabled && !MediaQuery.disableAnimationsOf(context);
