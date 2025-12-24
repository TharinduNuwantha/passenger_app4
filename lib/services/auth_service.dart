import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';
import '../utils/error_handler.dart';
import '../utils/phone_formatter.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  final Logger _logger = Logger();

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      _logger.i('Sending OTP to: $phoneNumber');

      // Format phone number for API
      final formattedPhone = PhoneFormatter.formatForApi(phoneNumber);
      _logger.i('Formatted phone for API: $formattedPhone'); // Debug log

      // Use extended timeout for SMS operations (Dialog gateway can be slow)
      final response = await _apiService.post(
        ApiConfig.sendOtpEndpoint,
        data: {'phone_number': formattedPhone, 'app_type': 'passenger'},
        options: Options(
          receiveTimeout: ApiConfig.smsTimeout,
          sendTimeout: ApiConfig.smsTimeout,
        ),
      );

      if (response.statusCode == 200) {
        _logger.i('OTP sent successfully');

        final data = response.data as Map<String, dynamic>;

        // Return response (production mode - no OTP in response)
        return {
          'success': true,
          'message': data['message'] as String? ?? 'OTP sent successfully',
        };
      }

      throw 'Failed to send OTP';
    } catch (e) {
      _logger.e('Send OTP error: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      _logger.i('Verifying OTP for: $phoneNumber');

      // Format phone number for API
      final formattedPhone = PhoneFormatter.formatForApi(phoneNumber);

      final response = await _apiService.post(
        ApiConfig.verifyOtpEndpoint,
        data: {'phone_number': formattedPhone, 'otp': otp},
      );

      if (response.statusCode == 200) {
        _logger.i('OTP verified successfully - Status: ${response.statusCode}');

        final data = response.data as Map<String, dynamic>;
        _logger.i('DEBUG - Response data keys: ${data.keys}');

        // Extract tokens - backend returns 'expires_in_seconds', not 'expires_in'
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        final expiresIn =
            data['expires_in_seconds'] as int? ?? 3600; // Default to 1 hour

        _logger.i(
          'DEBUG - Tokens extracted: access=${accessToken.substring(0, 20)}..., refresh=${refreshToken.substring(0, 20)}..., expires=$expiresIn',
        );

        // Save tokens first so we can use them for API calls
        await _storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: expiresIn,
        );

        _logger.i('DEBUG - Tokens saved to storage');

        // Now fetch the user profile using the access token
        try {
          _logger.i('DEBUG - Fetching user profile...');

          final profileResponse = await _apiService.get(
            ApiConfig.profileEndpoint,
          );

          if (profileResponse.statusCode == 200) {
            final userData = profileResponse.data as Map<String, dynamic>;
            _logger.i('DEBUG - User data from profile: $userData');

            final user = UserModel.fromJson(userData);
            _logger.i(
              'DEBUG - User model created: ${user.name}, ${user.phoneNumber}',
            );

            await _storage.saveUserData(user);
            _logger.i('DEBUG - User data saved to storage');

            // Create tokens model
            final tokens = AuthTokensModel(
              accessToken: accessToken,
              refreshToken: refreshToken,
              expiresIn: expiresIn,
              expiryTime: DateTime.now().add(Duration(seconds: expiresIn)),
            );

            _logger.i('DEBUG - Returning success with user and tokens');
            return {'success': true, 'tokens': tokens, 'user': user};
          }
        } catch (profileError) {
          _logger.e('DEBUG - Error fetching profile: $profileError');
          // If profile fetch fails, create a minimal user object
          // This shouldn't happen, but we handle it gracefully
        }

        // Fallback: Create minimal user from JWT data
        _logger.w('DEBUG - Using fallback user creation');
        final userData = {
          'id': '', // We'll get this from profile later
          'phone': '', // We'll get this from profile later
          'email': null,
          'first_name': null,
          'last_name': null,
          'roles': ['passenger'],
          'profile_completed': data['profile_complete'] ?? false,
          'phone_verified': true,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final user = UserModel.fromJson(userData);
        await _storage.saveUserData(user);

        final tokens = AuthTokensModel(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: expiresIn,
          expiryTime: DateTime.now().add(Duration(seconds: expiresIn)),
        );

        return {'success': true, 'tokens': tokens, 'user': user};
      }

      throw 'Failed to verify OTP';
    } catch (e) {
      _logger.e('Verify OTP error: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      _logger.i('Refreshing token');

      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('No refresh token available');
        return false;
      }

      final response = await _apiService.post(
        ApiConfig.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        _logger.i('Token refreshed successfully');

        final data = response.data as Map<String, dynamic>;

        // Get expires_in - backend returns 'expires_in_seconds'
        final expiresIn = (data['expires_in_seconds'] ?? data['expires_in'] ?? 3600) as int;

        // Save new tokens
        await _storage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String? ?? refreshToken, // Use new or keep old
          expiresIn: expiresIn,
        );

        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Refresh token error: $e');
      return false;
    }
  }

  // Logout (single device)
  Future<bool> logout({bool logoutAll = false}) async {
    try {
      _logger.i('Logging out (logoutAll: $logoutAll)');

      final response = await _apiService.post(
        ApiConfig.logoutEndpoint,
        data: {'logout_all': logoutAll},
      );

      if (response.statusCode == 200) {
        _logger.i('Logout successful');

        // Clear local storage
        await _storage.clearAll();

        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Logout error: $e');

      // Clear local storage even if API call fails
      await _storage.clearAll();

      return true; // Return true since local logout succeeded
    }
  }

  // Complete basic profile (first_name + last_name only) - for new passengers
  Future<Map<String, dynamic>> completeBasicProfile(
    String firstName,
    String lastName,
  ) async {
    try {
      _logger.i('Completing basic profile: $firstName $lastName');

      final response = await _apiService.post(
        ApiConfig.completeBasicProfileEndpoint,
        data: {'first_name': firstName, 'last_name': lastName},
      );

      if (response.statusCode == 200) {
        _logger.i('Basic profile completed successfully');

        final data = response.data as Map<String, dynamic>;
        final profileData = data['profile'] as Map<String, dynamic>;

        // Update stored user data
        final user = UserModel.fromJson(profileData);
        await _storage.saveUserData(user);

        return {'success': true, 'user': user};
      }

      throw 'Failed to complete profile';
    } catch (e) {
      _logger.e('Complete basic profile error: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      return await _storage.hasValidTokens();
    } catch (e) {
      _logger.e('Error checking authentication: $e');
      return false;
    }
  }

  // Get current user from storage
  Future<UserModel?> getCurrentUser() async {
    try {
      return await _storage.getUserData();
    } catch (e) {
      _logger.e('Error getting current user: $e');
      return null;
    }
  }
}