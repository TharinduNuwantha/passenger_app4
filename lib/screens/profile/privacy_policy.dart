import 'package:flutter/material.dart';
import '../../localization/app_localization.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../widgets/blue_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = (String key) => AppLocalization.tr(context, key);
    return Scaffold(
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
                    t('privacyPolicy'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('yourPrivacyMatters'),
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  _buildPolicyText(t('privacyPolicyIntro')),
                  const Divider(height: 48),

                  _buildSection(
                    t('privacySection1Title'),
                    t('privacySection1Body'),
                  ),

                  _buildSection(
                    t('privacySection2Title'),
                    t('privacySection2Body'),
                  ),

                  _buildSection(
                    t('privacySection3Title'),
                    t('privacySection3Body'),
                  ),

                  _buildSection(
                    t('privacySection4Title'),
                    t('privacySection4Body'),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      t('privacyLastUpdated'),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          softWrap: true,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPolicyText(content),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPolicyText(String text) {
    return Text(
      text,
      softWrap: true,
      style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.6),
    );
  }
}
