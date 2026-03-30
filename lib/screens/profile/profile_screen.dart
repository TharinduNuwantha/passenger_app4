import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../widgets/blue_header.dart';

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
        errorMessage = AppLocalization.tr(context, 'oopsSomethingWentWrong');
        isLoading = false;
      });
    }
  }

  String _formatPhoneNumber(String phone) {
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
    final selectedLanguageCode = context.watch<LanguageProvider>().languageCode;
    final t = (String key) => AppLocalization.tr(context, key);

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(t('profile')),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(t('profile')),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                t('somethingWentWrong'),
                style: AppTextStyles.h2.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  errorMessage!,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadUserData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t('tryAgain')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = _user?.fullName.isNotEmpty == true
        ? _user!.fullName
        : t('passenger');
    final displayPhone = _user != null
        ? _formatPhoneNumber(_user!.phoneNumber)
        : '';

    return Scaffold(
      key: ValueKey('profile-$selectedLanguageCode'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Header with Profile Info
            BlueHeader(
              bottomRadius: 30,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 40,
                left: 24,
                right: 24,
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        _getInitials(displayName),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayPhone,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (_user?.email != null && _user!.email!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _user!.email!,
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(t('accountManagement')),
                  _buildModernCard([
                    _buildSettingsTile(
                      Icons.person_outline_rounded,
                      t('editProfile'),
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/edit-profile',
                        );
                        if (result == true) {
                          _loadUserData();
                        }
                      },
                    ),
                    _buildSettingsTile(
                      Icons.language_rounded,
                      t('language'),
                      subtitle: AppLocalization.languageName(
                        context,
                        selectedLanguageCode,
                      ),
                      onTap: () => _showLanguageBottomSheet(context),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle(t('supportLegal')),
                  _buildModernCard([
                    _buildSettingsTile(
                      Icons.help_outline_rounded,
                      t('helpSupport'),
                      onTap: () {
                        Navigator.pushNamed(context, '/help-support');
                      },
                    ),
                    _buildSettingsTile(
                      Icons.contact_support_outlined,
                      t('contactUs'),
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
                      Icons.privacy_tip_outlined,
                      t('privacyPolicy'),
                      onTap: () {
                        Navigator.pushNamed(context, '/privacy-policy');
                      },
                    ),
                  ]),

                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.red.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade400,
                      ),
                      label: Text(
                        t('logoutAccount'),
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () => _handleLogout(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Version info
                  Center(
                    child: Text(
                      '${t('appVersion')} 2.6.3 (Build 312)',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        softWrap: true,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (idx < children.length - 1)
                Divider(height: 1, indent: 56, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Future<void> _showLanguageBottomSheet(BuildContext context) async {
    final provider = context.read<LanguageProvider>();
    final t = (String key) => AppLocalization.tr(context, key);

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final selectedCode = sheetContext
            .watch<LanguageProvider>()
            .languageCode;

        Widget option(String code, String labelKey) {
          return RadioListTile<String>(
            value: code,
            groupValue: selectedCode,
            activeColor: AppColors.primary,
            title: Text(AppLocalization.tr(context, labelKey)),
            onChanged: (value) async {
              if (value == null) return;
              await provider.setLocaleByCode(value);
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 12,
              left: 8,
              right: 8,
              bottom: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t('selectLanguage'), style: AppTextStyles.h3),
                const SizedBox(height: 8),
                option('en', 'englishLabel'),
                option('si', 'sinhalaLabel'),
                option('ta', 'tamilLabel'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final t = (String key) => AppLocalization.tr(context, key);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('logout')),
        content: Text(t('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              t('staySignedIn'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              t('signOut'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('logoutFailed'))));
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'P';
  }
}
