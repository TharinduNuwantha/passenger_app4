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
        iconTheme: const IconThemeData(color: AppColors.textLight),
        title: const Text(
          'Privacy & Policy',
          style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Privacy Policy', style: AppTextStyles.h1),
            SizedBox(height: 12),
            Text(
              'Your privacy is important to us. We collect personal information only to improve your experience in the app and ensure secure usage. All data is stored securely and is never shared with third parties without your consent.',
              style: AppTextStyles.bodyText1,
            ),
            SizedBox(height: 20),
            Text('Information Collection', style: AppTextStyles.h2),
            SizedBox(height: 6),
            Text(
              'We may collect information such as your name, email, phone number, and activity data. This is used to personalize the app experience and improve services.',
              style: AppTextStyles.bodyText1,
            ),
            SizedBox(height: 20),
            Text('Data Usage', style: AppTextStyles.h2),
            SizedBox(height: 6),
            Text(
              'Your data is used only for providing better services, support, and app features. We do not sell your data to third parties.',
              style: AppTextStyles.bodyText1,
            ),
            SizedBox(height: 20),
            Text('Security', style: AppTextStyles.h2),
            SizedBox(height: 6),
            Text(
              'We implement industry-standard security measures to protect your information. You can also request deletion of your data anytime from the app settings.',
              style: AppTextStyles.bodyText1,
            ),
          ],
        ),
      ),
    );
  }
}
