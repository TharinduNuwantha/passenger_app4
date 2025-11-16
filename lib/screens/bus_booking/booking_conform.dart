import 'package:flutter/material.dart';
import '../lounge/LoungesDetailsScreen.dart';
import 'booking_success.dart';

class AppColors {
  static const Color primary = Color(0xFF031A4B);
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color secondary = Color(0xFFFFC300);
}

class AppTextStyles {
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle bodyText1 = TextStyle(fontSize: 16);
  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Dashboard (Home)',
          style: AppTextStyles.h2.copyWith(
            fontSize: 20,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Text(
          'Welcome to the main Dashboard!',
          style: AppTextStyles.bodyText1.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

class BookingConfirmedScreen extends StatelessWidget {
  final String referenceNo;
  final String route;
  final String dateTime;
  final String busType;
  final String numberPlate;
  final String seatNo;
  final String price;
  final String pickup;
  final String drop;

  const BookingConfirmedScreen({
    super.key,
    required this.referenceNo,
    required this.route,
    required this.dateTime,
    required this.busType,
    required this.numberPlate,
    required this.seatNo,
    required this.price,
    this.pickup = '',
    this.drop = '',
  });

  Widget _buildSummaryLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Details',
          style: AppTextStyles.h2.copyWith(
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Icon(
                Icons.shopping_cart,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Booking Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus Booking Summary',
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const Divider(color: Colors.black26, height: 20),
                    const SizedBox(height: 8),
                    
                    // Booking Details
                    _buildSummaryLine('Reference No', referenceNo),
                    const Divider(height: 16),
                    _buildSummaryLine('Route', route),
                    const Divider(height: 16),
                    _buildSummaryLine('Date & Time', dateTime),
                    const Divider(height: 16),
                    _buildSummaryLine('Bus Type', busType),
                    const Divider(height: 16),
                    _buildSummaryLine('Number Plate', numberPlate),
                    const Divider(height: 16),
                    _buildSummaryLine('Seat No', seatNo),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price',
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'Rs.$price',
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Lounge Option Text
              Text(
                'Would you like to book a lounge?',
                style: AppTextStyles.bodyText1.copyWith(
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              // YES Button - Book a Lounge
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoungesDetailsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Yes, Book a Lounge',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // NO Button - Continue
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingSuccessScreen(
                          referenceNo: referenceNo,
                          route: route,
                          dateTime: dateTime,
                          busType: busType,
                          numberPlate: numberPlate,
                          seatNo: seatNo,
                          price: price,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.white, width: 2),
                    ),
                  ),
                  child: Text(
                    'No, Continue',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
