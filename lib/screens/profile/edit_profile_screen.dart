import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/blue_header.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final UserService _userService = UserService();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = await _userService.getProfile();
      authProvider.updateUser(user);

      if (!mounted) return;
      setState(() {
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _emailController.text = user.email ?? '';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    final t = (String key) => AppLocalization.tr(context, key);

    setState(() {
      isSaving = true;
    });

    try {
      final updatedUser = await _userService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.updateUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('profileUpdatedSuccessfully')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('failedToSaveProfile')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLanguageCode = context.watch<LanguageProvider>().languageCode;
    final t = (String key) => AppLocalization.tr(context, key);

    return Scaffold(
      key: ValueKey('edit-profile-$activeLanguageCode'),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BlueHeader(
            bottomRadius: 30,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    t('editProfile'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Spacer for balance
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar Section
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Hero(
                              tag: 'profile-avatar',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.1),
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.05),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: AppColors.primary.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        _buildSettingsField(
                          label: t('firstName'),
                          controller: _firstNameController,
                          icon: Icons.person_outline_rounded,
                          hintText: t('enterFirstName'),
                        ),
                        const SizedBox(height: 20),
                        _buildSettingsField(
                          label: t('lastName'),
                          controller: _lastNameController,
                          icon: Icons.person_outline_rounded,
                          hintText: t('enterLastName'),
                        ),
                        const SizedBox(height: 20),
                        _buildSettingsField(
                          label: t('emailLabel'),
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hintText: t('yourEmail'),
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 50),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _validateAndSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _buildActionButtonChild(context),
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

  void _validateAndSave() {
    final t = (String key) => AppLocalization.tr(context, key);

    if (_firstNameController.text.trim().isEmpty) {
      _showWarning(t('pleaseEnterFirstName'));
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showWarning(t('pleaseEnterYourEmail'));
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showWarning(t('pleaseEnterValidEmail'));
      return;
    }
    _saveUserData();
  }

  Widget _buildSaveButtonText(BuildContext context) {
    final t = (String key) => AppLocalization.tr(context, key);
    return Text(
      t('saveChanges'),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSavingIndicator() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }

  Widget _buildActionButtonChild(BuildContext context) {
    if (isSaving) return _buildSavingIndicator();
    return _buildSaveButtonText(context);
  }

  Widget _buildSettingsField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
