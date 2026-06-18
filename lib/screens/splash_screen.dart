import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../config/constants.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    // Run auth check and minimum branding time in parallel
    // This saves ~1s compared to waiting 2500ms THEN checking auth
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await Future.wait([
      authProvider.checkAuthStatus(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted) return;

    // Navigate based on auth status
    if (authProvider.isAuthenticated) {
      // Check if profile is complete
      final user = authProvider.user;
      if (user != null && !user.profileCompleted) {
        Navigator.of(
          context,
        ).pushReplacementNamed(AppConstants.completeProfileRoute);
      } else {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenHeight = constraints.maxHeight;
              final double logoSize = (screenHeight * 0.22).clamp(80.0, 200.0);
              final double textWidth = (screenHeight * 0.22).clamp(100.0, 200.0);
              final double spacing = (screenHeight * 0.025).clamp(6.0, 24.0);

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: spacing * 2),

                      // === BUS ICON ===
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Image.asset(
                            'assets/images/only_bus.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      SizedBox(height: spacing),

                      // === APP NAME ===
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Image.asset(
                            'assets/images/only_text.png',
                            width: textWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      SizedBox(height: spacing * 0.4),

                      // === SUBTITLE WITH SHIMMER ===
                      FadeTransition(
                        opacity: _fade,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            // shimmer effect
                            final shimmerValue =
                                (0.65 + (0.35 * sin(_controller.value * 2 * pi))).clamp(0.0, 1.0);
                            return Opacity(
                              opacity: shimmerValue,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'PASSENGER',
                                  style: TextStyle(
                                    fontSize: (screenHeight * 0.018).clamp(11.0, 14.0),
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: spacing * 3),

                      // === PULSE LOADING INDICATOR ===
                      FadeTransition(
                        opacity: _fade,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final double dotSize = (screenHeight * 0.018).clamp(10.0, 14.0);
                            return Transform.scale(
                              scale: 0.9 + (0.1 * sin(_controller.value * 6.28)),
                              child: Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: spacing * 1.5),

                      // VERSION
                      FadeTransition(
                        opacity: _fade,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'V2.6.3 • © 2026 BusLounge',
                            style: TextStyle(
                              fontSize: (screenHeight * 0.015).clamp(10.0, 12.0),
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: spacing),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
}