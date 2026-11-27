/// FitOrSkip design system: "The Hang Tag".
///
/// The costume is the clothing hang tag: warm paper surfaces, ink text, a
/// petrol and marigold tailor palette, and verdicts delivered as a stamped
/// tag. The engine under the costume is the Bagay Verdict card, which is
/// styled as that tag everywhere it appears: result screen and history.
library;

import 'package:material_ui/material_ui.dart';

import 'verdict/verdict_engine.dart';

class FitColors {
  static const Color paper = Color(0xFFFAF5EC);
  static const Color paperDark = Color(0xFF16130F);
  static const Color ink = Color(0xFF211A15);
  static const Color inkOnDark = Color(0xFFF2EAD9);
  static const Color petrol = Color(0xFF0E5A52);
  static const Color petrolBright = Color(0xFF3FA08F);
  static const Color marigold = Color(0xFFE39A2D);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF221E19);
  static const Color lineLight = Color(0xFFE3D9C6);
  static const Color lineDark = Color(0xFF3A342B);

  static Color bandColor(VerdictBand band, {required bool dark}) =>
      switch (band) {
        VerdictBand.bagay =>
          dark ? const Color(0xFF4CC07A) : const Color(0xFF1E7A46),
        VerdictBand.pwedePa =>
          dark ? const Color(0xFFE8B04B) : const Color(0xFFB97F0E),
        VerdictBand.diliBagay =>
          dark ? const Color(0xFFEF7D6B) : const Color(0xFFB3382E),
      };
}

class FitTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: FitColors.petrol,
      brightness: brightness,
    ).copyWith(
      primary: dark ? FitColors.petrolBright : FitColors.petrol,
      secondary: FitColors.marigold,
      surface: dark ? FitColors.cardDark : FitColors.cardLight,
      onSurface: dark ? FitColors.inkOnDark : FitColors.ink,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor:
          dark ? FitColors.paperDark : FitColors.paper,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? FitColors.paperDark : FitColors.paper,
        foregroundColor: dark ? FitColors.inkOnDark : FitColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: dark ? FitColors.inkOnDark : FitColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? FitColors.cardDark : FitColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: dark ? FitColors.lineDark : FitColors.lineLight,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? FitColors.cardDark : FitColors.cardLight,
        indicatorColor: FitColors.marigold.withValues(alpha: 0.35),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: dark ? FitColors.inkOnDark : FitColors.ink,
          ),
        ),
      ),
    );
    // Explicit ink colors on every style: the verdict card and headings
    // must never depend on a null-color inheritance chain resolving
    // differently across runtimes.
    final inkColor = dark ? FitColors.inkOnDark : FitColors.ink;
    final textTheme = base.textTheme
        .copyWith(
          headlineMedium: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: const TextStyle(fontSize: 14.5, height: 1.4),
          bodySmall: const TextStyle(fontSize: 12.5, height: 1.35),
        )
        .apply(bodyColor: inkColor, displayColor: inkColor);
    return base.copyWith(textTheme: textTheme);
  }
}
