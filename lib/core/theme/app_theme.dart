import 'package:flutter/material.dart';
import 'ui_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: UiTokens.primary,
      brightness: Brightness.light,
      primary: UiTokens.primary,
      secondary: UiTokens.secondary,
      surface: UiTokens.surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: UiTokens.bgLight,

      // Typography
      textTheme: _textTheme(scheme),

      // Card defaults (our cards are mostly Containers but keep this clean)
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiTokens.r20),
        ),
      ),

      // Buttons (premium default sizing)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiTokens.r14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiTokens.r14),
          ),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.22)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      // Inputs (lux)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.04),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.80)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.r16),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.r16),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.r16),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),

      // AppBar (simple, clean)
      appBarTheme: AppBarTheme(
        backgroundColor: UiTokens.bgLight.withValues(alpha: 0.96),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),

      // Switch (premium)
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return scheme.secondary.withValues(alpha: 0.35);
          }
          return scheme.onSurface.withValues(alpha: 0.12);
        }),
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return scheme.secondary;
          return scheme.onSurface.withValues(alpha: 0.60);
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.96),
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: scheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurface.withValues(alpha: 0.62),
        ),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.64),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: UiTokens.primary,
      brightness: Brightness.dark,
      primary: UiTokens.primary,
      secondary: UiTokens.secondary,
      surface: UiTokens.surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: UiTokens.bgDark,

      textTheme: _textTheme(scheme),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiTokens.r20),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiTokens.r14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiTokens.r14),
          ),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.06),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.82)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.r16),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.r16),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.r16),
          borderSide: BorderSide(
            color: scheme.secondary.withValues(alpha: 0.70),
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: UiTokens.bgDark.withValues(alpha: 0.96),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return scheme.secondary.withValues(alpha: 0.35);
          }
          return scheme.onSurface.withValues(alpha: 0.14);
        }),
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return scheme.secondary;
          return scheme.onSurface.withValues(alpha: 0.65);
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.96),
        indicatorColor: scheme.secondary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: scheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        indicatorColor: scheme.secondary.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: scheme.secondary),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurface.withValues(alpha: 0.62),
        ),
        selectedLabelTextStyle: TextStyle(
          color: scheme.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.64),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) {
    // Academic luxury typography
    return TextTheme(
      headlineLarge: UiTokens.h1(cs),
      headlineSmall: UiTokens.h2(cs),
      titleMedium: TextStyle(
        color: cs.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
      bodyMedium: UiTokens.body(cs),
      bodySmall: UiTokens.muted(cs),
      labelLarge: TextStyle(
        color: cs.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );
  }
}
