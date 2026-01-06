import 'package:flutter/material.dart';

/// Centralized SmartTransit color definitions shared across the Driver app UI.
/// Combines the requested blue/orange brand palette with legacy aliases so
/// existing widgets continue to compile while picking up the refreshed theme.
class AppColors {
  // ===========================================================================
  // Primary Brand Colors
  // ===========================================================================
  static const Color primary = Color(0xFF1976D2); // SmartTransit blue
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primarySurface = Color(0xFFE3F2FD);
  static const Color primaryLighter = primaryLight; // legacy alias

  // ===========================================================================
  // Secondary / Accent Colors
  // ===========================================================================
  static const Color secondary = Color(0xFF1E88E5); // Blue accent
  static const Color secondaryLight = Color(0xFF6AB7FF);
  static const Color secondaryDark = Color(0xFF1565C0);
  static const Color accent = secondary;

  // ===========================================================================
  // Gradients & Decorative Palettes
  // ===========================================================================
  static const Color gradientStart = primaryDark;
  static const Color gradientMid = primary;
  static const Color gradientEnd = primaryLight;
  static const Color accentGradientStart = secondaryDark;
  static const Color accentGradientEnd = secondary;

  // ===========================================================================
  // Status & Feedback Colors
  // ===========================================================================
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successSurface = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color warningSurface = Color(0xFFFFF3E0);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorSurface = Color(0xFFFFEBEE);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  static const Color pickupGreen = success;
  static const Color dropRed = error;
  static const Color notificationBadge = warning;

  // ===========================================================================
  // Backgrounds & Surfaces
  // ===========================================================================
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF212121);
  static const Color surfaceWhite = surface; // backward compat
  static const Color field = Color(0xFFE0E0E0);

  // ===========================================================================
  // Text Colors
  // ===========================================================================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color iconLight = textLight;
  static const Color text = textLight; // legacy alias

  // ===========================================================================
  // Border & Divider Colors
  // ===========================================================================
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = divider;

  // ===========================================================================
  // Whites & Transparency Helpers (legacy aliases)
  // ===========================================================================
  static const Color white = textLight;
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white80 = Color(0xCCFFFFFF);
  static const Color black54 = Color(0x8A000000);

  // ===========================================================================
  // Shadows
  // ===========================================================================
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowMedium = Colors.black.withOpacity(0.16);
}
