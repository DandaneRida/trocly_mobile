import 'package:flutter/material.dart';

class TroclyColors {
  static const primary = Color(0xFF6C5CE7);
  static const secondary = Color(0xFF00B894);
  static const danger = Color(0xFFE84C3D);
  static const warning = Color(0xFFFFA502);
  static const background = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  static const border = Color(0xFFDFE6E9);
}

class TroclyTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: TroclyColors.primary,
        secondary: TroclyColors.secondary,
        surface: TroclyColors.surface,
        error: TroclyColors.danger,
        background: TroclyColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TroclyColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: TroclyColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: TroclyColors.textPrimary,
        ),
      ),
    );
  }
}
