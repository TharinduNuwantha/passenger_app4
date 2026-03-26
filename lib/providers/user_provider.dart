import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final Logger _logger = Logger();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch user profile
  Future<void> fetchProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _logger.i('Fetching user profile');

      _user = await _userService.getProfile();

      _logger.i('Profile fetched successfully');
    } catch (e) {
      _logger.e('Fetch profile error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _logger.i('Updating user profile');

      _user = await _userService.updateProfile(
        firstName: firstName ?? '',
        lastName: lastName ?? '',
        email: email ?? '',
      );

      _logger.i('Profile updated successfully');
      return true;
    } catch (e) {
      _logger.e('Update profile error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh profile from server
  Future<void> refreshProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _logger.i('Refreshing user profile');

      final updatedUser = await _userService.refreshProfile();

      if (updatedUser != null) {
        _user = updatedUser;
        _logger.i('Profile refreshed successfully');
      }
    } catch (e) {
      _logger.e('Refresh profile error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user from storage
  Future<void> loadUserFromStorage() async {
    try {
      _logger.i('Loading user from storage');

      _user = await _userService.getCurrentUser();

      if (_user != null) {
        _logger.i('User loaded from storage');
      } else {
        _logger.w('No user found in storage');
      }

      notifyListeners();
    } catch (e) {
      _logger.e('Load user error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear user data
  void clearUser() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set user (used by auth provider)
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }
}
