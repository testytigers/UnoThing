import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'mascot.dart';

/// The mascot guiding a step: a full-width card with the mascot, what it
/// says right now, and a pie showing how far along you are.
class MascotGuide extends StatelessWidget {
  const MascotGuide({
    super.key,
    required this.message,
    required this.mood,
    required this.step,
    required this.steps,
  });

  final String message;
  final MascotMood mood;

  /// 1-based.
  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Mascot(mood: mood, size: 76, facing: 0.4, talkKey: message),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: AnimatedSize(
                duration: AppDurations.medium,
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    message,
                    key: ValueKey(message),
                    style: AppText.bodyStrong.copyWith(
                      color: t.ink,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          StepPie(step: step, steps: steps),
        ],
      ),
    );
  }
}

/// A ring that fills to [step] of [steps] on arrival, with "1/3" inside.
class StepPie extends StatelessWidget {
  const StepPie({super.key, required this.step, required this.steps});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Step $step of $steps',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 46,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: (step - 1) / steps, end: step / steps),
          duration: AppDurations.fill,
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => CustomPaint(
            painter: _PiePainter(
              value: v,
              track: t.backgroundDeep,
              fill: t.brand,
            ),
            child: child,
          ),
          child: Center(
            child: Text(
              '$step/$steps',
              style: AppText.label.copyWith(
                color: t.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({
    required this.value,
    required this.track,
    required this.fill,
  });

  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint..color = track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      paint..color = fill,
    );
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.value != value || old.track != track || old.fill != fill;
}
