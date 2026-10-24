import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/time/local_date.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/duration_format.dart';
import '../../../widgets/cup/day_cup.dart';
import '../../../widgets/dock/morphing_dock.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/mascot/coach_bubble.dart';
import '../../../widgets/mascot/mascot.dart';

export '../../../widgets/mascot/coach_bubble.dart' show CoachBubble;
export '../../../widgets/mascot/mascot.dart' show MascotMood;

/// Shared layout for Frames 8, 11, 12, 13 and 14: the date, the mascot's
/// message on top, then a large cup and the timer. Their actions live in the
/// dock below.
class SessionLayout extends StatelessWidget {
  const SessionLayout({
    super.key,
    required this.goalId,
    required this.date,
    required this.cup,
    required this.seconds,
    this.alertTimer = false,
    this.message,
  });

  /// With [date], ties the cup to the Shelf's for the Hero flight.
  final int goalId;
  final LocalDate date;
  final Widget cup;
  final int seconds;

  /// Shows the timer in the alert color (spilled days).
  final bool alertTimer;

  /// The mascot speaking (or a verdict), pinned on top like on Home.
  final Widget? message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: Text(shortDate(date))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xs,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: message,
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, viewport) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                      ),
                      child: ConstrainedBox(
                        // Centred when it fits, scrolls when it doesn't.
                        constraints: BoxConstraints(
                          minHeight: viewport.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            Hero(tag: cupHeroTag(goalId, date), child: cup),
                            const SizedBox(height: AppSpacing.lg),
                            Semantics(
                              label: 'Time',
                              value: formatTimer(seconds),
                              excludeSemantics: true,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AnimatedDefaultTextStyle(
                                  duration: AppDurations.medium,
                                  style: AppText.timer.copyWith(
                                    color: alertTimer ? t.danger : t.ink,
                                  ),
                                  child: Text(formatTimer(seconds)),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MorphingDock.reserve),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A day's verdict on top (Frames 13 and 14): a big title in the mascot's
/// voice, then the mascot explaining.
class SessionMessage extends StatelessWidget {
  const SessionMessage({
    super.key,
    required this.title,
    required this.mood,
    this.body,
    this.titleColor,
  });

  final String title;
  final MascotMood mood;
  final String? body;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppText.display.copyWith(color: titleColor ?? t.ink),
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            CoachBubble(text: body!, mood: mood),
          ],
        ],
      ),
    );
  }
}
