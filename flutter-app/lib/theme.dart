import 'package:flutter/material.dart';

/// Tashya Labs brand palette, plus one signature accent per tool — mirrors
/// the web prototype so the Play Store app and the browser tools feel like
/// the same product. See PROJECT-NOTES.md for the full brand reference.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0F172A);
  static const gray = Color(0xFF475569);
  static const offWhite = Color(0xFFFFFBFB);

  static const merge = Color(0xFFDC2626); // PDF red
  static const split = Color(0xFF7C3AED); // purple
  static const compress = Color(0xFF0D9488); // teal
  static const unlock = Color(0xFFB45309); // amber

  static const bad = Color(0xFFDC2626);
}

ThemeData buildAppTheme({required Brightness brightness, Color? seed}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed ?? AppColors.merge,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF0A1120)
        : AppColors.offWhite,
    // Using the system font for now rather than declaring 'Manrope' without
    // bundling it — that would silently fall back with no error. To match
    // the brand exactly, drop the four Manrope .ttf weights (from the logo
    // pack) into assets/fonts/, register them in pubspec.yaml under
    // flutter > fonts, and set fontFamily: 'Manrope' here.
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF111A2E) : Colors.white,
      foregroundColor: isDark ? AppColors.offWhite : AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? const Color(0xFF111A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
    ),
  );
}

/// Wraps a tool screen so every FilledButton, active icon, progress bar, etc.
/// inside it picks up that tool's signature color as the theme's primary —
/// the same trick the web prototype does with a single CSS --accent token.
class ToolAccent extends StatelessWidget {
  const ToolAccent({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(primary: color, secondary: color);
    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: color),
      ),
      child: child,
    );
  }
}
