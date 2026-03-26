import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String referenceNo;
  final String totalAmount;

  const PaymentSuccessScreen({
    super.key,
    required this.referenceNo,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              const Icon(Icons.check_circle, color: AppColors.success, size: 100),
              const SizedBox(height: 30),

              // Success Title
              Text(
                'Payment Successful!',
                style: AppTextStyles.h1.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Success Message
              Text(
                'Your payment has been processed successfully.',
                style: AppTextStyles.body.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Payment Details Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: AppTextStyles.h2.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Reference No', referenceNo),
                    const Divider(height: 20),
                    _buildDetailRow('Total Amount', totalAmount),
                    const Divider(height: 20),
                    _buildDetailRow('Payment Date', _getCurrentDate()),
                    const Divider(height: 20),
                    _buildDetailRow(
                      'Status',
                      'Completed',
                      valueColor: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to home or booking list
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // View Receipt Button (Optional)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to receipt screen or download receipt
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt will be sent to your email'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View Receipt',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
