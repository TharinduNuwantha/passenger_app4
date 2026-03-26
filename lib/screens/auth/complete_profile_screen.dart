import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart' hide AppColors;
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_overlay.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

/// Screen shown to new passengers after OTP verification
/// Collects only first_name and last_name to complete their profile
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final Logger _logger = Logger();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    _logger.i('Submitting profile: $firstName $lastName');

    // Save to SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firstName', firstName);
      await prefs.setString('lastName', lastName);
      await prefs.setBool('profileCompleted', true);
      _logger.i('Profile saved to SharedPreferences');
    } catch (e) {
      _logger.e('Error saving to SharedPreferences: $e');
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.completeBasicProfile(
      firstName,
      lastName,
    );

    if (!mounted) return;

    if (success) {
      _logger.i('Profile completed, navigating to home');
      // Navigate to home and remove all previous routes
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppConstants.homeRoute, (route) => false);
    } else {
      ErrorDialog.show(
        context: context,
        message:
            authProvider.error ??
            'Failed to complete profile. Please try again.',
        onRetry: _submitProfile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Saving...',
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Welcome Icon with Add Badge
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Center(
                        child: Text(
                          'Complete Your Profile',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Center(
                        child: Text(
                          'Please enter your name to get started',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // First Name Field
                      Text(
                        'First Name',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _firstNameController,
                        focusNode: _firstNameFocusNode,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Enter your first name',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: AppColors.surfaceWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color.fromARGB(255, 36, 100, 237)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your first name';
                          }
                          if (value.trim().length < 2) {
                            return 'First name must be at least 2 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_lastNameFocusNode);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Last Name Field
                      Text(
                        'Last Name',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lastNameController,
                        focusNode: _lastNameFocusNode,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Enter your Last Name',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: AppColors.surfaceWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color.fromARGB(255, 36, 100, 237)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your last name';
                          }
                          if (value.trim().length < 2) {
                            return 'Last name must be at least 2 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submitProfile(),
                      ),

                      const SizedBox(height: 48),

                      // Continue Button
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : _submitProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info text
                      Center(
                        child: Text(
                          'You can add more details later in your profile settings',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
