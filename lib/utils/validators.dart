import '../config/constants.dart';

class Validators {
  // Phone Number Validator
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');

    // Check if it starts with 0 and has 10 digits, or has 9 digits
    if (cleanNumber.length == AppConstants.phoneNumberLengthWithZero) {
      if (!cleanNumber.startsWith('0')) {
        return 'Phone number should start with 0';
      }
      return null;
    } else if (cleanNumber.length == AppConstants.phoneNumberLength) {
      return null;
    }

    return 'Please enter a valid Sri Lankan phone number';
  }

  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }

    if (!AppConstants.emailPattern.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // OTP Validator
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length != AppConstants.otpLength) {
      return 'OTP must be ${AppConstants.otpLength} digits';
    }

    if (!AppConstants.otpPattern.hasMatch(value)) {
      return 'OTP must contain only numbers';
    }

    return null;
  }

  // Name Validator
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Name is optional
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  // Required Field Validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Generic Length Validator
  static String? validateLength(
    String? value,
    int minLength,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    return null;
  }
}
