import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'app_theme_colors.dart';

/// Light theme color tokens
const lightColors = AppThemeColors(
  // ── Surfaces ──
  scaffoldBackground: Color(0xFFF5F5F5),
  cardBackground: Color(0xFFFFFFFF),
  cardBorder: Color(0xFFEEEEEE),
  bottomNavBackground: Color(0xFFFFFFFF),
  dialogBackground: Color(0xFFFFFFFF),
  bottomSheetBackground: Color(0xFFFFFFFF),
  bottomSheetBarrier: Color(0x80000000),

  // ── Text ──
  textPrimary: Color(0xFF212121),
  textSecondary: Color(0xFF757575),
  textTertiary: Color(0xFF9E9E9E),
  textOnPrimary: Color(0xFFFFFFFF),

  // ── Input Fields ──
  inputBackground: Color(0xFFF7F8FA),
  inputBorder: Color(0xFFE0E0E0),
  inputText: Color(0xFF212121),
  inputHint: Color(0xFFBDBDBD),

  // ── Icons ──
  iconPrimary: Color(0xFF424242),
  iconSecondary: Color(0xFF757575),
  iconInactive: Color(0xFF9E9E9E),

  // ── Shadows & Overlays ──
  shadowColor: Color(0x14000000), // black 8%
  shimmerBase: Color(0xFFE0E0E0),
  shimmerHighlight: Color(0xFFF5F5F5),
  dividerColor: Color(0xFFE0E0E0),

  // ── Chips & Badges ──
  chipBackground: Color(0xFFF5F5F5),
  chipBorder: Color(0xFFE0E0E0),

  // ── Status bar ──
  statusBarColor: AppColors.primary,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

/// Full Light ThemeData
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: lightColors.scaffoldBackground,

  // ── AppBar ──
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: AppColors.primary,
    foregroundColor: lightColors.textOnPrimary,
    iconTheme: IconThemeData(color: lightColors.textOnPrimary),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: lightColors.statusBarColor,
      statusBarIconBrightness: lightColors.statusBarIconBrightness,
      statusBarBrightness: lightColors.statusBarBrightness,
    ),
  ),

  // ── Cards ──
  cardTheme: CardThemeData(
    elevation: 2,
    color: lightColors.cardBackground,
    surfaceTintColor: lightColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),

  // ── Elevated Buttons ──
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: lightColors.textOnPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
  ),

  // ── Outlined Buttons ──
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),

  // ── Text Buttons ──
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
    ),
  ),

  // ── Input Decoration ──
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightColors.inputBackground,
    hintStyle: TextStyle(color: lightColors.inputHint),
    labelStyle: TextStyle(color: lightColors.textSecondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightColors.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: lightColors.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // ── Dialogs ──
  dialogTheme: DialogThemeData(
    backgroundColor: lightColors.dialogBackground,
    surfaceTintColor: lightColors.dialogBackground,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),

  // ── Bottom Sheets ──
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: lightColors.bottomSheetBackground,
    surfaceTintColor: lightColors.bottomSheetBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),

  // ── Divider ──
  dividerTheme: DividerThemeData(
    color: lightColors.dividerColor,
    thickness: 1,
  ),

  // ── Icons ──
  iconTheme: IconThemeData(color: lightColors.iconPrimary),

  // ── Progress Indicators ──
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
  ),

  // ── Snackbar ──
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF323232),
    contentTextStyle: TextStyle(color: lightColors.textOnPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),

  // ── Extensions ──
  extensions: const [lightColors],
);
