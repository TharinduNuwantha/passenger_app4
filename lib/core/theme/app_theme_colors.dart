import 'package:flutter/material.dart';

/// Semantic color tokens for the entire app.
/// Access via: `Theme.of(context).extension<AppThemeColors>()!`
/// Or shortcut: `context.colors.cardBackground`
///
/// Brand colors (AppColors.primary, success, error, warning) stay fixed
/// across themes. Only surfaces, text, borders, shadows adapt.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    // ── Surfaces ──
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.bottomNavBackground,
    required this.dialogBackground,
    required this.bottomSheetBackground,
    required this.bottomSheetBarrier,

    // ── Text ──
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,

    // ── Input Fields ──
    required this.inputBackground,
    required this.inputBorder,
    required this.inputText,
    required this.inputHint,

    // ── Icons ──
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconInactive,

    // ── Shadows & Overlays ──
    required this.shadowColor,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.dividerColor,

    // ── Chips & Badges ──
    required this.chipBackground,
    required this.chipBorder,

    // ── Status bar ──
    required this.statusBarColor,
    required this.statusBarIconBrightness,
    required this.statusBarBrightness,
  });

  // ── Surfaces ──
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color bottomNavBackground;
  final Color dialogBackground;
  final Color bottomSheetBackground;
  final Color bottomSheetBarrier;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary; // text on blue/brand surfaces

  // ── Input Fields ──
  final Color inputBackground;
  final Color inputBorder;
  final Color inputText;
  final Color inputHint;

  // ── Icons ──
  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconInactive;

  // ── Shadows & Overlays ──
  final Color shadowColor;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color dividerColor;

  // ── Chips & Badges ──
  final Color chipBackground;
  final Color chipBorder;

  // ── Status bar ──
  final Color statusBarColor;
  final Brightness statusBarIconBrightness;
  final Brightness statusBarBrightness;

  @override
  AppThemeColors copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? bottomNavBackground,
    Color? dialogBackground,
    Color? bottomSheetBackground,
    Color? bottomSheetBarrier,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnPrimary,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputText,
    Color? inputHint,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? iconInactive,
    Color? shadowColor,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? dividerColor,
    Color? chipBackground,
    Color? chipBorder,
    Color? statusBarColor,
    Brightness? statusBarIconBrightness,
    Brightness? statusBarBrightness,
  }) {
    return AppThemeColors(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      bottomNavBackground: bottomNavBackground ?? this.bottomNavBackground,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      bottomSheetBackground: bottomSheetBackground ?? this.bottomSheetBackground,
      bottomSheetBarrier: bottomSheetBarrier ?? this.bottomSheetBarrier,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputText: inputText ?? this.inputText,
      inputHint: inputHint ?? this.inputHint,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconInactive: iconInactive ?? this.iconInactive,
      shadowColor: shadowColor ?? this.shadowColor,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      dividerColor: dividerColor ?? this.dividerColor,
      chipBackground: chipBackground ?? this.chipBackground,
      chipBorder: chipBorder ?? this.chipBorder,
      statusBarColor: statusBarColor ?? this.statusBarColor,
      statusBarIconBrightness: statusBarIconBrightness ?? this.statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness ?? this.statusBarBrightness,
    );
  }

  @override
  AppThemeColors lerp(covariant ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      bottomNavBackground: Color.lerp(bottomNavBackground, other.bottomNavBackground, t)!,
      dialogBackground: Color.lerp(dialogBackground, other.dialogBackground, t)!,
      bottomSheetBackground: Color.lerp(bottomSheetBackground, other.bottomSheetBackground, t)!,
      bottomSheetBarrier: Color.lerp(bottomSheetBarrier, other.bottomSheetBarrier, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputText: Color.lerp(inputText, other.inputText, t)!,
      inputHint: Color.lerp(inputHint, other.inputHint, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      iconInactive: Color.lerp(iconInactive, other.iconInactive, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t)!,
      statusBarColor: Color.lerp(statusBarColor, other.statusBarColor, t)!,
      statusBarIconBrightness: t < 0.5 ? statusBarIconBrightness : other.statusBarIconBrightness,
      statusBarBrightness: t < 0.5 ? statusBarBrightness : other.statusBarBrightness,
    );
  }
}
