import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

import 'contact_us.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _user;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = await _userService.getProfile();
      setState(() {
        _user = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatPhoneNumber(String phone) {
    // Format +94XXXXXXXXX to 0XX XXX XXXX
    if (phone.startsWith('+94')) {
      final local = '0${phone.substring(3)}';
      if (local.length == 10) {
        return '${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
      }
      return local;
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  style: AppTextStyles.small.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = _user?.fullName.isNotEmpty == true
        ? _user!.fullName
        : 'Passenger';
    final displayPhone = _user != null
        ? _formatPhoneNumber(_user!.phoneNumber)
        : '';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // User avatar with initials
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.secondary,
                child: Text(
                  _getInitials(displayName),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(displayName, style: AppTextStyles.h2),
              const SizedBox(height: 8),
              // Phone number
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(displayPhone, style: AppTextStyles.small),
                ],
              ),
              // Email if available
              if (_user?.email != null && _user!.email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(_user!.email!, style: AppTextStyles.small),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile Settings', style: AppTextStyles.h2),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.secondary),
                    _buildSettingsTile(
                      Icons.person_outline,
                      'Edit Profile',
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/edit-profile',
                        );
                        // Reload data if profile was updated
                        if (result == true) {
                          _loadUserData();
                        }
                      },
                    ),

                    _buildSettingsTile(
                      Icons.privacy_tip_outlined,
                      'Privacy Policy',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/privacy-policy',
                        );
                      },
                    ),

                    _buildSettingsTile(
                      Icons.contact_support_outlined,
                      'Contact Us',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildSettingsTile(
                      Icons.help_outline,
                      'Help & Support',
                      onTap: () {
                        Navigator.pushNamed(context, '/help-support');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    // Logout using AuthProvider
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Log Out', style: AppTextStyles.buttonText),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.white),
      title: Text(title, style: AppTextStyles.body),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
