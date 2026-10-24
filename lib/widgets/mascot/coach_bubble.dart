import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'mascot.dart';

/// The mascot saying [text] from a white speech bubble. The bubble
/// cross-fades only when the message changes, not when a countdown in it
/// ticks.
class CoachBubble extends StatelessWidget {
  const CoachBubble({
    super.key,
    required this.text,
    required this.mood,
    this.mascotSize = 56,
  });

  final String text;
  final MascotMood mood;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final kind = text.replaceAll(RegExp(r'[0-9:]'), '');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Mascot(mood: mood, size: mascotSize, facing: 0.4, talkKey: kind),
        const SizedBox(width: 2),
        Flexible(
          child: CustomPaint(
            painter: _BubblePainter(color: t.surface),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _BubblePainter.tail + 14,
                12,
                16,
                12,
              ),
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
                    text,
                    key: ValueKey(kind),
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
        ),
      ],
    );
  }
}

/// Rounded bubble with a little tail on the left, near the mascot's mouth.
class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color});

  final Color color;

  static const tail = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(
        RRect.fromLTRBR(
          tail,
          0,
          size.width,
          size.height,
          const Radius.circular(20),
        ),
      );
    final y = (size.height - 20).clamp(16.0, size.height - 12);
    final point = Path()
      ..moveTo(tail + 6, y - 9)
      ..quadraticBezierTo(tail * 0.6, y - 1, 0, y + 5)
      ..quadraticBezierTo(tail * 0.9, y + 6, tail + 8, y + 5)
      ..close();
    canvas.drawPath(
      Path.combine(PathOperation.union, body, point),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
