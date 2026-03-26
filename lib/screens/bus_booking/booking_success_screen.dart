import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking_models.dart';
import '../../theme/app_colors.dart';
import '../payment/payment_method_screen.dart';
import '../lounge/lounge_list_screen.dart';

/// Success screen after booking is created, shows booking details and QR code
class BookingSuccessScreenV2 extends StatelessWidget {
  final MasterBooking booking;
  final BusBooking? busBooking;
  final List<BusBookingSeat> seats;
  final String? qrCode;

  const BookingSuccessScreenV2({
    super.key,
    required this.booking,
    this.busBooking,
    this.seats = const [],
    this.qrCode,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = qrCode ?? busBooking?.qrCodeData ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              // Navigate back to home or bookings list
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 20),

              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Reference: ${booking.bookingReference}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Safe travels & enjoy your journey!',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // QR Code Card
              if (qrData.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Boarding Pass',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (context, error) {
                            return const Center(child: Text('QR Code error'));
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Show this QR to conductor for boarding',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Booking Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Divider(height: 20),
                    if (busBooking != null) ...[
                      _buildDetailRow('Route', busBooking!.routeName),
                      _buildDetailRow('From', busBooking!.boardingStopName),
                      _buildDetailRow('To', busBooking!.alightingStopName),
                      _buildDetailRow(
                        'Date & Time',
                        _formatDateTime(busBooking!.departureDatetime),
                      ),
                      if (busBooking!.busType != null)
                        _buildDetailRow('Bus Type', busBooking!.busTypeDisplay),
                      if (busBooking!.busNumber != null)
                        _buildDetailRow('Bus Number', busBooking!.busNumber!),
                      _buildDetailRow(
                        'Seats',
                        seats.isNotEmpty
                            ? seats.map((s) => s.seatNumber).join(', ')
                            : '${busBooking!.numberOfSeats} seat(s)',
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildDetailRow('Passenger', booking.passengerName),
                    _buildDetailRow('Phone', booking.passengerPhone),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          booking.formattedTotal,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatusChip(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Copy Reference Button
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: booking.bookingReference),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reference copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Reference'),
              ),

              const SizedBox(height: 30),

              // Lounge Option
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Would you like to book a lounge?',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                      const LoungeListScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Yes, Book Lounge'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _proceedToPayment(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Skip, Pay Now'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _proceedToPayment(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Pay Later',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color bgColor;
    Color textColor;
    String statusText;

    switch (booking.paymentStatus) {
      case MasterPaymentStatus.paid:
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
        textColor = const Color(0xFF4CAF50);
        statusText = 'Paid';
        break;
      case MasterPaymentStatus.pending:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        statusText = 'Payment Pending';
        break;
      case MasterPaymentStatus.collectOnBus:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        statusText = 'Pay on Bus';
        break;
      case MasterPaymentStatus.free:
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
        textColor = const Color(0xFF4CAF50);
        statusText = 'Free';
        break;
      case MasterPaymentStatus.failed:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        statusText = 'Payment Failed';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        statusText = booking.paymentStatus.toJson();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _proceedToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          bookingPrice: booking.totalAmount.toStringAsFixed(2),
          referenceNo: booking.bookingReference,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
