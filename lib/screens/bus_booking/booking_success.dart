import 'package:flutter/material.dart';
import '../payment/payment_method_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String referenceNo;
  final String route;
  final String dateTime;
  final String busType;
  final String numberPlate;
  final String seatNo;
  final String price;

  const BookingSuccessScreen({
    super.key,
    required this.referenceNo,
    required this.route,
    required this.dateTime,
    required this.busType,
    required this.numberPlate,
    required this.seatNo,
    required this.price,
  });

  Widget _buildDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 80),
              const SizedBox(height: 20),

              Text(
                'Your booking is confirmed!',
                style: AppTextStyles.h1.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Safe travels & enjoy your journey ahead.',
                style: AppTextStyles.body.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                    _buildDetail('Reference No', referenceNo),
                    _buildDetail('Route', route),
                    _buildDetail('Date & Time', dateTime),
                    _buildDetail('Bus', busType),
                    _buildDetail('Seat No', seatNo),
                    _buildDetail('Number Plate', numberPlate),
                    _buildDetail('Price', 'LKR $price'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ✅ Checkout Button (navigate to PaymentMethodScreen)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate safely, converting data to String just in case
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentMethodScreen(
                          bookingPrice: price.toString(),
                          referenceNo: referenceNo.toString(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      color: AppColors.textLight,
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
}
