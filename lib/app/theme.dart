import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Raw palette. Only this file may reference these values directly; widgets
/// read colors through [AppTokens] or the [ColorScheme].
abstract final class _Palette {
  // Cream canvas and white tiles.
  static const cream = Color(0xFFF6F2EA);
  static const creamDeep = Color(0xFFECE6DA);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1B2E);
  static const stone = Color(0xFF6F6B66);
  static const pebble = Color(0xFFA8A39A);
  static const hairline = Color(0xFFE9E3D7);
  static const hairlineStrong = Color(0xFFD5CEC0);

  // Brand periwinkle: the mascot, selections, progress. Light enough for
  // the mascot's black face (5.5:1) and for ink text on it.
  static const periwinkle = Color(0xFF6A8DFF);
  static const periwinkleSoft = Color(0xFFE4EAFF);

  // Periwinkle deep enough for text on white and cream.
  static const periwinkleInk = Color(0xFF3B5BDB);

  // Buttons: soft ink, never pure black.
  static const button = Color(0xFF26283D);

  // The cup's flake paint: richer than the brand, same family.
  static const paintDeep = Color(0xFF16248A);
  static const paint = Color(0xFF2E52DE);
  static const paintBright = Color(0xFF7F9DFF);
  static const paintGlow = Color(0xFFB9C8FF);

  // The glass.
  static const glassInner = Color(0xFFE9EDF9);
  static const glassEdge = Color(0xFFCBD3EA);
  static const flakeSilver = Color(0xFFEFF3FF);
  static const flakeViolet = Color(0xFFC9B8FF);

  // Accents.
  static const gold = Color(0xFFE2B33C);
  static const goldBright = Color(0xFFF6D77E);
  static const goldInk = Color(0xFF94701A);
  static const coral = Color(0xFFF2564A);
  static const coralSoft = Color(0xFFFF8A7E);

  /// Coral dark enough for text: 5.4:1 on white, 4.9:1 on cream.
  static const coralInk = Color(0xFFC0392B);
  static const blush = Color(0xFFFF8FA3);
}

/// Design tokens exposed to widgets via `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.border,
    required this.borderStrong,
    required this.brand,
    required this.brandSoft,
    required this.brandInk,
    required this.onBrand,
    required this.button,
    required this.onButton,
    required this.paintDeep,
    required this.paint,
    required this.paintBright,
    required this.paintGlow,
    required this.flakeA,
    required this.flakeB,
    required this.gold,
    required this.goldBright,
    required this.goldInk,
    required this.danger,
    required this.dangerSoft,
    required this.dangerInk,
    required this.blush,
    required this.highlight,
    required this.cupGlass,
    required this.cupInner,
    required this.cupEdge,
    required this.milk,
    required this.shadow,
  });

  final Color background;

  /// Tracks and pressed tiles on the canvas.
  final Color backgroundDeep;
  final Color surface;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color border;
  final Color borderStrong;

  /// Periwinkle: the mascot's body, selected tiles, progress, today.
  final Color brand;
  final Color brandSoft;

  /// Brand-colored text and links on white or cream.
  final Color brandInk;

  /// Text and icons on [brand]: ink, for contrast.
  final Color onBrand;

  /// Primary button fill.
  final Color button;
  final Color onButton;

  /// The cup's flake paint (shadow, body, highlight, glow). Only the liquid
  /// and the falling drop glitter.
  final Color paintDeep;
  final Color paint;
  final Color paintBright;
  final Color paintGlow;

  /// Flake tints mixed into the paint.
  final Color flakeA;
  final Color flakeB;

  /// Gold: target line, full-cup rim, sparkles. [goldInk] for gold text.
  final Color gold;
  final Color goldBright;
  final Color goldInk;

  final Color danger;
  final Color dangerSoft;

  /// Danger as text (errors, destructive actions); [danger] is for shapes
  /// and big numbers.
  final Color dangerInk;

  /// The mascot's cheeks.
  final Color blush;

  /// Pure white glints: the mascot's tears and glare, the cup's shine.
  final Color highlight;

  /// The glass body, the inside of its far wall, and its edges.
  final Color cupGlass;
  final Color cupInner;
  final Color cupEdge;

  /// The spilled-milk puddle.
  final Color milk;
  final Color shadow;

  // Semantic aliases.
  Color get mascot => brand;
  Color get mascotInk => ink;
  Color get targetLine => gold;
  Color get minLine => danger;

  static const light = AppTokens(
    background: _Palette.cream,
    backgroundDeep: _Palette.creamDeep,
    surface: _Palette.white,
    ink: _Palette.ink,
    inkMuted: _Palette.stone,
    inkFaint: _Palette.pebble,
    border: _Palette.hairline,
    borderStrong: _Palette.hairlineStrong,
    brand: _Palette.periwinkle,
    brandSoft: _Palette.periwinkleSoft,
    brandInk: _Palette.periwinkleInk,
    onBrand: _Palette.ink,
    button: _Palette.button,
    onButton: _Palette.white,
    paintDeep: _Palette.paintDeep,
    paint: _Palette.paint,
    paintBright: _Palette.paintBright,
    paintGlow: _Palette.paintGlow,
    flakeA: _Palette.flakeSilver,
    flakeB: _Palette.flakeViolet,
    gold: _Palette.gold,
    goldBright: _Palette.goldBright,
    goldInk: _Palette.goldInk,
    danger: _Palette.coral,
    dangerSoft: _Palette.coralSoft,
    dangerInk: _Palette.coralInk,
    blush: _Palette.blush,
    highlight: _Palette.white,
    cupGlass: _Palette.white,
    cupInner: _Palette.glassInner,
    cupEdge: _Palette.glassEdge,
    milk: _Palette.white,
    shadow: _Palette.ink,
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) =>
      other is AppTokens && t >= 0.5 ? other : this;
}

