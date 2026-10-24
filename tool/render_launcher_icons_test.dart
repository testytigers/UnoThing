// Renders the Android launcher icons from the mascot. Run after changing
// the mascot:
//
//   flutter test tool/render_launcher_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_one_thing/app/theme.dart';
import 'package:the_one_thing/widgets/mascot/mascot_painter.dart';

const _res = 'android/app/src/main/res';

/// Legacy icon px per density, and adaptive layer px (108 dp).
const _densities = {
  'mdpi': (48, 108),
  'hdpi': (72, 162),
  'xhdpi': (96, 216),
  'xxhdpi': (144, 324),
  'xxxhdpi': (192, 432),
};

/// The whole drop in its shades, standing on its shadow, inside the 66 dp
/// safe zone that every launcher mask keeps.
class _MascotLayer extends StatelessWidget {
  const _MascotLayer({this.monochrome});

  final Color? monochrome;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: 70,
      child: CustomPaint(
        painter: MascotPainter(
          mood: MascotMood.cool,
          tokens: AppTokens.light,
          pose: () => const MascotPose(turn: 0.3),
          monochrome: monochrome,
        ),
      ),
    ),
  );
}

Future<void> _render(
  WidgetTester tester,
  Widget child,
  int px,
  String path,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: SizedBox.square(dimension: 108, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: px / 108);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  testWidgets('render launcher icons', (tester) async {
    const t = AppTokens.light;
    for (final MapEntry(key: dpi, value: (legacy, adaptive))
        in _densities.entries) {
      final dir = '$_res/mipmap-$dpi';
      // Adaptive background: the cream canvas.
      await _render(
        tester,
        ColoredBox(color: t.background),
        adaptive,
        '$dir/ic_launcher_background.png',
      );
      await _render(
        tester,
        const _MascotLayer(),
        adaptive,
        '$dir/ic_launcher_foreground.png',
      );
      await _render(
        tester,
        const _MascotLayer(monochrome: Color(0xFFFFFFFF)),
        adaptive,
        '$dir/ic_launcher_monochrome.png',
      );
      // Legacy (pre-Android 8) icon: the same, on a rounded tile.
      await _render(
        tester,
        Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: t.background,
              child: const Center(
                child: SizedBox.square(dimension: 80, child: _MascotLayer()),
              ),
            ),
          ),
        ),
        legacy,
        '$dir/ic_launcher.png',
      );
    }
  });
}
