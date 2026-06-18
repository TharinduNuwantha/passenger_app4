import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../services/storage_service.dart';

class LanguageProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Logger _logger = Logger();

  Locale _locale = const Locale('si');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> loadLocale() async {
    try {
      final savedLanguageCode = await _storageService.getLanguageCode();
      if (savedLanguageCode == null || !_isSupported(savedLanguageCode)) {
        _locale = const Locale('si');
        await _storageService.saveLanguageCode(_locale.languageCode);
      } else {
        _locale = Locale(savedLanguageCode);
      }
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading locale: $e');
      _locale = const Locale('si');
      notifyListeners();
    }
  }

  Future<void> setLocaleByCode(String languageCode) async {
    if (!_isSupported(languageCode) || languageCode == _locale.languageCode) {
      return;
    }

    _locale = Locale(languageCode);
    notifyListeners();

    try {
      await _storageService.saveLanguageCode(languageCode);
    } catch (e) {
      _logger.e('Error saving locale: $e');
    }
  }

  bool _isSupported(String languageCode) {
    return languageCode == 'en' || languageCode == 'si' || languageCode == 'ta';
  }
}
