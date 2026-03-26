import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:logger/logger.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_overlay.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Logger _logger = Logger();

  int _resendCountdown = AppConstants.otpResendTimeout;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false; // Flag to prevent duplicate verification calls
  String? _appSignature;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _listenForSmsCode();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    cancel(); // Cancel SMS listener
    super.dispose();
  }

  @override
  void codeUpdated() {
    // This method is called when SMS with OTP is received
    if (code != null && code!.length == AppConstants.otpLength) {
      _logger.i('📱 SMS OTP Auto-filled: $code');
      setState(() {
        _otpController.text = code!;
      });
      // Auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _otpController.text.length == AppConstants.otpLength) {
          _verifyOtp();
        }
      });
    }
  }

  void _listenForSmsCode() async {
    try {
      // Get app signature for logging (development only)
      _appSignature = await SmsAutoFill().getAppSignature;
      _logger.i('📱 App Signature: $_appSignature');
      _logger.i('📱 Listening for SMS with OTP...');

      // Start listening for OTP SMS
      // Note: With SMS Retriever API, no permission dialog is shown
      // If you want "Allow/Deny" dialog, you need to manually request
      // READ_SMS permission using permission_handler package
      listenForCode();
    } catch (e) {
      _logger.e('Error setting up SMS auto-fill: $e');
    }
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = AppConstants.otpResendTimeout;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    // Prevent duplicate verification calls
    if (_isVerifying) {
      _logger.i('⚠️ Verification already in progress, ignoring duplicate call');
      return;
    }

    if (_otpController.text.length != AppConstants.otpLength) {
      ErrorDialog.show(
        context: context,
        message: 'Please enter the complete 6-digit code',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(
      widget.phoneNumber,
      _otpController.text,
    );

    if (!mounted) return;

    if (success) {
      // Check if profile is complete
      final user = authProvider.user;
      if (user != null && !user.profileCompleted) {
        // New user - navigate to complete profile screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppConstants.completeProfileRoute,
          (route) => false,
        );
      } else {
        // Existing user with complete profile - navigate to home
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppConstants.homeRoute, (route) => false);
      }
    } else {
      // Reset flag on error
      setState(() {
        _isVerifying = false;
      });

      ErrorDialog.show(
        context: context,
        message:
            authProvider.error ??
            'Invalid verification code. Please try again.',
        onRetry: _verifyOtp,
      );
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(widget.phoneNumber);

    if (!mounted) return;

    if (success) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New code sent! Check your SMS.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final isRateLimit = authProvider.error?.contains('Too many') ?? false;
      
      ErrorDialog.show(
        context: context,
        title: isRateLimit ? 'Too Many Requests' : 'Error',
        message: authProvider.error ?? 'Failed to send code. Please try again.',
        onRetry: isRateLimit ? null : _resendOtp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Verifying...',
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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
                              const SizedBox(height: AppSpacing.small),

                              // Icon
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sms_rounded,
                                    size: 56,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Title
                              const Text(
                                'Verify Your Number',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.small),

                              // Phone Number
                              Text(
                                'Enter the 6-digit code sent to\n${PhoneFormatter.formatForDisplay(widget.phoneNumber)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // OTP Input
                              Pinput(
                                controller: _otpController,
                                length: AppConstants.otpLength,
                                defaultPinTheme: PinTheme(
                                  width: 54,
                                  height: 64,
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 54,
                                  height: 64,
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                submittedPinTheme: PinTheme(
                                  width: 54,
                                  height: 64,
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onCompleted: (pin) => _verifyOtp(),
                                autofocus: true,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Verify Button
                              CustomButton(
                                text: 'Verify & Continue',
                                onPressed: _verifyOtp,
                                icon: Icons.check_circle_rounded,
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Resend Section
                              Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Didn\'t receive the code?',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.small),
                                    if (_canResend)
                                      TextButton(
                                        onPressed: _resendOtp,
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.medium,
                                            vertical: AppSpacing.small,
                                          ),
                                        ),
                                        child: const Text(
                                          'Resend Code',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.medium,
                                          vertical: AppSpacing.small,
                                        ),
                                        child: Text(
                                          'Resend in $_resendCountdown seconds',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.large),

                              // Change Number Button
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text('Change Mobile Number'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
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
