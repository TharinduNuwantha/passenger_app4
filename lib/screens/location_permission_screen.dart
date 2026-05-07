import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';

class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const LocationPermissionScreen({super.key, required this.onGranted});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isChecking = true;
  bool _isServiceEnabled = false;
  LocationPermission _permission = LocationPermission.denied;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _checkLocationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationStatus();
    }
  }

  Future<void> _checkLocationStatus() async {
    if (!mounted) return;
    setState(() => _isChecking = true);

    try {
      _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      _permission = await Geolocator.checkPermission();

      if (_isServiceEnabled &&
          (_permission == LocationPermission.always ||
              _permission == LocationPermission.whileInUse)) {
        widget.onGranted();
      }
    } catch (e) {
      debugPrint('Error checking location: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _requestPermission() async {
    _permission = await Geolocator.requestPermission();
    _checkLocationStatus();
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    _checkLocationStatus();
  }

  Future<void> _enableLocationService() async {
    await Geolocator.openLocationSettings();
    _checkLocationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B0B0D), // Midnight Black
                  Color(0xFF111C2E), // Royal Navy
                ],
              ),
            ),
          ),
          
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Animated Icon
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 72,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  const Text(
                    'Location Services',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'To access premium features like real-time tracking and nearby lounges, please enable location access.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // Action Button Area
                  if (!_isChecking) ...[
                    _buildStateSpecificUI(),
                  ] else
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    
                  const SizedBox(height: 40),
                  
                  // Trust Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, 
                        size: 16, 
                        color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 8),
                      Text(
                        'Your data is private and secure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

  Widget _buildStateSpecificUI() {
    if (!_isServiceEnabled) {
      return _buildActionButton(
        label: 'Enable GPS',
        subtitle: 'Turn on location services',
        onPressed: _enableLocationService,
        icon: Icons.gps_fixed_rounded,
      );
    } else if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      return _buildActionButton(
        label: _permission == LocationPermission.deniedForever
            ? 'Open Settings'
            : 'Grant Permission',
        subtitle: _permission == LocationPermission.deniedForever
            ? 'Permission is required to continue'
            : 'Allow app to use your location',
        onPressed: _permission == LocationPermission.deniedForever
            ? _openSettings
            : _requestPermission,
        icon: _permission == LocationPermission.deniedForever
            ? Icons.settings_rounded
            : Icons.security_rounded,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
