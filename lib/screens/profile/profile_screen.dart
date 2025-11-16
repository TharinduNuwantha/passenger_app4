import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contact_us.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String firstName = '';
  String lastName = '';
  String email = '';
  String passport = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'User';
      lastName = prefs.getString('lastName') ?? '';
      email = prefs.getString('email') ?? 'email@example.com';
      passport = prefs.getString('passport') ?? 'N/A';
      isLoading = false;
    });
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

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://picsum.photos/200'),
              ),
              const SizedBox(height: 16),
              Text('$firstName $lastName', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(email, style: AppTextStyles.small),
              const SizedBox(height: 4),
              if (passport.isNotEmpty && passport != 'N/A')
                Text('NIC: $passport', style: AppTextStyles.small),
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
                        ); // ✅ route added
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
                    // Clear user data and navigate to login
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
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
