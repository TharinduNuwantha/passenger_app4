import 'package:flutter/material.dart';

/// Lior Mobile App Color Theme
/// Premium, calming palette for SmartTransit Passenger App
class AppColors {
  // ============================================================================
  // Primary Colors - Actions & Core Elements
  // ============================================================================
  static const Color primary = Color(0xFF3A88C8); // Deep Sky Blue - Main buttons, headers
  static const Color secondary = Color(0xFF88C9A1); // Soft Teal - Secondary actions, highlights

  // ============================================================================
  // Accent / Premium Colors
  // ============================================================================
  static const Color accent = Color(0xFFD4B27A); // Champagne Gold - Icons, badges, premium feel

  // Gradient colors for splash screens and CTAs
  static const Color gradientStart = Color(0xFF3A88C8); // Deep Sky Blue
  static const Color gradientEnd = Color(0xFF88C9A1); // Soft Teal

  // ============================================================================
  // Status & Feedback Colors
  // ============================================================================
  static const Color success = Color(0xFFB8D8C2); // Calm Sage - Success messages, confirmations
  static const Color error = Color(0xFFF44336); // Red - Errors
  static const Color warning = Color(0xFFF4B9A8); // Soft Coral - Warnings, gentle alerts
  static const Color info = Color(0xFF3A88C8); // Deep Sky Blue - Info messages

  // ============================================================================
  // Background Colors
  // ============================================================================
  static const Color background = Color(0xFFF5F7FA); // Off-White - Main background
  static const Color surface = Colors.white; // Cards, containers
  static const Color surfaceDark = Color(0xFF1F2B3A); // Dark Charcoal - Dark mode

  // ============================================================================
  // Text Colors
  // ============================================================================
  static const Color textPrimary = Color(0xFF1F2B3A); // Dark Charcoal - Main text
  static const Color textSecondary = Color(0xFF757575); // Gray - Secondary text
  static const Color textLight = Colors.white; // White text on dark backgrounds

  // ============================================================================
  // Border & Divider Colors
  // ============================================================================
  static const Color border = Color(0xFFDADBDC); // Soft Gray - Borders
  static const Color divider = Color(0xFFDADBDC); // Soft Gray - Dividers
}

class AppSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
}

/// Lior Premium Gradients
class AppGradients {
  // Blue to Teal gradient for logo, splash, CTAs
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [AppColors.background, Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      iconTheme: IconThemeData(color: AppColors.textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.medium,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      color: AppColors.surface,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.surfaceDark,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textLight,
      iconTheme: IconThemeData(color: AppColors.textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.medium,
      ),
    ),
  );
}
