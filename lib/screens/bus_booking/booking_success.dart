import 'package:flutter/material.dart';
import '../../config/theme_config.dart' as config;
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
          style: const TextStyle(fontSize: 15, color: Colors.black87),
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
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),

              const Text(
                'Your booking is confirmed!',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Safe travels & enjoy your journey ahead.',
                style: TextStyle(color: AppColors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
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
                    backgroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Checkout',
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
}
