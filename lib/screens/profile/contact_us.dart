import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Contact Us",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Get in Touch",
                style: AppTextStyles.h1.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              const Text(
                "We’d love to hear from you! Please fill out the form below or contact us directly.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const ListTile(
                leading: Icon(Icons.phone, color: AppColors.primary),
                title: Text("Phone", style: TextStyle(color: Colors.black87)),
                subtitle: Text(
                  "+94 78 595 7049",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.email, color: AppColors.primary),
                title: Text("Email", style: TextStyle(color: Colors.black87)),
                subtitle: Text(
                  "support@passengerapp.com",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const Divider(color: Color.fromARGB(136, 0, 0, 0)),
              const SizedBox(height: 15),
              Text(
                "Send us a message",
                style: AppTextStyles.h2.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 10),
              _buildContactField(nameController, "Your Name"),
              const SizedBox(height: 10),
              _buildContactField(emailController, "Your Email"),
              const SizedBox(height: 10),
              _buildContactField(messageController, "Message", maxLines: 4),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Your message has been sent!"),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                    nameController.clear();
                    emailController.clear();
                    messageController.clear();
                  },
                  child: const Text(
                    "Submit",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
