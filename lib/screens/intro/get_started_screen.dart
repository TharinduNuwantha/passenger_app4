import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme_config.dart';
import '../auth/phone_input_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  Future<void> _navigateToLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true); // Mark as seen

    if (context.mounted) {
      // Return to PhoneInputScreen which will now pass the check and show the UI
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Error Handling
          Positioned.fill(
            child: Image.asset(
              'assets/images/IMG_20260106_214547.png', // Corrected path to match pubspec.yaml
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to a dark blue gradient if the image asset is not found
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF001A35), Colors.black],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.directions_bus_filled_outlined,
                      size: 120,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                );
              },
            ),
          ),

          // Dark Overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (Matching screenshot)
                  
                  
                  const Spacer(),

                  // Title (Matching screenshot)
                  const Text(
                    'Most Affordable\nBus Rental Service',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Convenience on a budget with our Most Affordable Bus Rental Service app',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Get Started Button
                  InkWell(
                    onTap: () => _navigateToLogin(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary, // Using theme Primary Blue
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
