import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/theme.dart';

import 'dart:math' as math;

import 'package:the_one_thing/widgets/cup/cup_painter.dart';
import 'package:the_one_thing/widgets/cup/cup_widget.dart';

import '../../helpers/fonts.dart';

Widget _frame(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildAppTheme(),
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: const ValueKey('golden'),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    ),
  ),
);

Future<void> _golden(WidgetTester tester, Widget cup, String name) async {
  await tester.pumpWidget(_frame(cup));
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(const ValueKey('golden')),
    matchesGoldenFile('goldens/$name.png'),
  );
}

CupPainter _painterOf(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
        as CupPainter;

void main() {
  setUpAll(loadAppFonts);

  group('goldens, medium', () {
    testWidgets(
      'ghost',
      (t) => _golden(
        t,
        const CupWidget(fill: 0, state: CupState.ghost),
        'medium_ghost',
      ),
    );
    testWidgets(
      'empty',
      (t) => _golden(
        t,
        const CupWidget(fill: 0, state: CupState.empty),
        'medium_empty',
      ),
    );
    testWidgets(
      'filled 40%',
      (t) => _golden(
        t,
        const CupWidget(fill: 0.4, state: CupState.filled),
        'medium_filled_40',
      ),
    );
    testWidgets(
      'filled, target reached',
      (t) => _golden(
        t,
        const CupWidget(fill: 1.4, state: CupState.filled),
        'medium_filled_reached',
      ),
    );
    testWidgets(
      'spilled',
      (t) => _golden(
        t,
        const CupWidget(fill: 0, state: CupState.spilled),
        'medium_spilled',
      ),
    );
    testWidgets(
      'rest',
      (t) => _golden(
        t,
        const CupWidget(fill: 0, state: CupState.rest),
        'medium_rest',
      ),
    );
  });

  group('goldens, large with thresholds', () {
    testWidgets(
      'filled 48% of a 25 min target',
      (t) => _golden(
        t,
        const CupWidget(
          fill: 0.48,
          state: CupState.filled,
          size: CupSize.large,
          showThresholds: true,
          dailyTargetSeconds: 1500,
        ),
        'large_thresholds_filled',
      ),
    );

    testWidgets(
      'empty with a 1h 30min target',
      (t) => _golden(
        t,
        const CupWidget(
          fill: 0,
          state: CupState.empty,
          size: CupSize.large,
          showThresholds: true,
          dailyTargetSeconds: 5400,
        ),
        'large_thresholds_empty',
      ),
    );

    testWidgets(
      'spilled',
      (t) => _golden(
        t,
        const CupWidget(fill: 0, state: CupState.spilled, size: CupSize.large),
        'large_spilled',
      ),
    );
  });

  testWidgets(
    'golden, mini row of every state',
    (t) => _golden(
      t,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupWidget(fill: 0, state: CupState.ghost, size: CupSize.mini),
          CupWidget(fill: 0, state: CupState.empty, size: CupSize.mini),
          CupWidget(fill: 0.5, state: CupState.filled, size: CupSize.mini),
          CupWidget(fill: 1, state: CupState.filled, size: CupSize.mini),
          CupWidget(fill: 0, state: CupState.spilled, size: CupSize.mini),
          CupWidget(fill: 0, state: CupState.rest, size: CupSize.mini),
        ],
      ),
      'mini_all_states',
    ),
  );

  testWidgets('golden, running wave at a fixed frame', (tester) async {
    await tester.pumpWidget(
      _frame(
        const CupWidget(
          fill: 0.6,
          state: CupState.filled,
          size: CupSize.large,
          showThresholds: true,
          dailyTargetSeconds: 1500,
          running: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile('goldens/large_running_wave.png'),
    );
  });

  group('behavior', () {
    testWidgets('fill above 1 is capped visually but keeps the reached rim', (
      tester,
    ) async {
      await tester.pumpWidget(
        _frame(const CupWidget(fill: 3, state: CupState.filled)),
      );
      await tester.pumpAndSettle();
      expect(_painterOf(tester).fill, 1.0);
    });

    testWidgets('liquid animates from initialFill up to fill (Frame 10)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _frame(
          const CupWidget(fill: 0.8, initialFill: 0.2, state: CupState.filled),
        ),
      );
      expect(_painterOf(tester).fill, closeTo(0.2, 0.01));
      // A drop falls in first; the level starts moving as it lands.
      await tester.pump(const Duration(milliseconds: 300));
      expect(_painterOf(tester).fill, closeTo(0.2, 0.01));
      await tester.pump(const Duration(milliseconds: 400));
      final mid = _painterOf(tester).fill;
      expect(mid, greaterThan(0.2));
      expect(mid, lessThan(0.8));
      await tester.pumpAndSettle();
      expect(_painterOf(tester).fill, closeTo(0.8, 0.001));
    });

    testWidgets('wave runs only while running and settles flat', (
      tester,
    ) async {
      Widget cup(bool running) => _frame(
        CupWidget(
          fill: 0.5,
          state: CupState.filled,
          size: CupSize.large,
          running: running,
        ),
      );
      await tester.pumpWidget(cup(true));
      await tester.pump(const Duration(seconds: 1));
      expect(_painterOf(tester).waveStrength, closeTo(1, 0.001));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(cup(false));
      await tester.pumpAndSettle();
      expect(_painterOf(tester).waveStrength, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('mini cups never animate', (tester) async {
      await tester.pumpWidget(
        _frame(
          const CupWidget(
            fill: 0.5,
            state: CupState.filled,
            size: CupSize.mini,
            running: true,
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('semantic label is exposed', (tester) async {
      await tester.pumpWidget(
        _frame(
          const CupWidget(
            fill: 0.5,
            state: CupState.filled,
            semanticLabel: '6 December, 12 minutes, saved',
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('6 December, 12 minutes, saved'),
        findsOneWidget,
      );
    });

    testWidgets('crossing the safety net plays the gold pulse', (tester) async {
      Widget cup(double fill, {bool running = true}) => _frame(
        CupWidget(
          fill: fill,
          state: CupState.filled,
          size: CupSize.large,
          showThresholds: true,
          dailyTargetSeconds: 1200, // safety net at 0.25
          running: running,
        ),
      );
      await tester.pumpWidget(cup(0.24));
      expect(_painterOf(tester).celebration, isNull);
      await tester.pumpWidget(cup(0.26));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painterOf(tester).celebration, CupCelebration.saved);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reaching the goal draws the gold rim', (tester) async {
      Widget cup(double fill) => _frame(
        CupWidget(
          fill: fill,
          state: CupState.filled,
          size: CupSize.large,
          showThresholds: true,
          dailyTargetSeconds: 1200,
          running: true,
        ),
      );
      await tester.pumpWidget(cup(0.99));
      await tester.pumpWidget(cup(1.0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painterOf(tester).celebration, CupCelebration.full);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no moments when not running (e.g. Adjust time)', (
      tester,
    ) async {
      Widget cup(double fill) => _frame(
        CupWidget(
          fill: fill,
          state: CupState.filled,
          size: CupSize.large,
          showThresholds: true,
          dailyTargetSeconds: 1200,
        ),
      );
      await tester.pumpWidget(cup(0.1));
      await tester.pumpWidget(cup(1.0));
      await tester.pumpAndSettle();
      expect(_painterOf(tester).celebration, isNull);
    });

    testWidgets(
      'after a save one drop falls in, then the liquid rises; no bar from '
      'the top, and nothing more during a live session',
      (tester) async {
        Widget cup(double fill, {bool running = false}) => _frame(
          CupWidget(
            key: const ValueKey('hero'),
            fill: fill,
            initialFill: 0.1,
            state: CupState.filled,
            size: CupSize.large,
            showThresholds: true,
            dailyTargetSeconds: 1200,
            running: running,
          ),
        );
        await tester.pumpWidget(cup(0.4));
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Falling: the level waits for it.
        final falling = _painterOf(tester);
        expect(falling.landing!.value, inExclusiveRange(0, 1));
        expect(falling.fill, closeTo(0.1, 1e-9));

        // Landed: the level starts to rise.
        await tester.pump(const Duration(milliseconds: 500));
        expect(_painterOf(tester).fill, greaterThan(0.1));

        await tester.pumpAndSettle();
        expect(_painterOf(tester).landing!.value, 1);
        expect(_painterOf(tester).fill, closeTo(0.4, 1e-9));

        // A session starts and the level creeps up: no drop comes back.
        await tester.pumpWidget(cup(0.42, running: true));
        await tester.pump(const Duration(milliseconds: 200));
        expect(_painterOf(tester).landing!.value, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );

    test('the wave loops without a seam', () {
      for (var k = 0.0; k < 12; k += 0.37) {
        expect(
          surfaceOffset(k, 2 * math.pi),
          closeTo(surfaceOffset(k, 0), 1e-9),
        );
      }
    });

    testWidgets('a running cup glides linearly between ticks', (tester) async {
      Widget cup(double fill) => _frame(
        CupWidget(
          fill: fill,
          state: CupState.filled,
          size: CupSize.large,
          running: true,
        ),
      );
      await tester.pumpWidget(cup(0.40));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(cup(0.50));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_painterOf(tester).fill, closeTo(0.45, 0.002));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
