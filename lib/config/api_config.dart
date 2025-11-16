class ApiConfig {
  // Base URL Configuration
  // PRODUCTION: Choreo deployment
  // Development: Use 10.0.2.2:8080 (Android emulator) or localhost:8080 (iOS simulator)
  // Physical device (local): Use your computer's IP (e.g., 192.168.1.100:8080)

  // CHOREO PRODUCTION URL
  static const String baseUrl = 'https://a9a9815d-fed9-4f0e-bf6f-706f789df0f3-dev.e1-us-east-azure.choreoapis.dev/default/backend/v1.0';

  // API Endpoints
  static const String sendOtpEndpoint = '/api/v1/auth/send-otp';
  static const String verifyOtpEndpoint = '/api/v1/auth/verify-otp';
  static const String refreshTokenEndpoint = '/api/v1/auth/refresh';
  static const String profileEndpoint = '/api/v1/user/profile';
  static const String updateProfileEndpoint = '/api/v1/user/profile';
  static const String logoutEndpoint = '/api/v1/auth/logout';

  // Search Endpoints
  static const String searchTripsEndpoint = '/api/v1/search';
  static const String popularRoutesEndpoint = '/api/v1/search/popular';
  static const String autocompleteEndpoint = '/api/v1/search/autocomplete';
  static const String searchHealthEndpoint = '/api/v1/search/health';

  // Full URLs
  static String get sendOtpUrl => '$baseUrl$sendOtpEndpoint';
  static String get verifyOtpUrl => '$baseUrl$verifyOtpEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get profileUrl => '$baseUrl$profileEndpoint';
  static String get updateProfileUrl => '$baseUrl$updateProfileEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
}
