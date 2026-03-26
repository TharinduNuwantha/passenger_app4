import 'package:flutter/material.dart';

/// SmartTransit Driver/Conductor App Color Theme
/// Matches Bus Owner App branding for consistent ecosystem look
class AppColors {
  // ============================================================================
  // Primary Brand Colors (Matching Bus Owner App)
  // ============================================================================
  static const Color primary = Color(0xFF1976D2); // Main blue
  static const Color primaryLight = Color(0xFF42A5F5); // Lighter blue
  static const Color primaryDark = Color(0xFF1565C0); // Darker blue
  static const Color primarySurface = Color(
    0xFFE3F2FD,
  ); // Very light blue (backgrounds)

  // ============================================================================
  // Secondary / Accent Colors
  // ============================================================================
  static const Color secondary = Color(0xFFFF9800); // Orange
  static const Color secondaryLight = Color(0xFFFFB74D); // Light orange
  static const Color secondaryDark = Color(0xFFF57C00); // Dark orange
  static const Color accent = Color(0xFFFF9800); // Orange accent

  // Gradient colors for professional branding
  static const Color gradientStart = Color(0xFF1976D2); // Blue
  static const Color gradientEnd = Color(0xFF42A5F5); // Light blue

  // ============================================================================
  // Status & Feedback Colors
  // ============================================================================
  static const Color success = Color(0xFF4CAF50); // Green - success, active
  static const Color successLight = Color(0xFF81C784); // Light green
  static const Color successDark = Color(0xFF388E3C); // Dark green
  static const Color successSurface = Color(0xFFE8F5E9); // Very light green

  static const Color warning = Color(0xFFFF9800); // Orange - warnings, pending
  static const Color warningLight = Color(0xFFFFB74D); // Light orange
  static const Color warningDark = Color(0xFFF57C00); // Dark orange
  static const Color warningSurface = Color(0xFFFFF3E0); // Very light orange

  static const Color error = Color(0xFFF44336); // Red - errors, critical
  static const Color errorLight = Color(0xFFE57373); // Light red
  static const Color errorDark = Color(0xFFD32F2F); // Dark red
  static const Color errorSurface = Color(0xFFFFEBEE); // Very light red

  static const Color info = Color(0xFF2196F3); // Blue - information

  // ============================================================================
  // Background Colors
  // ============================================================================
  static const Color background = Color(0xFFF5F5F5); // Main app background
  static const Color surface = Color(0xFFFFFFFF); // Cards, dialogs
  static const Color surfaceVariant = Color(0xFFFAFAFA); // Alternate surface
  static const Color surfaceDark = Color(0xFF212121); // Dark mode surface

  // ============================================================================
  // Text Colors
  // ============================================================================
  static const Color textPrimary = Color(0xFF212121); // Main text
  static const Color textSecondary = Color(0xFF757575); // Subtitle, captions
  static const Color textHint = Color(0xFF9E9E9E); // Hints, placeholders
  static const Color textDisabled = Color(0xFFBDBDBD); // Disabled text
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Text on primary color
  static const Color textLight = Color(
    0xFFFFFFFF,
  ); // White text on dark backgrounds

  // ============================================================================
  // Border & Divider Colors
  // ============================================================================
  static const Color border = Color(0xFFE0E0E0); // Borders
  static const Color divider = Color(0xFFE0E0E0); // Dividers

  // ============================================================================
  // Status Colors (for trips, staff, etc.)
  // ============================================================================
  static const Color statusActive = Color(0xFF4CAF50); // Active, running
  static const Color statusInactive = Color(0xFF9E9E9E); // Inactive, idle
  static const Color statusPending = Color(0xFFFF9800); // Pending, waiting
  static const Color statusCompleted = Color(0xFF2196F3); // Completed
  static const Color statusCancelled = Color(0xFFF44336); // Cancelled
}

class AppSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
  static const double xxLarge = 48.0;
}

/// SmartTransit Premium Gradients for Driver/Conductor App
class AppGradients {
  // Professional blue gradient for branding (matching bus_owner_app)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Subtle background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [AppColors.background, Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Orange accent gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [AppColors.secondaryDark, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gold accent gradient for premium badges
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4B27A), Color(0xFFE5C98D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
