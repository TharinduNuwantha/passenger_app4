import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_intent_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

/// Success screen after lounge booking confirmation
class LoungeIntentSuccessScreen extends StatelessWidget {
  final ConfirmBookingResponse bookingResponse;

  const LoungeIntentSuccessScreen({
    super.key,
    required this.bookingResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success icon
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            
            // Success message
            Text(
              'Booking Confirmed!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your lounge booking has been confirmed',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Booking reference card
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Booking Reference',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bookingResponse.masterReference,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Booking details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Details',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    const Divider(),
                    
                    if (bookingResponse.preLoungeBooking != null) ...[
                      _buildDetailRow(
                        'Lounge Reference',
                        bookingResponse.preLoungeBooking!.reference,
                      ),
                    ],
                    
                    _buildDetailRow(
                      'Total Amount',
                      'LKR ${bookingResponse.totalPaid.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Booked On',
                      DateFormat('MMM d, yyyy h:mm a').format(DateTime.now()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Instructions card
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Important Information',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Please arrive at the lounge at your scheduled check-in time\n'
                      '• Show your booking reference at the lounge reception\n'
                      '• Your pre-ordered items will be ready when you arrive\n'
                      '• For any changes or cancellations, contact support',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
                // TODO: Navigate to My Bookings tab
              },
              child: const Text('View My Bookings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
