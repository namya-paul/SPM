import 'package:flutter/material.dart';

/// Color palette for the dashboard.
///
/// Design intent: a dark "ops console" look, appropriate for a system
/// monitoring tool. Status colors (healthy / warning / critical) are
/// used consistently across usage bars, status dots, and charts so
/// the same color always means the same thing.
class AppColors {
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D29);
  static const Color surfaceLight = Color(0xFF2A2E3F);

  // Primary accent, used for highlights and the network metric.
  static const Color accent = Color(0xFF00D9FF);

  // Status colors, used for usage bars and online/offline indicators.
  static const Color healthy = Color(0xFF4ADE80);  // < 60%
  static const Color warning = Color(0xFFFBBF24);  // 60-85%
  static const Color critical = Color(0xFFF87171); // > 85% or offline

  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
    );
  }
}
