import 'dart:async';
import 'package:logger/logger.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class TokenRefreshService {
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  factory TokenRefreshService() => _instance;
  TokenRefreshService._internal();

  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  final Logger _logger = Logger();

  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // Start automatic token refresh
  void startAutoRefresh() {
    _logger.i('Starting automatic token refresh');

    // Cancel existing timer if any
    _refreshTimer?.cancel();

    // Check token status every minute
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndRefreshToken(),
    );
  }

  // Stop automatic token refresh
  void stopAutoRefresh() {
    _logger.i('Stopping automatic token refresh');
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Check if token needs refresh and refresh if needed
  Future<void> _checkAndRefreshToken() async {
    if (_isRefreshing) {
      _logger.d('Token refresh already in progress');
      return;
    }

    try {
      _isRefreshing = true;

      // Check if token needs refresh
      final needsRefresh = await _storage.needsTokenRefresh();

      if (needsRefresh) {
        _logger.i('Token needs refresh, refreshing...');
        final success = await _authService.refreshToken();

        if (success) {
          _logger.i('Token refreshed successfully');
        } else {
          _logger.w('Token refresh failed');
        }
      } else {
        _logger.d('Token is still valid, no refresh needed');
      }
    } catch (e) {
      _logger.e('Error during token refresh check: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  // Manually trigger token refresh
  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      _logger.d('Token refresh already in progress');
      return false;
    }

    try {
      _isRefreshing = true;
      _logger.i('Manually refreshing token');

      final success = await _authService.refreshToken();

      if (success) {
        _logger.i('Token refreshed successfully');
        return true;
      } else {
        _logger.w('Token refresh failed');
        return false;
      }
    } catch (e) {
      _logger.e('Error during manual token refresh: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Check if token needs refresh
  Future<bool> needsRefresh() async {
    try {
      return await _storage.needsTokenRefresh();
    } catch (e) {
      _logger.e('Error checking token refresh need: $e');
      return false;
    }
  }

  // Get minutes until token expiry
  Future<int?> getMinutesUntilExpiry() async {
    try {
      final expiryTime = await _storage.getTokenExpiry();
      if (expiryTime == null) return null;

      final duration = expiryTime.difference(DateTime.now());
      return duration.inMinutes;
    } catch (e) {
      _logger.e('Error getting minutes until expiry: $e');
      return null;
    }
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiryTime = await _storage.getTokenExpiry();
      if (expiryTime == null) return true;

      return DateTime.now().isAfter(expiryTime);
    } catch (e) {
      _logger.e('Error checking token expiry: $e');
      return true;
    }
  }
}
