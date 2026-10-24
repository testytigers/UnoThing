import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/theme.dart';
import 'package:the_one_thing/widgets/dock/morphing_dock.dart';

Widget _frame(List<DockItem> items) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: MorphingDock(items: items),
    ),
  ),
);

DockItem _icon(String id) =>
    DockItem(id: id, icon: Icons.circle, semanticLabel: id, onTap: () {});

/// A slot's width, without its 2 px margins.
double _width(WidgetTester tester, String id) =>
    tester.getSize(find.byKey(ValueKey(id))).width - 4;

void main() {
  testWidgets('a pill that loses its label folds into a circle in place', (
    tester,
  ) async {
    final pill = DockItem(
      id: 'toggle',
      playing: false,
      label: 'Start pouring',
      filled: true,
      semanticLabel: 'Start pouring',
      onTap: () {},
    );
    await tester.pumpWidget(_frame([_icon('horizon'), pill, _icon('bell')]));
    await tester.pumpAndSettle();
    final wide = _width(tester, 'toggle');
    expect(wide, greaterThan(100));

    final round = DockItem(
      id: 'toggle',
      playing: true,
      filled: true,
      semanticLabel: 'Pause',
      onTap: () {},
    );
    await tester.pumpWidget(_frame([round, _icon('finish')]));
    await tester.pump(const Duration(milliseconds: 150));
    // Mid-morph: the same slot, narrowing; the leaving buttons still there.
    final mid = _width(tester, 'toggle');
    expect(mid, lessThan(wide));
    expect(mid, greaterThan(52));
    expect(find.byKey(const ValueKey('horizon')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(_width(tester, 'toggle'), 52);
    expect(find.byKey(const ValueKey('horizon')), findsNothing);
    expect(find.byKey(const ValueKey('bell')), findsNothing);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    expect(find.bySemanticsLabel('finish'), findsOneWidget);
  });

  testWidgets('new buttons grow in from nothing', (tester) async {
    await tester.pumpWidget(_frame([_icon('a')]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_frame([_icon('a'), _icon('b')]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getSize(find.byKey(const ValueKey('b'))).width, lessThan(52));
    await tester.pumpAndSettle();
    expect(_width(tester, 'b'), 52);
  });

  testWidgets('with no buttons the dock sinks away and ignores taps', (
    tester,
  ) async {
    await tester.pumpWidget(_frame([_icon('a')]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_frame(const []));
    await tester.pumpAndSettle();
    final opacity = tester.widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(MorphingDock),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(opacity.opacity, 0);
    expect(find.bySemanticsLabel('a'), findsNothing);
  });

  testWidgets('a disabled button says so and does nothing', (tester) async {
    await tester.pumpWidget(
      _frame(const [
        DockItem(
          id: 'toggle',
          label: 'Rest day',
          filled: true,
          semanticLabel: 'Rest day',
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Rest day')),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
  });
}
