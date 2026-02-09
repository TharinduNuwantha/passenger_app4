import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../config/constants.dart';
import '../config/theme_config.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideUp;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 2500));

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0B0D), // Midnight Black
              Color(0xFF111C2E), // Royal Navy
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // === BUS ICON ===
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slideUp,
                  child: Image.asset(
                    'assets/images/only_bus.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // === APP NAME ===
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slideUp,
                  child: Image.asset(
                    'assets/images/only_text.png',
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // === SUBTITLE WITH SHIMMER ===
              FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // shimmer effect
                    final shimmerValue =
                        (0.5 + (0.5 * (1 + sin(_controller.value * 6.28))));
                    return Opacity(
                      opacity: shimmerValue,
                      child: Text(
                        'PASSENGER',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(flex: 2),

              // === PULSE LOADING INDICATOR ===
              FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * sin(_controller.value * 6.28)),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // VERSION
              FadeTransition(
                opacity: _fade,
                child: Text(
                  'V2.6.3 • © 2026 BusLounge',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}