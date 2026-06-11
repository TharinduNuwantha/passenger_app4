import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
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
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/help_support.dart';
import 'screens/profile/privacy_policy.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/location_gatekeeper.dart';
import 'screens/bus_booking/booking_detail_screen.dart';
import 'screens/bus_booking/my_bookings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env first (needed for Supabase key)
  await dotenv.load(fileName: ".env");

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('953f9d46-26ca-4f7d-8690-c3cefd7c583f');
  OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    if (data != null && data['booking_id'] != null) {
      final bookingId = data['booking_id'] as String;
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: bookingId),
        ),
      );
    } else {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const MyBookingsScreen(),
        ),
      );
    }
  });

  // Fire Supabase init without awaiting — splash screen animation gives it time
  unawaited(Supabase.initialize(
    url: 'https://pttatcukzpceljcrwehk.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  ));

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
            navigatorKey: navigatorKey,
            title: AppConstants.appName,
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
