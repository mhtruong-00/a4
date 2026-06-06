import 'package:flutter/material.dart';

/// Central place for the app's colours and theme. The window / floor / quote
/// tints echo the colour coding I used in my iOS app so the sections feel the
/// same across both versions.
class AppColors {
  static const Color seed = Color(0xFF3F51B5); // indigo
  static const Color windowTint = Color(0xFF1565C0); // blue
  static const Color floorTint = Color(0xFFEF6C00); // orange
  static const Color quoteTint = Color(0xFF00695C); // teal
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
  );
}

