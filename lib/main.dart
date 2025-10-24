import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/phone_input_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash_screen.dart';

void main() {
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

                case AppConstants.homeRoute:
                  return MaterialPageRoute(builder: (_) => const HomeScreen());

                case AppConstants.profileRoute:
                  return MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  );

                case AppConstants.editProfileRoute:
                  return MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
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
