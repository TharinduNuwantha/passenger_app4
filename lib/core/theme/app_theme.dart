/// App theme entry point.
/// Import this single file to access light/dark themes and the context extension.
///
/// Usage in any widget:
/// ```dart
/// import '../../core/theme/app_theme.dart';
///
/// // Access semantic colors:
/// final bg = context.colors.cardBackground;
///
/// // Check dark mode:
/// if (context.isDarkMode) { ... }
/// ```
library;

export 'app_theme_colors.dart';
export 'light_theme.dart' show lightTheme;
export 'dark_theme.dart' show darkTheme;

import 'package:flutter/material.dart';
import 'app_theme_colors.dart';

/// Convenience extension on BuildContext for quick theme access.
extension ThemeContextExtension on BuildContext {
  /// Access the semantic color tokens for the current theme.
  AppThemeColors get colors => Theme.of(this).extension<AppThemeColors>()!;

  /// Whether the current theme is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// The current ThemeData.
  ThemeData get theme => Theme.of(this);
}
