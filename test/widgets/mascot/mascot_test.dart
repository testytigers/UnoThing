import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/theme.dart';
import 'package:the_one_thing/widgets/mascot/coach_bubble.dart';
import 'package:the_one_thing/widgets/mascot/mascot.dart';
import 'package:the_one_thing/widgets/mascot/mascot_painter.dart';

import '../../helpers/fonts.dart';

Widget _frame(Widget child, {double width = 412}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildAppTheme(),
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: const ValueKey('golden'),
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('golden, every mood', (tester) async {
    await tester.pumpWidget(
      _frame(
        Wrap(
          children: [
            for (final mood in MascotMood.values) Mascot(mood: mood, size: 100),
          ],
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile('goldens/moods.png'),
    );
  });

  testWidgets('golden, peeking with content on its body', (tester) async {
    await tester.pumpWidget(
      _frame(
        MascotPeek(
          mood: MascotMood.sparkle,
          child: Container(
            height: 120,
            margin: const EdgeInsets.all(20),
            color: AppTokens.light.surface,
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile('goldens/peek.png'),
    );
  });

  testWidgets('peek lays its child below the face', (tester) async {
    await tester.pumpWidget(
      _frame(
        const MascotPeek(
          mood: MascotMood.idle,
          child: SizedBox(key: ValueKey('belly'), height: 50),
        ),
      ),
    );
    final top = tester.getTopLeft(find.byKey(const ValueKey('belly'))).dy;
    final peek = tester.getTopLeft(find.byType(MascotPeek)).dy;
    expect(top - peek, closeTo(412 * 0.46, 0.5));
  });

  testWidgets('is decorative: hidden from screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _frame(
        const CoachBubble(
          text: 'Day saved. Nothing can spill it now.',
          mood: MascotMood.happy,
        ),
        width: 300,
      ),
    );
    expect(
      find.bySemanticsLabel('Day saved. Nothing can spill it now.'),
      findsOneWidget,
    );
    expect(find.byType(ExcludeSemantics), findsWidgets);
    semantics.dispose();
  });

  testWidgets('still in tests and with reduce motion; settles', (tester) async {
    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
    expect(tester.hasRunningAnimations, isFalse);
    // Changing mood mid-life is safe.
    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.sparkle)));
    await tester.pumpAndSettle();
  });

  testWidgets('alive outside tests: blinks and breathes on a ticker', (
    tester,
  ) async {
    Mascot.ambient = true;
    addTearDown(() => Mascot.ambient = false);
    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);

    // Reduce motion stops it.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a new mood spins in: the face swaps while it looks away', (
    tester,
  ) async {
    Mascot.ambient = true;
    addTearDown(() => Mascot.ambient = false);
    MascotPose pose() =>
        (tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: find.byType(Mascot),
                        matching: find.byType(CustomPaint),
                      ),
                    )
                    .painter!
                as MascotPainter)
            .pose();

    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.angry)));
    await tester.pump(const Duration(milliseconds: 150));
    expect(pose().mood, MascotMood.idle);
    expect(pose().turn, greaterThan(0));
    expect(pose().hop, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 400));
    expect(pose().mood, MascotMood.angry);

    await tester.pump(const Duration(milliseconds: 400));
    expect(pose().hop, 0);
    expect(pose().turn.abs(), lessThan(0.5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with reduce motion the new mood shows at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    Mascot.ambient = true;
    addTearDown(() => Mascot.ambient = false);
    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
    await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.cool)));
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(Mascot),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as MascotPainter;
    expect(painter.pose().mood ?? painter.mood, MascotMood.cool);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'the outline boils like a hand-drawn line, eight times a second',
    (tester) async {
      Mascot.ambient = true;
      addTearDown(() => Mascot.ambient = false);
      MascotPose pose() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(Mascot),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter!
                  as MascotPainter)
              .pose();
      await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
      await tester.pump(const Duration(milliseconds: 300));
      final first = pose().boil;
      expect(first, isNotNull);
      await tester.pump(const Duration(milliseconds: 260));
      expect(pose().boil, greaterThan(first!));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('still when not alive: no boil, resting at its facing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _frame(const Mascot(mood: MascotMood.idle, facing: 0.4)),
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(Mascot),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as MascotPainter;
    expect(painter.pose().boil, isNull);
    expect(painter.pose().turn, 0.4);
  });

  testWidgets('glancing on the login peek never slides the eyes off the drop', (
    tester,
  ) async {
    // A glance only squeezes the face a little (three-quarter view); an eye
    // sliding off the drop's edge would lose a big share of the ink.
    Future<int> ink(double turn) async {
      final recorder = PictureRecorder();
      MascotPainter(
        mood: MascotMood.idle,
        tokens: AppTokens.light,
        frame: MascotFrame.peek,
        pose: () => MascotPose(turn: turn, look: const Offset(0.8, 0.9)),
      ).paint(Canvas(recorder), const Size(412, 300));
      final bytes = (await tester.runAsync(() async {
        final image = await recorder.endRecording().toImage(412, 300);
        return image.toByteData();
      }))!;
      var count = 0;
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) < 60 &&
            bytes.getUint8(i + 1) < 60 &&
            bytes.getUint8(i + 2) < 80 &&
            bytes.getUint8(i + 3) > 200) {
          count++;
        }
      }
      return count;
    }

    final front = await ink(0);
    for (final turn in [0.45, -0.45]) {
      expect(await ink(turn), greaterThan(front * 0.85), reason: 'turn $turn');
    }
  });

  group('the face is alive, not one rigid stamp', () {
    MascotPose pose(WidgetTester tester) =>
        (tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: find.byType(Mascot),
                        matching: find.byType(CustomPaint),
                      ),
                    )
                    .painter!
                as MascotPainter)
            .pose();

    setUp(() => Mascot.ambient = true);
    tearDown(() => Mascot.ambient = false);

    testWidgets('it talks when its message changes, then closes its mouth', (
      tester,
    ) async {
      await tester.pumpWidget(
        _frame(const Mascot(mood: MascotMood.idle, talkKey: 'a')),
      );
      // Says hello on arrival.
      await tester.pump(const Duration(milliseconds: 500));
      expect(pose(tester).talk, isNotNull);
      await tester.pump(const Duration(seconds: 2));
      expect(pose(tester).talk, isNull);

      await tester.pumpWidget(
        _frame(const Mascot(mood: MascotMood.idle, talkKey: 'b')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(pose(tester).talk, isNotNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('during a spin the mouth trails the eyes, a little', (
      tester,
    ) async {
      await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.happy)));
      await tester.pump(const Duration(milliseconds: 200));
      final p = pose(tester);
      final lag = p.turn - p.mouthTurn!;
      expect(lag, greaterThan(0.02));
      expect(lag, lessThanOrEqualTo(0.3 + 1e-9));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('after the spin, the mouth catches up without unwinding', (
      tester,
    ) async {
      await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.idle)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_frame(const Mascot(mood: MascotMood.happy)));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        final p = pose(tester);
        final gap = (p.turn - p.mouthTurn!).abs();
        expect(gap, lessThanOrEqualTo(0.3 + 1e-9));
      }
      await tester.pumpWidget(const SizedBox());
    });
  });
}
