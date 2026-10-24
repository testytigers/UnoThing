import 'dart:async';

import 'package:the_one_thing/widgets/mascot/mascot.dart';
import 'package:the_one_thing/widgets/paint/royal_paint.dart';

/// Runs before every test file: static gradient paint, a still mascot, no
/// motion or sensors, so goldens are deterministic and pumpAndSettle settles.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  RoyalPaint.enabled = false;
  Mascot.ambient = false;
  await testMain();
}
