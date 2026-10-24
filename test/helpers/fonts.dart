import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled fonts (Inter weights and Rubik) so goldens render real
/// glyphs.
Future<void> loadAppFonts() async {
  final inter = FontLoader('Inter');
  for (final weight in [
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    inter.addFont(_font('assets/fonts/Inter-$weight.ttf'));
  }
  await inter.load();
  await (FontLoader(
    'Rubik',
  )..addFont(_font('assets/fonts/Rubik-ExtraBold.ttf'))).load();
}

Future<ByteData> _font(String path) =>
    Future.value(ByteData.sublistView(File(path).readAsBytesSync()));
