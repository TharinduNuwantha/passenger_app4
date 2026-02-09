import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';
import 'storage_service.dart';

class UserService {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  final Logger _logger = Logger();

  // Get user profile
  Future<UserModel> getProfile() async {
    try {
      _logger.i('Fetching user profile');

      final response = await _apiService.get(ApiConfig.profileEndpoint);

      if (response.statusCode == 200) {
        _logger.i('Profile fetched successfully');

        final data = response.data as Map<String, dynamic>;
        final user = UserModel.fromJson(data);

        // Save user data to storage
        await _storage.saveUserData(user);

        return user;
      }

      throw 'Failed to fetch profile';
    } catch (e) {
      _logger.e('Get profile error: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // Update user profile
  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? address,
    String? city,
    String? postalCode,
  }) async {
    try {
      _logger.i('Updating user profile');

      // Prepare update data - backend requires non-empty address fields
      final Map<String, dynamic> updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'address': address != null && address.isNotEmpty ? address : 'N/A',
        'city': city != null && city.isNotEmpty ? city : 'N/A',
        'postal_code': postalCode != null && postalCode.isNotEmpty ? postalCode : '00000',
      };

      final response = await _apiService.put(
        ApiConfig.updateProfileEndpoint,
        data: updateData,
      );

      if (response.statusCode == 200) {
        _logger.i('Profile updated successfully');

        final data = response.data as Map<String, dynamic>;

        // Extract user from response - backend returns profile under 'profile' key
        UserModel user;
        if (data.containsKey('profile')) {
          user = UserModel.fromJson(data['profile'] as Map<String, dynamic>);
        } else if (data.containsKey('user')) {
          user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        } else {
          user = UserModel.fromJson(data);
        }

        // Save updated user data to storage
        await _storage.saveUserData(user);

        return user;
      }

      throw 'Failed to update profile';
    } catch (e) {
      _logger.e('Update profile error: $e');
      throw ErrorHandler.handleError(e);
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

  // Refresh user profile from server
  Future<UserModel?> refreshProfile() async {
    try {
      return await getProfile();
    } catch (e) {
      _logger.e('Error refreshing profile: $e');
      return null;
    }
  }
}
