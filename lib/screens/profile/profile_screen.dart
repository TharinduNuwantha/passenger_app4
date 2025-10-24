import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, {bool logoutAll = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(logoutAll ? 'Logout All Devices' : 'Logout'),
        content: Text(
          logoutAll
              ? 'This will log you out from all devices. Continue?'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.logout(logoutAll: logoutAll);

    if (!context.mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppConstants.phoneInputRoute, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(AppConstants.editProfileRoute);
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, child) {
          final user = userProvider.user ?? authProvider.user;

          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.large),
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
                          (user.name?.isNotEmpty == true ? user.name![0] : 'U')
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
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                // User Info Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Name',
                          value: user.name ?? 'Not set',
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: user.email ?? 'Not set',
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: user.phoneNumber,
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Member Since',
                          value: DateFormat(
                            'MMM dd, yyyy',
                          ).format(user.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),

                // Role Card - Passenger App Context (Only show 'passenger' role)
                if (user.roles.contains('passenger'))
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.badge, color: AppColors.primary),
                              SizedBox(width: AppSpacing.small),
                              Text(
                                'Account Type',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Chip(
                            label: const Text('PASSENGER'),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.large),

                // Logout Buttons
                const Text(
                  'Logout Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.medium),

                // Logout This Device
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout This Device'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),

                // Logout All Devices
                OutlinedButton.icon(
                  onPressed: () => _logout(context, logoutAll: true),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout All Devices'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.all(AppSpacing.medium),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
