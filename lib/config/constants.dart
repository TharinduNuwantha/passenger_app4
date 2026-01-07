class AppConstants {
  // App Information
  static const String appName = 'AASL Passenger';
  static const String appVersion = '2.0.0';

  // Phone Number
  static const String countryCode = '+94';
  static const String countryISOCode = 'LK';
  static const int phoneNumberLength = 9; // Without leading 0
  static const int phoneNumberLengthWithZero = 10; // With leading 0

  // OTP
  static const int otpLength = 6;
  static const int otpResendTimeout = 60; // seconds
  static const int otpExpiryTime = 600; // 10 minutes in seconds

  // Token
  static const int tokenRefreshThreshold = 5; // minutes before expiry

  // Rate Limiting
  static const int maxOtpAttempts = 3;
  static const int rateLimitWindow = 600; // 10 minutes in seconds

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // Error Messages
  static const String networkError =
      'No internet connection. Please check your network and try again.';
  static const String serverError =
      'Something went wrong. Please try again later.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';
  static const String invalidPhoneError = 'Please enter a valid mobile number.';
  static const String invalidOtpError = 'Please enter a valid 6-digit code.';
  static const String otpExpiredError =
      'Code has expired. Please request a new one.';
  static const String tooManyAttemptsError =
      'Too many attempts. Please try again in 10 minutes.';

  // Success Messages
  static const String otpSentSuccess = 'Verification code sent!';
  static const String loginSuccess = 'Welcome!';
  static const String profileUpdatedSuccess = 'Profile updated successfully!';
  static const String logoutSuccess = 'Logged out successfully!';

  // Validation Patterns
  static final RegExp phonePattern = RegExp(r'^[0-9]{9,10}$');
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp otpPattern = RegExp(r'^[0-9]{6}$');

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Routes
  static const String splashRoute = '/';
  static const String phoneInputRoute = '/phone-input';
  static const String otpVerificationRoute = '/otp-verification';
  static const String completeProfileRoute = '/complete-profile';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit-profile';
}
