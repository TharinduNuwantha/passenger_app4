import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../intro/get_started_screen.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_overlay.dart';

/// Input formatter to block leading zero in phone numbers
class NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Block input if user tries to enter "0" as first character
    if (newValue.text.isNotEmpty && newValue.text[0] == '0') {
      return oldValue; // Return old value, effectively blocking the "0"
    }
    return newValue; // Allow the input
  }
}

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isValid = true;
  bool _isChecking = true; // Gatekeeper flag

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the context is ready for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
    });
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check ifintro seen or if user is authenticated
    final bool hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!mounted) return;

    // 1. If already logged in, go to home
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
      return;
    }

    // 2. If first run (intro not seen), go to GetStartedScreen
    if (!hasSeenIntro) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      );
      return;
    }

    // 3. Otherwise, show this screen (PhoneInput)
    setState(() {
      _isChecking = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    // Dismiss keyboard when Send OTP is tapped
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isValid) {
      ErrorDialog.show(
        context: context,
        message: 'Please enter a valid mobile number',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(_completePhoneNumber);

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent! Check your SMS.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to OTP verification
      Navigator.of(context).pushNamed(
        AppConstants.otpVerificationRoute,
        arguments: {'phoneNumber': _completePhoneNumber},
      );
    } else {
      final isRateLimit = authProvider.error?.contains('Too many') ?? false;
      
      ErrorDialog.show(
        context: context,
        title: isRateLimit ? 'Too Many Requests' : 'Error',
        message: authProvider.error ?? 'Failed to send verification code',
        onRetry: isRateLimit ? null : _sendOtp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(backgroundColor: Colors.white);
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Processing...',
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/IMG_20260106_214510.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Form Content
                Column(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 40,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Log In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Log in to continue your seamless journey',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color.fromARGB(255, 139, 139, 139),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Phone Input Styled as per image
                            IntlPhoneField(
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.black),
                              dropdownTextStyle: const TextStyle(color: Colors.black),
                              inputFormatters: [NoLeadingZeroFormatter()],
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                hintText: 'Mobile Number',
                                hintStyle: const TextStyle(color: Colors.black38),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              initialCountryCode: AppConstants.countryISOCode,
                              disableLengthCheck: true,
                              onChanged: (phone) {
                                setState(() {
                                  _completePhoneNumber = phone.completeNumber;
                                });
                              },
                              validator: (phone) {
                                if (phone == null || phone.number.isEmpty) {
                                  return 'Please enter your mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 25),
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _sendOtp,
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20)
        
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
