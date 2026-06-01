import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'app_theme_colors.dart';

/// Dark theme color tokens
const darkColors = AppThemeColors(
  // ── Surfaces ──
  scaffoldBackground: Color(0xFF0F0F23),
  cardBackground: Color(0xFF16213E),
  cardBorder: Color(0xFF2A2A4A),
  bottomNavBackground: Color(0xFF16213E),
  dialogBackground: Color(0xFF1E1E3A),
  bottomSheetBackground: Color(0xFF1A1A30),
  bottomSheetBarrier: Color(0xB3000000),

  // ── Text ──
  textPrimary: Color(0xFFF5F5F5),
  textSecondary: Color(0xFFB0B0B0),
  textTertiary: Color(0xFF6B6B6B),
  textOnPrimary: Color(0xFFFFFFFF),

  // ── Input Fields ──
  inputBackground: Color(0xFF1A1A2E),
  inputBorder: Color(0xFF2A2A4A),
  inputText: Color(0xFFF5F5F5),
  inputHint: Color(0xFF6B6B6B),

  // ── Icons ──
  iconPrimary: Color(0xFFE0E0E0),
  iconSecondary: Color(0xFFB0B0B0),
  iconInactive: Color(0xFF6B6B8A),

  // ── Shadows & Overlays ──
  shadowColor: Color(0x4D000000), // black 30%
  shimmerBase: Color(0xFF2A2A4A),
  shimmerHighlight: Color(0xFF3A3A5A),
  dividerColor: Color(0xFF2A2A4A),

  // ── Chips & Badges ──
  chipBackground: Color(0xFF1A1A30),
  chipBorder: Color(0xFF2A2A4A),

  // ── Status bar ──
  statusBarColor: Color(0xFF0F0F23),
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.light,
);

/// Full Dark ThemeData
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: darkColors.scaffoldBackground,

  // ── AppBar ──
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: darkColors.scaffoldBackground,
    foregroundColor: darkColors.textOnPrimary,
    iconTheme: IconThemeData(color: darkColors.textOnPrimary),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: darkColors.statusBarColor,
      statusBarIconBrightness: darkColors.statusBarIconBrightness,
      statusBarBrightness: darkColors.statusBarBrightness,
    ),
  ),

  // ── Cards ──
  cardTheme: CardThemeData(
    elevation: 2,
    color: darkColors.cardBackground,
    surfaceTintColor: darkColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),

  // ── Elevated Buttons ──
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: darkColors.textOnPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),
  ),

  // ── Outlined Buttons ──
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
  ),

  // ── Text Buttons ──
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
    ),
  ),

  // ── Input Decoration ──
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkColors.inputBackground,
    hintStyle: TextStyle(color: darkColors.inputHint),
    labelStyle: TextStyle(color: darkColors.textSecondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: darkColors.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: darkColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // ── Dialogs ──
  dialogTheme: DialogThemeData(
    backgroundColor: darkColors.dialogBackground,
    surfaceTintColor: darkColors.dialogBackground,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),

  // ── Bottom Sheets ──
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: darkColors.bottomSheetBackground,
    surfaceTintColor: darkColors.bottomSheetBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),

  // ── Divider ──
  dividerTheme: DividerThemeData(
    color: darkColors.dividerColor,
    thickness: 1,
  ),

  // ── Icons ──
  iconTheme: IconThemeData(color: darkColors.iconPrimary),

  // ── Progress Indicators ──
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primaryLight,
  ),

  // ── Snackbar ──
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2A2A4A),
    contentTextStyle: TextStyle(color: darkColors.textOnPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),

  // ── Extensions ──
  extensions: const [darkColors],
);
