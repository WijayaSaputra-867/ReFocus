import 'package:flutter/material.dart';

/// App-wide colour tokens.
/// Dark theme, calm register — per PRODUCT.md brand commitments and shape brief.
abstract final class AppColors {
  // Backgrounds
  static const background = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);

  // Text
  static const textPrimary = Color(0xFFEEF0F6);
  static const textSecondary = Color(0xFF7A7F94);

  // State accents — calm, not alarming (PRD §10 UX Principles)
  static const accentIdle = Color(0xFF6EE7B7); // soft teal-green
  static const accentDistracting = Color(0xFFFBBF24); // amber
  static const accentCooldown = Color(0xFF818CF8); // indigo
  static const accentLocked = Color(0xFFF87171); // muted red
}

ThemeData buildTheme() {
  return ThemeData.dark(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accentIdle,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
