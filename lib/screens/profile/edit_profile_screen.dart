import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_overlay.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Listen to changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = userProvider.user ?? authProvider.user;

    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  void _onFieldChanged() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = userProvider.user ?? authProvider.user;

    if (user != null) {
      final nameChanged = _nameController.text != (user.name ?? '');
      final emailChanged = _emailController.text != (user.email ?? '');

      if (_hasChanges != (nameChanged || emailChanged)) {
        setState(() {
          _hasChanges = nameChanged || emailChanged;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasChanges) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save')));
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await userProvider.updateProfile(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Update user in auth provider
      if (userProvider.user != null) {
        authProvider.updateUser(userProvider.user!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    } else {
      ErrorDialog.show(
        context: context,
        title: 'Update Failed',
        message: userProvider.error ?? 'Failed to update profile',
        onRetry: _saveProfile,
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: LoadingOverlay(
            isLoading: userProvider.isLoading,
            message: 'Updating profile...',
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Edit Profile'),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                (_nameController.text.isNotEmpty
                                        ? _nameController.text[0]
                                        : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xLarge),

                      // Name Field
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icons.person,
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Phone Field (Read-only)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = userProvider.user ?? authProvider.user;
                          return CustomTextField(
                            controller: TextEditingController(
                              text: user?.phoneNumber ?? '',
                            ),
                            labelText: 'Phone Number',
                            prefixIcon: Icons.phone,
                            enabled: false,
                            readOnly: true,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.small),

                      // Info Text
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Text(
                                'Phone number cannot be changed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xLarge),

                      // Save Button
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: _hasChanges ? _saveProfile : null,
                        icon: Icons.save,
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Cancel Button
                      CustomButton(
                        text: 'Cancel',
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        isOutlined: true,
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
