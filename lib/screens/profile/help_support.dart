import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../widgets/blue_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Help & Support',
                    style: TextStyle(
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
                    'How can we help?',
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Find answers to your questions or get in touch with our team.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSupportCard(
                    icon: Icons.question_answer_outlined,
                    title: 'Frequently Asked Questions',
                    subtitle: 'Quick answers to common issues',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildSupportCard(
                    icon: Icons.chat_outlined,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildSupportCard(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Problem',
                    subtitle: 'Let us know if something is wrong',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildSupportCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Test Push Notification',
                    subtitle: 'Tap to send a test push to your device',
                    onTap: () => _testPushNotification(context),
                  ),
                  const SizedBox(height: 16),
                  _buildSupportCard(
                    icon: Icons.update_outlined,
                    title: 'Test DB Trigger (Confirm Booking)',
                    subtitle: 'Set a pending transport booking to confirmed',
                    onTap: () => _testConfirmBooking(context),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.headset_mic_outlined, color: AppColors.primary, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          'Still need help?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our support team is available 24/7 to assist you with any inquiries.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Contact Support Now', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _testPushNotification(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in!')));
      return;
    }

    final restApiKey = dotenv.env['ONESIGNAL_REST_API_KEY'];
    if (restApiKey == null || restApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add ONESIGNAL_REST_API_KEY to your Flutter .env file!')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending push request...')));

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode({
          "app_id": "953f9d46-26ca-4f7d-8690-c3cefd7c583f",
          "include_external_user_ids": [userId],
          "target_channel": "push",
          "headings": {"en": "Test Push Notification"},
          "contents": {"en": "It works! Your OneSignal setup is correct."},
        }),
      );

      if (!context.mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Push notification sent successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _testConfirmBooking(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in!')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Searching for pending booking...')));

    try {
      final supabase = Supabase.instance.client;
      // Find a pending booking
      final pendingBookings = await supabase
          .from('transport_bookings')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .limit(1);

      if (!context.mounted) return;

      if (pendingBookings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pending transport bookings found to confirm.')));
        return;
      }

      final bookingId = pendingBookings[0]['id'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Confirming booking: $bookingId...')));

      // Update to confirmed
      await supabase
          .from('transport_bookings')
          .update({'status': 'confirmed'})
          .eq('id', bookingId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed! Check notifications.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
