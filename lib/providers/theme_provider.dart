import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Logger _logger = Logger();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // Load theme mode from storage
  Future<void> loadThemeMode() async {
    try {
      _logger.i('Loading theme mode from storage');

      final savedMode = await _storage.getThemeMode();

      if (savedMode != null) {
        _themeMode = _themeModeFromString(savedMode);
        _logger.i('Theme mode loaded: $_themeMode');
      } else {
        _themeMode = ThemeMode.system;
        _logger.i('No saved theme mode, using system default');
      }

      notifyListeners();
    } catch (e) {
      _logger.e('Error loading theme mode: $e');
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _logger.i('Setting theme mode to: $mode');

      _themeMode = mode;
      notifyListeners();

      // Save to storage
      await _storage.saveThemeMode(_themeModeToString(mode));

      _logger.i('Theme mode saved');
    } catch (e) {
      _logger.e('Error setting theme mode: $e');
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  // Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  // Set system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  // Convert ThemeMode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // Convert string to ThemeMode
  ThemeMode _themeModeFromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
