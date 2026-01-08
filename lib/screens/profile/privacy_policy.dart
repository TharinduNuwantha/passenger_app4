import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Privacy & Policy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildPolicyText(
              'Your privacy is important to us. We collect personal information only to improve your experience in the app and ensure secure usage. All data is stored securely and is never shared with third parties without your consent.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Information Collection'),
            _buildPolicyText(
              'We may collect information such as your name, email, phone number, and activity data. This is used to personalize the app experience and improve services.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Data Usage'),
            _buildPolicyText(
              'Your data is used only for providing better services, support, and app features. We do not sell your data to third parties.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Security'),
            _buildPolicyText(
              'We implement industry-standard security measures to protect your information. You can also request deletion of your data anytime from the app settings.',
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'Last updated: October 2026',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPolicyText(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: TextStyle(
        color: Colors.black54,
        fontSize: 13,
        height: 1.6,
        letterSpacing: 0.1,
      ),
    );
  }
}
