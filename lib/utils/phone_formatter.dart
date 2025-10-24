import '../config/constants.dart';

class PhoneFormatter {
  // Format phone number for display: 0771234567 -> +94 77 123 4567
  static String formatForDisplay(String phoneNumber) {
    // Remove any non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // If it starts with 0, remove it
    String number = cleanNumber;
    if (number.startsWith('0')) {
      number = number.substring(1);
    }

    // Format: +94 77 123 4567
    if (number.length == AppConstants.phoneNumberLength) {
      return '${AppConstants.countryCode} ${number.substring(0, 2)} ${number.substring(2, 5)} ${number.substring(5)}';
    }

    return phoneNumber; // Return original if can't format
  }

  // Format phone number for API: +94 77 123 4567 -> 0771234567
  static String formatForApi(String phoneNumber) {
    // Remove any non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // If it starts with country code (94), remove it
    if (cleanNumber.startsWith('94')) {
      cleanNumber = cleanNumber.substring(2);
    }

    // If it doesn't start with 0, add it
    if (!cleanNumber.startsWith('0')) {
      cleanNumber = '0$cleanNumber';
    }

    return cleanNumber;
  }

  // Clean phone number: Remove all non-digit characters
  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'\D'), '');
  }

  // Add country code: 771234567 -> +94771234567
  static String addCountryCode(String phoneNumber) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    // If already has country code
    if (cleanNumber.startsWith('94')) {
      return '+$cleanNumber';
    }

    // Remove leading 0 if present
    String number = cleanNumber;
    if (number.startsWith('0')) {
      number = number.substring(1);
    }

    return '+94$number';
  }

  // Mask phone number: 0771234567 -> 077****567
  static String maskPhoneNumber(String phoneNumber) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    if (cleanNumber.length >= 10) {
      return '${cleanNumber.substring(0, 3)}****${cleanNumber.substring(cleanNumber.length - 3)}';
    }

    return phoneNumber;
  }

  // Validate if phone number is Sri Lankan
  static bool isSriLankanNumber(String phoneNumber) {
    final cleanNumber = cleanPhoneNumber(phoneNumber);

    // Check if it's 10 digits starting with 0, or 9 digits, or 11 digits starting with 94
    if (cleanNumber.length == 10 && cleanNumber.startsWith('0')) {
      return true;
    }

    if (cleanNumber.length == 9) {
      return true;
    }

    if (cleanNumber.length == 11 && cleanNumber.startsWith('94')) {
      return true;
    }

    return false;
  }
}
