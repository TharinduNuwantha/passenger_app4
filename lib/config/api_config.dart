import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL Configuration
  // PRODUCTION: Choreo deployment (from environment variables)
  // Development: Use 10.0.2.2:8080 (Android emulator) or localhost:8080 (iOS simulator)
  // Physical device (local): Use your computer's IP (e.g., 192.168.1.100:8080)

  // Load base URL from environment variables (secure)
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://a9a9815d-fed9-4f0e-bf6f-706f789df0f3-dev.e1-us-east-azure.choreoapis.dev/default/backend/v1.0';

  // Google Maps API Key (for location autocomplete - will be replaced with backend autocomplete)
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // API Endpoints
  static const String sendOtpEndpoint = '/api/v1/auth/send-otp';
  static const String verifyOtpEndpoint = '/api/v1/auth/verify-otp';
 // static const String refreshTokenEndpoint = '/api/v1/auth/refresh';QrBitBuffer
 static const String refreshTokenEndpoint = '/api/v1/auth/refresh';
  static const String profileEndpoint = '/api/v1/user/profile';
  static const String updateProfileEndpoint = '/api/v1/user/profile';
    static const String completeBasicProfileEndpoint =
      '/api/v1/auth/complete-basic-profile';
  static const String logoutEndpoint = '/api/v1/auth/logout';

  // Search Endpoints
  static const String searchTripsEndpoint = '/api/v1/search';
  static const String popularRoutesEndpoint = '/api/v1/search/popular';
  static const String autocompleteEndpoint = '/api/v1/search/autocomplete';
  static const String searchHealthEndpoint = '/api/v1/search/health';

  // Notification Endpoints
  static const String notificationsEndpoint = '/api/v1/notifications';
  static const String notificationReadEndpoint = '/api/v1/notifications';
  static const String notificationReadAllEndpoint = '/api/v1/notifications/read-all';
  static const String notificationUnreadCountEndpoint = '/api/v1/notifications/unread-count';

  // Full URLs - Auth
  static String get sendOtpUrl => '$baseUrl$sendOtpEndpoint';
  static String get verifyOtpUrl => '$baseUrl$verifyOtpEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get profileUrl => '$baseUrl$profileEndpoint';
  static String get updateProfileUrl => '$baseUrl$updateProfileEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';

  // Full URLs - Search
  static String get searchTripsUrl => '$baseUrl$searchTripsEndpoint';
  static String get popularRoutesUrl => '$baseUrl$popularRoutesEndpoint';
  static String get autocompleteUrl => '$baseUrl$autocompleteEndpoint';
  static String get searchHealthUrl => '$baseUrl$searchHealthEndpoint';

  // Full URLs - Notifications
  static String get notificationsUrl => '$baseUrl$notificationsEndpoint';
  static String get notificationReadAllUrl => '$baseUrl$notificationReadAllEndpoint';
  static String get notificationUnreadCountUrl => '$baseUrl$notificationUnreadCountEndpoint';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Extended timeout for slow operations (SMS sending)
  static const Duration smsTimeout = Duration(seconds: 60);
}
