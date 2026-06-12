import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'config/constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_intent_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/phone_input_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/help_support.dart';
import 'screens/profile/privacy_policy.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'widgets/location_gatekeeper.dart';

/// Global navigator key — allows navigation from outside the widget tree
/// (e.g. OneSignal notification tap handler in main()).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env first (needed for Supabase key)
  await dotenv.load(fileName: ".env");

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('953f9d46-26ca-4f7d-8690-c3cefd7c583f');
  OneSignal.Notifications.requestPermission(true);

  // Handle push notification tap — navigate to in-app Notifications screen
  OneSignal.Notifications.addClickListener((event) async {
    final notification = event.notification;
    final title = notification.title ?? 'New Notification';
    final body = notification.body ?? '';

    // Persist to local notification cache so the in-app screen shows it
    final notifService = NotificationService();
    final additionalData = notification.additionalData;
    final notifType = (additionalData?['type'] as String?) ?? 'system';
    await notifService.addLocalNotification(
      title: title,
      message: body,
      type: notifType,
    );

    // Navigate to the Notifications screen once the app is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      // Retrieve userId from SharedPreferences is async; we pass '' if unavailable.
      // NotificationsScreen fetches its own data so userId is only needed for
      // filtering — empty string shows all cached notifications.
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(
            userId: additionalData?['user_id'] as String? ?? '',
          ),
        ),
      );
    });
  });

  // Fire Supabase init without awaiting — splash screen animation gives it time
  unawaited(
    Supabase.initialize(
      url: 'https://pttatcukzpceljcrwehk.supabase.co',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadThemeMode()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Lazy: only created when first accessed (booking/search flows)
        ChangeNotifierProvider.value(value: SearchProvider()),
        ChangeNotifierProvider.value(value: BookingIntentProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppConstants.splashRoute,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppConstants.splashRoute:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );

                case AppConstants.phoneInputRoute:
                  return MaterialPageRoute(
                    builder: (_) => const PhoneInputScreen(),
                  );

                case AppConstants.otpVerificationRoute:
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (_) => OtpVerificationScreen(
                      phoneNumber: args?['phoneNumber'] as String? ?? '',
                    ),
                  );

                case AppConstants.completeProfileRoute:
                  return MaterialPageRoute(
                    builder: (_) => const CompleteProfileScreen(),
                  );

                case AppConstants.homeRoute:
                  return MaterialPageRoute(
                    builder: (_) =>
                        const LocationGatekeeper(child: DashBoard()),
                  );

                case AppConstants.profileRoute:
                  return MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  );

                case AppConstants.editProfileRoute:
                  return MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  );

                case '/privacy-policy':
                  return MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  );

                case '/help-support':
                  return MaterialPageRoute(
                    builder: (_) => const HelpSupportScreen(),
                  );

                default:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
