import 'package:flutter/material.dart';

/// Liora Mobile App Color Theme
/// Luxury, Minimalist, Trustworthy, Elegant Design System
class AppColors {
  // ============================================================================
  // Brand Colors
  // ============================================================================
  static const Color lioraGold = Color(0xFFD4AF37); // Primary Brand Color
  static const Color royalNavy = Color(0xFF111C2E); // Secondary Brand Color

  // ============================================================================
  // Dark Theme Colors
  // ============================================================================
  static const Color midnightBlack = Color(
    0xFF0B0B0D,
  ); // Main Background (Dark Mode)
  static const Color onyxSurface = Color(
    0xFF1E1E21,
  ); // Card/Container Background (Dark Mode)
  static const Color pureWhite = Color(0xFFFFFFFF); // Primary Text (Dark Mode)
  static const Color mistGray = Color(0xFFA0A0A0); // Secondary Text (Dark Mode)

  // ============================================================================
  // Light Theme Colors
  // ============================================================================
  static const Color crispWhite = Color(
    0xFFFFFFFF,
  ); // Main Background (Light Mode)
  static const Color softCloud = Color(0xFFF8F9FA); // Secondary Backgrounds
  static const Color deepCharcoal = Color(0xFF1A1A1A); // Body Text (Light Mode)
  static const Color bodyText = Color(
    0xFF4A4A4A,
  ); // Paragraph Text (Light Mode)

  // ============================================================================
  // Legacy Aliases (for compatibility)
  // ============================================================================
  static const Color primary = lioraGold;
  static const Color secondary = royalNavy;
  static const Color accent = lioraGold;

  // Gradient colors
  static const Color gradientStart = lioraGold;
  static const Color gradientEnd = Color(0xFFC5A028); // Subtle Gold Shift

  // ============================================================================
  // Status & Feedback Colors
  // ============================================================================
  static const Color success = Color(0xFFB8D8C2);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFF4B9A8);
  static const Color info = lioraGold;

  // ============================================================================
  // Background Colors
  // ============================================================================
  static const Color background = crispWhite;
  static const Color surface = crispWhite;
  static const Color surfaceDark = onyxSurface;

  // ============================================================================
  // Text Colors
  // ============================================================================
  static const Color textPrimary = royalNavy;
  static const Color textSecondary = deepCharcoal;
  static const Color textLight = pureWhite;
  static const Color textBodyLight = bodyText;

  // ============================================================================
  // Border & Divider Colors
  // ============================================================================
  static const Color border = lioraGold;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF333333);

  static Color? white = pureWhite;
  static Color? white70;
}

class AppSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
}

/// Liora Premium Gradients
class AppGradients {
  // Gold gradient for luxury feel
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.lioraGold, Color(0xFFC5A028)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark gradient for depth
  static const LinearGradient darkGradient = LinearGradient(
    colors: [AppColors.midnightBlack, AppColors.royalNavy],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Subtle background gradient for light mode
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [AppColors.crispWhite, AppColors.softCloud],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lioraGold,
      brightness: Brightness.light,
      primary: AppColors.lioraGold,
      secondary: AppColors.royalNavy,
      surface: AppColors.crispWhite,
      background: AppColors.crispWhite,
    ),
    scaffoldBackgroundColor: AppColors.crispWhite,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.crispWhite,
      foregroundColor: AppColors.royalNavy,
      iconTheme: IconThemeData(color: AppColors.lioraGold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lioraGold,
        foregroundColor: AppColors.royalNavy,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lioraGold,
        backgroundColor: AppColors.royalNavy,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.lioraGold, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.softCloud,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lioraGold),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lioraGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.medium,
      ),
      labelStyle: const TextStyle(color: AppColors.bodyText),
      hintStyle: const TextStyle(color: Color(0xFF999999)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.lioraGold, width: 1),
      ),
      color: AppColors.crispWhite,
      shadowColor: AppColors.royalNavy.withOpacity(0.1),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.royalNavy,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.royalNavy,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: AppColors.royalNavy,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AppColors.bodyText),
      bodyMedium: TextStyle(color: AppColors.bodyText),
      bodySmall: TextStyle(color: AppColors.deepCharcoal),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.crispWhite,
      selectedItemColor: AppColors.lioraGold,
      unselectedItemColor: Color(0xFF8FA3BF),
      elevation: 8,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lioraGold,
      brightness: Brightness.dark,
      primary: AppColors.lioraGold,
      secondary: AppColors.royalNavy,
      surface: AppColors.onyxSurface,
      background: AppColors.midnightBlack,
    ),
    scaffoldBackgroundColor: AppColors.midnightBlack,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.midnightBlack,
      foregroundColor: AppColors.pureWhite,
      iconTheme: IconThemeData(color: AppColors.lioraGold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lioraGold,
        foregroundColor: AppColors.royalNavy,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lioraGold,
        backgroundColor: AppColors.royalNavy,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.lioraGold, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.onyxSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lioraGold),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lioraGold, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.medium,
      ),
      labelStyle: const TextStyle(color: AppColors.mistGray),
      hintStyle: const TextStyle(color: Color(0xFF666666)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.lioraGold, width: 1),
      ),
      color: AppColors.onyxSurface,
      shadowColor: Colors.black.withOpacity(0.4),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.pureWhite,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.pureWhite,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: AppColors.pureWhite,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AppColors.mistGray),
      bodyMedium: TextStyle(color: AppColors.mistGray),
      bodySmall: TextStyle(color: AppColors.mistGray),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: AppColors.lioraGold,
      unselectedItemColor: Color(0xFF555555),
      elevation: 8,
    ),
  );
}
