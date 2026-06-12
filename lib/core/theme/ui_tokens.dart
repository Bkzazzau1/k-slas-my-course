import 'package:flutter/material.dart';

class UiTokens {
  UiTokens._();

  // Brand palette (academic luxury)
  static const Color primary = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF10B981);

  // Surfaces
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0B1220);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF0F172A);

  // Optional warning/urgency
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Radius scale
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r18 = 18;
  static const double r20 = 20;
  static const double r22 = 22;

  // Spacing scale
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;

  // Borders / Shadows (premium subtle)
  static Color border(ColorScheme cs, {double alpha = 0.08}) =>
      cs.onSurface.withValues(alpha: alpha);

  static List<BoxShadow> softShadow() => [
        BoxShadow(
          blurRadius: 18,
          offset: const Offset(0, 10),
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ];

  static List<BoxShadow> glow(Color c) => [
        BoxShadow(
          blurRadius: 22,
          offset: const Offset(0, 12),
          color: c.withValues(alpha: 0.16),
        ),
      ];

  // Text styles helper (optional usage)
  static TextStyle h1(ColorScheme cs) => TextStyle(
        color: cs.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  static TextStyle h2(ColorScheme cs) => TextStyle(
        color: cs.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  static TextStyle body(ColorScheme cs) => TextStyle(
        color: cs.onSurface.withValues(alpha: 0.82),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle muted(ColorScheme cs) => TextStyle(
        color: cs.onSurface.withValues(alpha: 0.68),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );
}
