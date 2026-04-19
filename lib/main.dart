import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'config/constants.dart';
import 'config/theme_config.dart' show AppTheme;
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
import 'theme/app_colors.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
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
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => BookingIntentProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
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
                  return MaterialPageRoute(builder: (_) => const DashBoard());

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
// TharinduPakaya6454