/// Spacing, radii and sizes shared across screens.
abstract final class AppSpacing {
  static const gutter = 20.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const button = 16.0;
  static const tile = 16.0;
  static const input = 16.0;
  static const sheet = 28.0;
  static const card = 24.0;
}

abstract final class AppSizes {
  static const buttonHeight = 56.0;
  static const tileHeight = 56.0;
  static const maxContentWidth = 480.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const fill = Duration(milliseconds: 900);
  static const entrance = Duration(milliseconds: 520);
  static const stagger = Duration(milliseconds: 70);
}

const _sans = 'Inter';
const _display = 'Rubik';

/// Type scale. Rubik ExtraBold for headlines and big moments, Inter for
/// everything else. Numbers use tabular figures so they never jitter.
abstract final class AppText {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Biggest moment (Login).
  static const hero = TextStyle(
    fontFamily: _display,
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  );

  /// Screen titles and moments ("On target", "Horizon").
  static const display = TextStyle(
    fontFamily: _display,
    fontSize: 30,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  /// Section headlines, sheet titles, the goal on the Shelf.
  static const headline = TextStyle(
    fontFamily: _sans,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const title = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const body = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const bodyStrong = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static const label = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Small overline above titles.
  static const eyebrow = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  static const button = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const timer = TextStyle(
    fontFamily: _sans,
    fontSize: 64,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.5,
    fontFeatures: _tabular,
  );

  static const input = TextStyle(
    fontFamily: _sans,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static const wheel = TextStyle(
    fontFamily: _sans,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}

ThemeData buildAppTheme() {
  const t = AppTokens.light;

  final scheme = ColorScheme.fromSeed(seedColor: t.brand).copyWith(
    primary: t.brand,
    onPrimary: t.onBrand,
    secondary: t.gold,
    surface: t.background,
    onSurface: t.ink,
    onSurfaceVariant: t.inkMuted,
    outline: t.border,
    outlineVariant: t.border,
    error: t.danger,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: const BorderSide(color: Colors.transparent),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _sans,
    scaffoldBackgroundColor: t.background,
    canvasColor: t.background,
    splashFactory: InkSparkle.splashFactory,
    extensions: const [t],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.brand,
      selectionColor: t.brand.withValues(alpha: 0.25),
      selectionHandleColor: t.brand,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppText.title.copyWith(color: t.ink),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: t.ink),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.brandInk,
        textStyle: AppText.button,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: AppText.bodyStrong.copyWith(
        color: t.inkFaint,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: AppText.body.copyWith(color: t.inkMuted),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: t.brand, width: 2),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: t.danger),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: t.danger, width: 2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: t.borderStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      titleTextStyle: AppText.headline.copyWith(color: t.ink),
      contentTextStyle: AppText.body.copyWith(color: t.inkMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.button,
      contentTextStyle: AppText.bodyStrong.copyWith(color: t.onButton),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
    ),
    dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.brand),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
