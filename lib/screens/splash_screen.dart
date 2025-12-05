import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme_config.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    // Navigate based on auth status
    if (authProvider.isAuthenticated) {
      // Check if profile is complete
      final user = authProvider.user;
      if (user != null && !user.profileCompleted) {
        // Profile not complete - go to complete profile screen
        Navigator.of(
          context,
        ).pushReplacementNamed(AppConstants.completeProfileRoute);
      } else {
        // Profile complete - go to home
        Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppConstants.phoneInputRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo - LIOR with rounded background
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/lior_logo_no_bg.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              // Tagline
              const Text(
                'Your Journey, Our Priority',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge * 2),

              // Loading Indicator
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
