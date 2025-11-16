import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
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
      ErrorDialog.show(
        context: context,
        message: authProvider.error ?? 'Failed to send verification code',
        onRetry: _sendOtp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Sending verification code...',
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.large),

                              // Welcome Icon
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.phone_iphone_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Welcome Title
                              const Text(
                                'Welcome!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.small),

                              // Subtitle
                              const Text(
                                'Enter your mobile number to get started',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(
                                height: AppSpacing.large,
                              ), // Phone Input Field
                              IntlPhoneField(
                                controller: _phoneController,
                                inputFormatters: [
                                  NoLeadingZeroFormatter(), // Block leading "0"
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
                                  hintText: '77 123 4567',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                initialCountryCode: AppConstants.countryISOCode,
                                disableLengthCheck: true,
                                onChanged: (phone) {
                                  setState(() {
                                    _completePhoneNumber = phone.completeNumber;
                                    // _isValid = phone.isValidNumber();
                                  });
                                },
                                validator: (phone) {
                                  if (phone == null || phone.number.isEmpty) {
                                    return 'Please enter your mobile number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Continue Button
                              CustomButton(
                                text: 'Continue',
                                onPressed: _sendOtp,
                                icon: Icons.arrow_forward_rounded,
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Info Card
                              Container(
                                padding: const EdgeInsets.all(
                                  AppSpacing.medium,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.info.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.info,
                                      size: 20,
                                    ),
                                    SizedBox(width: AppSpacing.small),
                                    Expanded(
                                      child: Text(
                                        'We\'ll send you a 6-digit verification code via SMS',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.large),

                              // Terms and Privacy
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.small,
                                ),
                                child: Text(
                                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.medium),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
