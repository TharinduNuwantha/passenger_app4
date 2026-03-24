import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localization.dart';
import '../intro/get_started_screen.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
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
    final t = (String key) => AppLocalization.tr(context, key);

    // Dismiss keyboard when Send OTP is tapped
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isValid) {
      ErrorDialog.show(context: context, message: t('pleaseEnterValidMobile'));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(_completePhoneNumber);

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('verificationCodeSent')),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
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
        title: isRateLimit ? t('tooManyRequests') : t('error'),
        message: authProvider.error ?? t('failedToSendCode'),
        onRetry: isRateLimit ? null : _sendOtp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = (String key) => AppLocalization.tr(context, key);

    if (_isChecking) {
      return const Scaffold(backgroundColor: Colors.white);
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: t('processing'),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leadingWidth: 0,
              automaticallyImplyLeading: false,
              actions: [
                // Language Switcher Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: _buildLanguageSwitcher(context),
                  ),
                ),
              ],
            ),
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
                            Text(
                              t('loginTitle'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              t('loginSubtitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 139, 139, 139),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Phone Input Styled as per image
                            IntlPhoneField(
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.black),
                              dropdownTextStyle: const TextStyle(
                                color: Colors.black,
                              ),
                              inputFormatters: [NoLeadingZeroFormatter()],
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                hintText: t('mobileNumber'),
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
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
                                  return t('pleaseEnterMobileNumber');
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
                                child: Text(
                                  t('loginButton'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context) {
    final t = (String key) => AppLocalization.tr(context, key);
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return GestureDetector(
          onTap: () {
            _showLanguageSheet(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _getLanguageLabel(languageProvider.languageCode),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLanguageLabel(String code) {
    switch (code) {
      case AppLocalization.english:
        return 'EN';
      case AppLocalization.sinhala:
        return 'සි';
      case AppLocalization.tamil:
        return 'த';
      default:
        return 'EN';
    }
  }

  void _showLanguageSheet(BuildContext context) {
    final t = (String key) => AppLocalization.tr(context, key);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('changeLanguage'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageOption(
                    context,
                    AppLocalization.english,
                    t('englishLabel'),
                    languageProvider.languageCode == AppLocalization.english,
                  ),
                  _buildLanguageOption(
                    context,
                    AppLocalization.sinhala,
                    t('sinhalaLabel'),
                    languageProvider.languageCode == AppLocalization.sinhala,
                  ),
                  _buildLanguageOption(
                    context,
                    AppLocalization.tamil,
                    t('tamilLabel'),
                    languageProvider.languageCode == AppLocalization.tamil,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String code,
    String label,
    bool isSelected,
  ) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return ListTile(
          leading: Radio<String>(
            value: code,
            groupValue: languageProvider.languageCode,
            onChanged: (value) async {
              if (value != null) {
                await Provider.of<LanguageProvider>(context, listen: false)
                    .setLocaleByCode(value);
                Navigator.pop(context);
              }
            },
            activeColor: AppColors.primary,
          ),
          title: Text(label),
          onTap: () async {
            await Provider.of<LanguageProvider>(context, listen: false)
                .setLocaleByCode(code);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
