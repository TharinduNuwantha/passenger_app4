import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final Logger _logger = Logger();

  // Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: AppConstants.accessTokenKey, value: token);
      _logger.d('Access token saved');
    } catch (e) {
      _logger.e('Error saving access token: $e');
      rethrow;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      _logger.e('Error reading access token: $e');
      return null;
    }
  }

  // Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
      _logger.d('Refresh token saved');
    } catch (e) {
      _logger.e('Error saving refresh token: $e');
      rethrow;
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      _logger.e('Error reading refresh token: $e');
      return null;
    }
  }

  // Save token expiry time
  Future<void> saveTokenExpiry(DateTime expiryTime) async {
    try {
      await _storage.write(
        key: AppConstants.tokenExpiryKey,
        value: expiryTime.toIso8601String(),
      );
      _logger.d('Token expiry saved: $expiryTime');
    } catch (e) {
      _logger.e('Error saving token expiry: $e');
      rethrow;
    }
  }

  // Get token expiry time
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(
        key: AppConstants.tokenExpiryKey,
      );
      if (expiryString != null) {
        return DateTime.parse(expiryString);
      }
      return null;
    } catch (e) {
      _logger.e('Error reading token expiry: $e');
      return null;
    }
  }

  // Save all tokens at once
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    try {
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

      await Future.wait([
        saveAccessToken(accessToken),
        saveRefreshToken(refreshToken),
        saveTokenExpiry(expiryTime),
      ]);

      _logger.i('All tokens saved successfully');
    } catch (e) {
      _logger.e('Error saving tokens: $e');
      rethrow;
    }
  }

  // Check if valid tokens exist
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final expiryTime = await getTokenExpiry();

      if (accessToken == null || refreshToken == null || expiryTime == null) {
        _logger.d('Missing tokens');
        return false;
      }

      // Check if token is expired
      if (DateTime.now().isAfter(expiryTime)) {
        _logger.d('Token expired');
        return false;
      }

      _logger.d('Valid tokens found');
      return true;
    } catch (e) {
      _logger.e('Error checking token validity: $e');
      return false;
    }
  }

  // Check if token needs refresh (within 5 minutes of expiry)
  Future<bool> needsTokenRefresh() async {
    try {
      final expiryTime = await getTokenExpiry();
      if (expiryTime == null) return false;

      final threshold = Duration(minutes: AppConstants.tokenRefreshThreshold);
      final refreshTime = expiryTime.subtract(threshold);

      return DateTime.now().isAfter(refreshTime);
    } catch (e) {
      _logger.e('Error checking token refresh need: $e');
      return false;
    }
  }

  // Save user data
  Future<void> saveUserData(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: AppConstants.userDataKey, value: userJson);
      _logger.d('User data saved');
    } catch (e) {
      _logger.e('Error saving user data: $e');
      rethrow;
    }
  }

  // Get user data
  Future<UserModel?> getUserData() async {
    try {
      final userJson = await _storage.read(key: AppConstants.userDataKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      _logger.e('Error reading user data: $e');
      return null;
    }
  }

  // Clear all tokens
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: AppConstants.accessTokenKey),
        _storage.delete(key: AppConstants.refreshTokenKey),
        _storage.delete(key: AppConstants.tokenExpiryKey),
      ]);
      _logger.i('Tokens cleared');
    } catch (e) {
      _logger.e('Error clearing tokens: $e');
      rethrow;
    }
  }

  // Clear user data
  Future<void> clearUserData() async {
    try {
      await _storage.delete(key: AppConstants.userDataKey);
      _logger.i('User data cleared');
    } catch (e) {
      _logger.e('Error clearing user data: $e');
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      _logger.i('All storage cleared');
    } catch (e) {
      _logger.e('Error clearing all storage: $e');
      rethrow;
    }
  }

  // Save theme mode
  Future<void> saveThemeMode(String themeMode) async {
    try {
      await _storage.write(key: AppConstants.themeKey, value: themeMode);
    } catch (e) {
      _logger.e('Error saving theme mode: $e');
    }
  }

  // Get theme mode
  Future<String?> getThemeMode() async {
    try {
      return await _storage.read(key: AppConstants.themeKey);
    } catch (e) {
      _logger.e('Error reading theme mode: $e');
      return null;
    }
  }
}
