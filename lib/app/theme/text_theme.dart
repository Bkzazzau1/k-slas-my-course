import 'package:flutter/material.dart';

class AppTextTheme {
  static TextTheme base(TextTheme t) {
    return t.copyWith(
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: t.bodyMedium?.copyWith(height: 1.3),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
