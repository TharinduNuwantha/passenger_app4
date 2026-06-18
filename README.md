# SmartTransit Passenger App

A Flutter-based mobile application for bus transportation booking and management. Passengers can search for trips, book seats, and manage their reservations with SMS OTP authentication.

##  Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Running the App](#running-the-app)
- [API Integration](#api-integration)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

##  Features

### Authentication
- **SMS OTP Login**: Secure authentication via one-time passwords (OTP)
- **Auto-Read SMS**: Automatic SMS reading on Android (with SMS Autofill)
- **JWT Tokens**: Access and refresh tokens for API security
- **Profile Management**: Complete profile setup and editing

### Trip Management
- **Trip Search**: Search available buses by route, date, and time
- **Real-time Availability**: Live seat availability checking
- **Booking System**: Reserve seats with real-time confirmation
- **Booking History**: View all past and upcoming bookings
- **Cancellation**: Cancel bookings before departure (if allowed)

### User Interface
- **Material Design**: Modern and responsive UI
- **Dark Mode Support**: Light and dark theme switching
- **Multiple Screens**: 
  - Splash screen
  - Phone input
  - OTP verification
  - Profile completion
  - Home/Dashboard
  - Search results
  - Booking management
  - User profile

### Additional Features
- **Google Maps Integration**: Location-based search (future)
- **QR Code Support**: Digital ticketing
- **Multi-language Support**: Internationalization ready
- **Local Storage**: Secure token storage with Flutter Secure Storage

##  Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.8.1 or higher
  - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Included with Flutter
- **Android Studio** (for Android development)
  - Android SDK API level 21+
  - Gradle 8.0+
- **Xcode** (for iOS development - macOS only)
- **Git**: For version control

### Verify Installation
```bash
flutter --version
dart --version
flutter doctor
```

##  Installation

### 1. Clone the Repository
```bash
cd c:\Users\pandu\Documents\AASL\Workspace\passengerApp
cd passenger_app
```

### 2. Get Flutter Dependencies
```bash
flutter pub get
```

### 3. Generate Build Files
```bash
flutter pub run build_runner build
```

### 4. Install Platform-Specific Dependencies

**For Android:**
```bash
# No additional steps needed - Gradle handles it
```

**For iOS (macOS only):**
```bash
cd ios
pod install
cd ..
```

##  Configuration

### 1. Environment Variables

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and configure:

```dotenv
# Backend API Configuration
API_BASE_URL=https://584bf421-3861-4953-806e-cdc205b16164-dev.e1-us-east-azure.choreoapis.dev/bustransportationsystem/backend-mx/v1.0

# Google Maps API Key (optional for location features)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 2. Android Configuration

**Update `android/app/src/main/AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
```

**Add Google Maps (if using location features):**
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

### 3. iOS Configuration

**Update `ios/Runner/Info.plist`:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show nearby transit routes</string>
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan QR codes for tickets</string>
```

##  Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── api_config.dart      # API endpoints and configuration
│   ├── constants.dart       # App-wide constants
│   └── theme_config.dart    # Theme configuration
├── models/
│   ├── auth_models.dart     # Authentication models
│   ├── booking_models.dart  # Booking data models
│   ├── trip_models.dart     # Trip and schedule models
│   └── user_models.dart     # User profile models
├── providers/
│   ├── auth_provider.dart       # Authentication state management
│   ├── booking_intent_provider.dart  # Booking flow management
│   ├── search_provider.dart     # Trip search state
│   ├── theme_provider.dart      # Theme switching
│   └── user_provider.dart       # User profile state
├── screens/
│   ├── splash_screen.dart       # Splash/loading screen
│   ├── auth/
│   │   ├── phone_input_screen.dart      # Phone entry
│   │   ├── otp_verification_screen.dart # OTP verification
│   │   └── complete_profile_screen.dart # Profile setup
│   ├── home/
│   │   ├── home_screen.dart         # Main dashboard
│   │   ├── search_screen.dart       # Search trips
│   │   └── booking_screen.dart      # Booking details
│   └── profile/
│       ├── profile_screen.dart      # User profile
│       ├── edit_profile_screen.dart # Edit profile
│       └── help_and_support.dart    # Support page
├── services/
│   ├── api_service.dart         # HTTP client and API calls
│   ├── auth_service.dart        # Authentication logic
│   ├── booking_service.dart     # Booking operations
│   └── search_service.dart      # Trip search operations
├── theme/
│   ├── app_colors.dart          # Color palette
│   └── app_typography.dart      # Typography styles
├── utils/
│   ├── validators.dart          # Input validation
│   ├── storage_helper.dart      # Secure storage
│   └── logger.dart              # Logging utilities
└── widgets/
    ├── custom_app_bar.dart      # Reusable app bar
    ├── custom_button.dart       # Button components
    └── loading_widget.dart      # Loading indicators
```

##  Running the App

### 1. Run on Android Emulator/Device
```bash
# List connected devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

### 2. Run on iOS (macOS only)
```bash
flutter run -d iphone
```

### 3. Run on Web
```bash
flutter run -d chrome
```

### 4. Run with Hot Reload
```bash
# Press 'r' in the terminal for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

## 🔌 API Integration

### Authentication Flow

1. **Send OTP**
   ```
   POST /api/v1/auth/send-otp
   {
     "phone_number": "+94785957049"
   }
   Response: { "otp": "123456", "expires_at": "..." }
   ```

2. **Verify OTP**
   ```
   POST /api/v1/auth/verify-otp
   {
     "phone_number": "+94785957049",
     "otp": "123456"
   }
   Response: { "access_token": "...", "refresh_token": "..." }
   ```

3. **Use Access Token**
   ```
   Headers:
   Authorization: Bearer <access_token>
   ```

### Key Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/health` | Health check |
| POST | `/api/v1/auth/send-otp` | Send OTP |
| POST | `/api/v1/auth/verify-otp` | Verify OTP & get tokens |
| GET | `/api/v1/user/profile` | Get user profile |
| POST | `/api/v1/search` | Search trips |
| POST | `/api/v1/bookings` | Create booking |
| GET | `/api/v1/bookings` | List user bookings |
| GET | `/api/v1/bookings/{id}` | Get booking details |

### See Backend Documentation
For complete API documentation, visit the backend's swagger.yaml file or access the Postman collection.

##  Testing

### Unit Tests
```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/unit_tests.dart

# Run with coverage
flutter test --coverage
```

### Widget Tests
```bash
# Run all widget tests
flutter test

# Run specific widget test
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] Login with valid phone number
- [ ] OTP auto-read works on Android
- [ ] OTP manual entry works
- [ ] Profile completion saves data
- [ ] Search returns results
- [ ] Booking flow completes successfully
- [ ] Dark mode toggle works
- [ ] App handles network errors gracefully
- [ ] Session refresh with refresh token works
- [ ] Logout clears all data

##  Troubleshooting

### Common Issues

**1. Build Fails with Gradle Error**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build
```

**2. Android Build Error: "minSdkVersion"**
- Edit `android/app/build.gradle.kts`
- Ensure `minSdkVersion = 21` or higher

**3. iOS Pod Installation Fails**
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

**4. API Connection Fails**
- Verify backend is running: `flutter run --release`
- Check `.env` file has correct `API_BASE_URL`
- Check device can reach the API (firewall/network)
- View logs with: `flutter logs`

**5. SMS OTP Not Auto-Reading on Android**
- Run: `flutter run -t lib/get_app_hash.dart`
- Copy the app hash from console
- Update `PASSENGER_APP_HASH` in backend `.env`
- Redeploy backend

**6. Secure Storage Errors**
- For Android: Ensure Android Keystore is available
- For iOS: Check Keychain access permissions

### Debug Mode

Enable detailed logging:
```bash
# View all app logs
flutter logs

# Run with verbose output
flutter run -v

# Debug on Android emulator
adb logcat | grep flutter
```

##  Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Provider Package](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)
- [Firebase Security Best Practices](https://firebase.google.com/docs/best-practices)

##  Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/your-feature`
4. Create Pull Request

##  License

This project is proprietary and confidential. All rights reserved.

---

**Questions or Issues?**
- Check the troubleshooting section above
- Review backend logs at: `AASL_Transit_backend/backend/`
- Contact the development team
