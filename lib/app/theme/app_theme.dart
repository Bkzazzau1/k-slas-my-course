import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'text_theme.dart';

class AppTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: ColorTokens.primary,
      primary: ColorTokens.primary,
      secondary: ColorTokens.secondary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: ColorTokens.bgLight,
      textTheme: AppTextTheme.base(ThemeData.light().textTheme),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: ColorTokens.primary,
      primary: ColorTokens.primary,
      secondary: ColorTokens.secondary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: ColorTokens.bgDark,
      textTheme: AppTextTheme.base(ThemeData.dark().textTheme),
    );
  }
}
