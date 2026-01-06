import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/token_refresh_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();
  final Logger _logger = Logger();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  UserModel? _user;
  String? _phoneNumber;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get user => _user;
  String? get phoneNumber => _phoneNumber;

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _logger.i('Checking authentication status');

      // Check if valid tokens exist
      final authenticated = await _authService.isAuthenticated();

      if (authenticated) {
        // Get current user
        _user = await _authService.getCurrentUser();
        _isAuthenticated = true;

        // Start auto token refresh
        _tokenRefreshService.startAutoRefresh();

        _logger.i('User is authenticated');
      } else {
        _isAuthenticated = false;
        _user = null;
        _logger.i('User is not authenticated');
      }
    } catch (e) {
      _logger.e('Error checking auth status: $e');
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send OTP
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      _phoneNumber = phoneNumber;
      notifyListeners();

      _logger.i('Sending OTP to: $phoneNumber');

      final result = await _authService.sendOtp(phoneNumber);

      if (result['success'] == true) {
        _logger.i('OTP sent successfully');
        return true;
      }

      _error = 'Failed to send OTP';
      return false;
    } catch (e) {
      _logger.e('Send OTP error: $e');
      // The error is already a formatted string from ErrorHandler
      _error = e is String ? e : e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _logger.i('Verifying OTP');

      final result = await _authService.verifyOtp(phoneNumber, otp);

      _logger.i('DEBUG - Verify OTP result: $result');
      _logger.i('DEBUG - Result success: ${result['success']}');
      _logger.i('DEBUG - Result keys: ${result.keys}');

      if (result['success'] == true) {
        _logger.i('DEBUG - User data: ${result['user']}');
        _user = result['user'] as UserModel;
        _isAuthenticated = true;
        _phoneNumber = null;

        // Start auto token refresh
        _tokenRefreshService.startAutoRefresh();

        _logger.i('OTP verified successfully - User: ${_user?.name}');
        return true;
      }

      _error = 'Invalid OTP';
      _logger.w('OTP verification failed - success is not true');
      return false;
    } catch (e) {
      _logger.e('Verify OTP error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      _logger.i('Refreshing token');

      final success = await _authService.refreshToken();

      if (success) {
        _logger.i('Token refreshed successfully');
        return true;
      }

      _error = 'Failed to refresh token';
      return false;
    } catch (e) {
      _logger.e('Refresh token error: $e');
      _error = e.toString();
      return false;
    }
  }

  // Logout
  Future<bool> logout({bool logoutAll = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _logger.i('Logging out (logoutAll: $logoutAll)');

      final success = await _authService.logout(logoutAll: logoutAll);

      if (success) {
        _isAuthenticated = false;
        _user = null;
        _phoneNumber = null;

        // Stop auto token refresh
        _tokenRefreshService.stopAutoRefresh();

        _logger.i('Logout successful');
        return true;
      }

      _error = 'Logout failed';
      return false;
    } catch (e) {
      _logger.e('Logout error: $e');
      _error = e.toString();

      // Clear local state anyway
      _isAuthenticated = false;
      _user = null;
      _phoneNumber = null;

      return true; // Return true since local logout succeeded
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update user
  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Complete basic profile (first_name + last_name only) - for new passengers
  Future<bool> completeBasicProfile(String firstName, String lastName) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _logger.i('Completing basic profile');

      final result = await _authService.completeBasicProfile(
        firstName,
        lastName,
      );

      if (result['success'] == true) {
        _user = result['user'] as UserModel;
        _logger.i('Basic profile completed - User: ${_user?.name}');
        return true;
      }

      _error = 'Failed to complete profile';
      return false;
    } catch (e) {
      _logger.e('Complete basic profile error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tokenRefreshService.stopAutoRefresh();
    super.dispose();
  }
}
